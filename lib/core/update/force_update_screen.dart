import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/update/force_update.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Blocks the app while the installed version is behind the store's. There is
/// no way past it except updating; the router keeps every route here.
class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  Future<void> _update(StoreUpdate update) async {
    // Android: Play's own full-screen update when allowed; if it can't run or
    // the user backs out of it, fall back to the store page.
    if (update.playImmediate) {
      try {
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.success) return;
      } catch (_) {}
    }
    await launchUrl(
      Uri.parse(update.storeUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(forceUpdateProvider);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.forceUpdateTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.forceUpdateBody,
                  textAlign: TextAlign.center,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (update?.storeVersion != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.forceUpdateVersions(
                      update!.currentVersion,
                      update.storeVersion!,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.semanticGrayNeutralFgMidOnWhite,
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: update == null ? null : () => _update(update),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l10n.forceUpdateButton,
                      style: AppTypography.label1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
