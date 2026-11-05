import 'dart:async';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/data/support_config_provider.dart';
import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:customer_app/features/chat/domain/models/chat_message.dart';
import 'package:customer_app/features/chat/presentation/controllers/chat_controller.dart';
import 'package:customer_app/features/chat/presentation/widgets/chat_image_widgets.dart';
import 'package:customer_app/features/chat/presentation/widgets/chat_system_note.dart';
import 'package:customer_app/features/support/data/support_repository.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:customer_app/features/support/presentation/controllers/support_tickets_controller.dart';
import 'package:customer_app/features/support/presentation/support_chat_launcher.dart';
import 'package:customer_app/features/support/presentation/support_l10n.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One report: what the customer sent, the team's replies, the outcome, and
/// a box to add details while it's still open. Opened from the list or from
/// the "ทีมงานตอบกลับ" push (`/support/tickets/{id}`).
///
/// With live chat switched on (`support_chat_enabled`) the replies are the
/// report's chat room `ticket:{id}`: messages arrive over the socket and the
/// customer can send photos.
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _reply = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  bool _sending = false;

  /// The live chat of this report (used while live chat is switched on).
  ChatRoom get _room => (id: widget.ticketId, kind: ChatKind.support);

  @override
  void initState() {
    super.initState();
    // Status / outcome changes arrive as `support_ticket` frames.
    _socketSub = ref.read(socketServiceProvider).messages.listen((frame) {
      if (frame['type'] != 'support_ticket') return;
      final data = frame['data'];
      final id = frame['ticket_id'] ?? (data is Map ? data['ticket_id'] : null);
      if (id?.toString() == widget.ticketId && mounted) {
        ref.invalidate(supportTicketProvider(widget.ticketId));
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _reply.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Step 1: adds details to the report.
  Future<void> _sendReply() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      await ref.read(supportRepositoryProvider).reply(widget.ticketId, text);
      _reply.clear();
      ref.invalidate(supportTicketProvider(widget.ticketId));
    } on ApiError catch (e) {
      handleSupportDisabled(ref, e);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Step 2: a chat message.
  void _sendChat() {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    ref.read(chatControllerProvider(_room).notifier).sendMessage(text);
    _reply.clear();
    _scrollToEnd();
  }

  Future<void> _refresh(bool chat) async {
    if (chat) {
      await ref.read(chatControllerProvider(_room).notifier).fetchChatHistory();
    }
    ref.invalidate(supportTicketProvider(widget.ticketId));
    await ref.read(supportTicketProvider(widget.ticketId).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(supportTicketProvider(widget.ticketId));
    final ticket = async.value;
    final chat = ref.watch(supportFlagsProvider).chatEnabled;
    final messages = chat
        ? ref.watch(chatControllerProvider(_room).select((s) => s.messages))
        : const <ChatMessage>[];

    if (chat) {
      ref.listen(chatControllerProvider(_room).select((s) => s.error), (
        _,
        error,
      ) {
        if (error == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      });
      ref.listen(
        chatControllerProvider(_room).select((s) => s.messages.length),
        (prev, next) {
          if (next > (prev ?? 0)) _scrollToEnd();
        },
      );
    }

    // Live chat carries on after "แก้ไขแล้ว" (a message reopens it); only a
    // closed report stops taking messages.
    final canWrite =
        ticket != null &&
        (chat ? ticket.status != SupportStatus.closed : ticket.status.isActive);

    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // Opened from a push there is nothing under it: go to the list.
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/support/tickets'),
        ),
        title: Text(
          ticket == null
              ? l10n.supportTicketsTitle
              : l10n.supportTicketTitle(ticket.displayNo),
          style: AppTypography.heading4,
        ),
        centerTitle: true,
      ),
      body: async.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyError(e),
                  textAlign: TextAlign.center,
                  style: AppTypography.body3,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(supportTicketProvider(widget.ticketId)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (t) => RefreshIndicator(
          onRefresh: () => _refresh(chat),
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(ticket: t),
              const SizedBox(height: 16),
              _Bubble(
                fromAdmin: false,
                message: t.description,
                at: t.createdAt,
                photos: t.attachments,
              ),
              if (chat)
                for (final m in messages)
                  if (m.isSystem)
                    ChatSystemNote(text: m.text)
                  else if (m.isImage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ChatRoomImageBubble(
                        room: _room,
                        message: m,
                        isMe: _isMine(m),
                        myColor: AppColors.primary,
                      ),
                    )
                  else
                    _Bubble(
                      fromAdmin: !_isMine(m),
                      message: m.text,
                      at: m.sentAt.toLocal(),
                    )
              else
                for (final r in t.replies)
                  _Bubble(
                    fromAdmin: r.fromAdmin,
                    message: r.message,
                    at: r.createdAt,
                  ),
              if (t.resolution != null || t.refundAmount != null) ...[
                const SizedBox(height: 8),
                _Outcome(ticket: t),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: ticket == null
          ? null
          : SafeArea(
              child: canWrite
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        chat ? 4 : 12,
                        8,
                        8,
                        8 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Row(
                        children: [
                          if (chat)
                            ChatAttachButton(
                              key: const Key('supportChatAttach'),
                              color: AppColors.primary,
                              onSend: (bytes, caption) {
                                ref
                                    .read(
                                      chatControllerProvider(_room).notifier,
                                    )
                                    .sendImage(bytes, caption: caption);
                                _scrollToEnd();
                              },
                            ),
                          Expanded(
                            child: TextField(
                              key: const Key('supportReplyField'),
                              controller: _reply,
                              enabled: !_sending,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 1000,
                              decoration: InputDecoration(
                                hintText: chat
                                    ? l10n.supportChatHint
                                    : l10n.supportReplyHint,
                                counterText: '',
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            key: const Key('supportReplySend'),
                            onPressed: _sending
                                ? null
                                : (chat ? _sendChat : _sendReply),
                            icon: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Text(
                        l10n.supportClosedNote,
                        key: const Key('supportClosedNote'),
                        textAlign: TextAlign.center,
                        style: AppTypography.caption4.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
            ),
    );
  }

  static bool _isMine(ChatMessage m) =>
      m.senderId == 'me' || m.senderRole == 'customer';
}

class _Header extends StatelessWidget {
  const _Header({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = AppDates.of(context);
    final service = ticket.service;
    final refId = ticket.refId;
    final created = ticket.createdAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ticket.category.icon,
                color: ticket.category == SupportCategory.safety
                    ? AppColors.error
                    : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ticket.category.label(l10n),
                  style: AppTypography.heading6,
                ),
              ),
              SupportStatusPill(ticket.status),
            ],
          ),
          if (service != null || created != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (service != null)
                  refId == null
                      ? service.label(l10n)
                      : l10n.supportOrderLabel(
                          service.label(l10n),
                          (refId.length > 8 ? refId.substring(0, 8) : refId)
                              .toUpperCase(),
                        ),
                if (created != null) dates.dateTime(created),
              ].join(' · '),
              style: AppTypography.caption4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.fromAdmin,
    required this.message,
    this.at,
    this.photos = const [],
  });

  final bool fromAdmin;
  final String message;
  final DateTime? at;
  final List<SupportAttachment> photos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = AppDates.of(context);
    final shown = photos.where((p) => p.url != null).toList();
    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: fromAdmin
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                [
                  fromAdmin ? l10n.supportTeam : l10n.supportYou,
                  if (at != null) dates.dateTime(at!),
                ].join(' · '),
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgLowOnWhite,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fromAdmin ? AppColors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: AppTypography.body3.copyWith(
                        color: fromAdmin ? null : AppColors.white,
                      ),
                    ),
                    if (shown.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final p in shown)
                            GestureDetector(
                              onTap: () => showDialog<void>(
                                context: context,
                                builder: (_) => Dialog(
                                  child: InteractiveViewer(
                                    child: AppNetworkImage(
                                      url: p.url,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: AppNetworkImage(
                                  url: p.url,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refund = ticket.refundAmount;
    return Container(
      key: const Key('supportOutcome'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.semanticSupportMintBgLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.semanticSupportMintBorderOnWhite),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.supportResolution,
            style: AppTypography.heading6.copyWith(
              color: AppColors.semanticSupportMintFgOnLow,
            ),
          ),
          if (ticket.resolution != null) ...[
            const SizedBox(height: 6),
            Text(ticket.resolution!, style: AppTypography.body3),
          ],
          if (refund != null && refund > 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.supportRefund(
                refund == refund.roundToDouble()
                    ? refund.toStringAsFixed(0)
                    : refund.toStringAsFixed(2),
              ),
              style: AppTypography.heading6,
            ),
          ],
        ],
      ),
    );
  }
}
