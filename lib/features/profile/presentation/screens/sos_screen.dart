import 'package:customer_app/core/utils/app_dates.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/data/support_config_provider.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/presentation/controllers/sos_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSScreen extends ConsumerWidget {
  const SOSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sosHistoryProvider);
    final isTriggering = ref.watch(sosControllerProvider);
    // Admin-managed call-center number (GET /api/config/support), not hardcoded.
    final supportPhone =
        ref.watch(supportPhoneProvider).asData?.value ?? kSupportPhoneFallback;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileSosTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency button
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onLongPress: isTriggering
                        ? null
                        : () => _confirmSOS(context, ref),
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTriggering ? Colors.orange : AppColors.error,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.35),
                            blurRadius: 32,
                            spreadRadius: 8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: isTriggering
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sos_rounded,
                                  size: 56,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.profileSosHoldHint,
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Call the customer-support / call-center line (admin-managed number).
            OutlinedButton.icon(
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: supportPhone)),
              icon: const Icon(Icons.call, color: AppColors.error),
              label: Text(
                l10n.profileSosCallCenter(supportPhone),
                style: AppTypography.label2.copyWith(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.foundationRed100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.foundationRed300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.profileSosInfoTitle,
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.profileSosInfoBody,
                    style: AppTypography.body2.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(l10n.profileSosHistory, style: AppTypography.heading4),
            const SizedBox(height: 12),
            historyAsync.when(
              loading: () => const Center(child: MassLoadingM(size: 48)),
              error: (e, s) =>
                  Text(l10n.profileLoadFailed, style: AppTypography.body2),
              data: (history) => history.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E2E1)),
                      ),
                      child: Center(
                        child: Text(
                          l10n.profileSosNoHistory,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: history.map<Widget>((item) {
                        final s = item as Map<String, dynamic>;
                        final status = s['status'] ?? '';
                        final isResolved = status == 'RESOLVED';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE5E2E1),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? AppColors.foundationGreen100
                                      : AppColors.foundationRed100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isResolved
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  color: isResolved
                                      ? AppColors.primary
                                      : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.profileSosEvent,
                                      style: AppTypography.caption3,
                                    ),
                                    Text(
                                      _formatDate(context, s['created_at'] as String?),
                                      style: AppTypography.caption5.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isResolved
                                      ? AppColors.foundationGreen100
                                      : AppColors.foundationRed100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isResolved
                                      ? l10n.profileSosResolved
                                      : l10n.profileSosOpen,
                                  style: AppTypography.caption5.copyWith(
                                    color: isResolved
                                        ? AppColors.primary
                                        : AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// An ISO timestamp as a localized local-time date + time.
  String _formatDate(BuildContext context, String? isoDate) =>
      AppDates.of(context).isoDateTime(isoDate, fallback: '');

  Future<void> _confirmSOS(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sos_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(l10n.profileSosConfirmTitle, style: AppTypography.heading4),
          ],
        ),
        content: Text(l10n.profileSosConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: AppTypography.label2),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.profileSosSend, style: AppTypography.label2),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final success = await ref.read(sosControllerProvider.notifier).triggerSos();

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.profileSosSent),
          backgroundColor: AppColors.error,
        ),
      );
      ref.invalidate(sosHistoryProvider);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.profileSosSendFailed,
            style: AppTypography.caption4,
          ),
        ),
      );
    }
  }
}
