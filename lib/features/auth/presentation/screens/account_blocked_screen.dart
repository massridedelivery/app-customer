import 'package:customer_app/core/auth/account_block.dart';
import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/data/support_config_provider.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shown when the backend answers 403 `account_suspended` / `account_deleted`.
/// The session is already cleared; the router keeps the app here until the
/// user dismisses it, after which they continue as a guest.
class AccountBlockedScreen extends ConsumerWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reason = ref.watch(accountBlockProvider) ?? AccountBlock.suspended;
    final phone =
        ref.watch(supportPhoneProvider).value ?? kSupportPhoneFallback;
    final isDeleted = reason == AccountBlock.deleted;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDeleted ? Icons.person_off_outlined : Icons.block_rounded,
                    size: 44,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isDeleted ? l10n.authAccountDeletedTitle : l10n.authAccountSuspendedTitle,
                  style: AppTypography.heading3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isDeleted
                      ? l10n.authAccountDeletedBody
                      : l10n.authAccountSuspendedBody,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // The number is shown as text too: a tel: link may do nothing
                // on some devices, and the user can copy it.
                SelectableText(
                  l10n.authContactSupportPhone(phone),
                  style: AppTypography.label1,
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await launchUrl(
                        Uri(scheme: 'tel', path: phone),
                      );
                      if (!ok) {
                        await Clipboard.setData(ClipboardData(text: phone));
                      }
                    },
                    icon: const Icon(Icons.call_outlined),
                    label: Text(l10n.authCallSupport),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(accountBlockProvider.notifier).clear();
                      context.go('/main');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.authOk),
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
