import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/core/widgets/app_network_image.dart';
import 'package:customer_app/features/support/data/support_repository.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:customer_app/features/support/presentation/controllers/support_tickets_controller.dart';
import 'package:customer_app/features/support/presentation/support_l10n.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One report: what the customer sent, the team's replies, the outcome, and
/// a box to add details while it's still open. Opened from the list or from
/// the "ทีมงานตอบกลับ" push (`/support/tickets/{id}`).
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
  bool _sending = false;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

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
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(supportTicketProvider(widget.ticketId));
    final ticket = async.value;

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
          onRefresh: () =>
              ref.refresh(supportTicketProvider(widget.ticketId).future),
          child: ListView(
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
              child: ticket.status.isActive
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        8,
                        8,
                        8 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('supportReplyField'),
                              controller: _reply,
                              enabled: !_sending,
                              minLines: 1,
                              maxLines: 4,
                              maxLength: 1000,
                              decoration: InputDecoration(
                                hintText: l10n.supportReplyHint,
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
                            onPressed: _sending ? null : _sendReply,
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
