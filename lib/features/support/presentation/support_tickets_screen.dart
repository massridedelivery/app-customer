import 'dart:async';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/services/socket_service.dart';
import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/utils/error_text.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:customer_app/features/support/presentation/controllers/support_tickets_controller.dart';
import 'package:customer_app/features/support/presentation/support_l10n.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "ประวัติการแจ้งปัญหา": every report with its status, plus "แจ้งปัญหาใหม่".
/// A `support_ticket` socket frame (status changed) reloads the list.
class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  @override
  void initState() {
    super.initState();
    _socketSub = ref.read(socketServiceProvider).messages.listen((frame) {
      if (frame['type'] == 'support_ticket' && mounted) {
        ref.invalidate(supportTicketsProvider);
      }
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tickets = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.foundationGrayscale100,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(l10n.supportTicketsTitle, style: AppTypography.heading4),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(supportTicketsProvider.future),
        child: tickets.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  friendlyError(e),
                  textAlign: TextAlign.center,
                  style: AppTypography.body3,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(supportTicketsProvider),
                  child: Text(l10n.retry),
                ),
              ),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    const Icon(
                      Icons.support_agent_rounded,
                      size: 56,
                      color: AppColors.semanticGrayNeutralFgLowOnWhite,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.supportTicketsEmpty,
                      key: const Key('supportTicketsEmpty'),
                      textAlign: TextAlign.center,
                      style: AppTypography.body3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _TicketTile(ticket: list[i]),
                ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              key: const Key('supportNewReport'),
              onPressed: () => context.push('/support/report'),
              icon: const Icon(Icons.edit_note_rounded, color: AppColors.white),
              label: Text(
                l10n.supportNewReport,
                style: AppTypography.heading6.copyWith(color: AppColors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketTile extends ConsumerWidget {
  const _TicketTile({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dates = AppDates.of(context);
    final service = ticket.service;
    final created = ticket.createdAt;
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: Key('supportTicket_${ticket.id}'),
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await context.push('/support/tickets/${ticket.id}');
          // Opening it marked the replies read; refresh the badges.
          ref.invalidate(supportTicketsProvider);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.foundationGrayscale100,
                child: Icon(
                  ticket.category.icon,
                  size: 20,
                  color: ticket.category == SupportCategory.safety
                      ? AppColors.error
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.category.label(l10n),
                            style: AppTypography.heading6,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ticket.unread) ...[
                          const SizedBox(width: 6),
                          Container(
                            key: const Key('supportTicketUnread'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.supportNewReply,
                              style: AppTypography.caption4.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption4.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SupportStatusPill(ticket.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            [
                              if (service != null) service.label(l10n),
                              if (created != null) dates.dateTime(created),
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption4.copyWith(
                              color: AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
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
