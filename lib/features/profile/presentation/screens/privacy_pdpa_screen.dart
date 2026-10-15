import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/widgets/mass_loading_m.dart';
import 'package:customer_app/features/profile/data/datasources/account_remote_data_source.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles PDPA-related actions: data export, consent, and account deletion.
class PrivacyPdpaScreen extends ConsumerWidget {
  const PrivacyPdpaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: Text(l10n.profilePdpaTitle, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.foundationBlue100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.foundationBlue200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profilePdpaRightsTitle,
                        style: AppTypography.heading4.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.profilePdpaRightsBody,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.profilePdpaDataManagement, style: AppTypography.heading4),
          const SizedBox(height: 14),
          _PdpaTile(
            icon: Icons.download_rounded,
            iconColor: AppColors.primary,
            title: l10n.profilePdpaExportTitle,
            subtitle: l10n.profilePdpaExportSubtitle,
            onTap: () => _exportData(context, ref),
          ),
          const SizedBox(height: 12),
          _PdpaTile(
            icon: Icons.history_edu_rounded,
            iconColor: AppColors.primary,
            title: l10n.profilePdpaConsentHistoryTitle,
            subtitle: l10n.profilePdpaConsentHistorySubtitle,
            onTap: () => _showConsentDialog(context, ref),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.profilePdpaDangerZone,
            style: AppTypography.heading4.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 14),
          _PdpaTile(
            icon: Icons.delete_forever_rounded,
            iconColor: AppColors.error,
            title: l10n.profilePdpaDeletionTitle,
            subtitle: l10n.profilePdpaDeletionSubtitle,
            onTap: () => _requestDeletion(context, ref),
            bgColor: AppColors.foundationRed100,
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profilePdpaExporting),
        content: const Center(
          heightFactor: 1.5,
          child: MassLoadingM(size: 48),
        ),
      ),
    );
    try {
      await ref.read(accountRemoteDataSourceProvider).exportData();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profilePdpaExportSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profilePdpaExportFailed)),
        );
      }
    }
  }

  void _showConsentDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profilePdpaConsentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profilePdpaConsentPolicyVersion),
            const SizedBox(height: 4),
            Text(l10n.profilePdpaConsentStatus),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.profileClose),
          ),
        ],
      ),
    );
  }

  void _requestDeletion(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profilePdpaDeletionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.profilePdpaDeletionReasonPrompt),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.profilePdpaDeletionReasonHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              l10n.profilePdpaSubmitRequest,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && reasonCtrl.text.isNotEmpty) {
      try {
        await ref
            .read(accountRemoteDataSourceProvider)
            .requestDeletion(reasonCtrl.text);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profilePdpaDeletionReceived)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.profilePdpaDeletionFailed)),
          );
        }
      }
    }
  }
}

class _PdpaTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? bgColor;

  const _PdpaTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.foundationGrayscale200),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.caption3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCFD1D9)),
          ],
        ),
      ),
    );
  }
}
