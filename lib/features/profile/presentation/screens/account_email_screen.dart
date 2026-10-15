import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/data/account_email.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Add / verify / change the account's email. Verifying (6-digit code, valid
/// 10 minutes) makes email login open this same account instead of creating a
/// new one. Changing the email goes through here, never a plain profile edit
/// (an unverified email can't sign in).
class AccountEmailScreen extends ConsumerStatefulWidget {
  const AccountEmailScreen({super.key});

  @override
  ConsumerState<AccountEmailScreen> createState() => _AccountEmailScreenState();
}

class _AccountEmailScreenState extends ConsumerState<AccountEmailScreen> {
  final _emailController = TextEditingController();
  bool _prefilled = false;
  bool _sending = false;

  bool get _isValidEmail => RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(_emailController.text.trim());

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_isValidEmail || _sending) return;
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    setState(() => _sending = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendAccountEmail(email);
    if (!mounted) return;
    setState(() => _sending = false);
    if (!result.ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(switch (result.error) {
              EmailOtpError.emailInUse => l10n.profileEmailInUse,
              EmailOtpError.rateLimited => l10n.authOtpRateLimited,
              EmailOtpError.invalidEmail => l10n.authEmailInvalid,
              EmailOtpError.unavailable => l10n.authEmailUnavailable,
              _ => l10n.authEmailSendFailed,
            }),
          ),
        );
      if (result.error == EmailOtpError.unavailable) context.pop();
      return;
    }
    final verified = await context.push<bool>(
      '/account-email/otp',
      extra: {'email': email, 'refId': result.refId},
    );
    if (!mounted || verified != true) return;
    ref.invalidate(accountEmailProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.profileEmailVerifiedDone)),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(accountEmailProvider).asData?.value;
    // An unverified address is most likely the one to verify: pre-fill it.
    if (!_prefilled && current != null) {
      _prefilled = true;
      if (!current.verified && !current.isEmpty) {
        _emailController.text = current.email;
      }
    }
    final verified = current != null && current.verified && !current.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profileEmail, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (current != null && !current.isEmpty) ...[
              _CurrentEmailCard(email: current),
              const SizedBox(height: 24),
            ],
            Text(
              verified ? l10n.profileEmailChange : l10n.profileEmailAddTitle,
              style: AppTypography.heading5,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.profileEmailHint,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('accountEmailInput'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendCode(),
              style: AppTypography.body1,
              decoration: InputDecoration(
                labelText: l10n.authEmail,
                hintText: 'you@email.com',
                labelStyle: AppTypography.body2,
                hintStyle: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('accountEmailSend'),
              onPressed: _isValidEmail && !_sending ? _sendCode : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _sending
                    ? AppColors.primary
                    : AppColors.semanticDisabledBgLow,
                disabledForegroundColor: _sending
                    ? Colors.white
                    : AppColors.semanticDisabledFgOnGray,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: AppTypography.label1,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.authSendCode),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentEmailCard extends StatelessWidget {
  const _CurrentEmailCard({required this.email});

  final AccountEmail email;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('accountEmailCurrent'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E2E1), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  email.email,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              VerifiedBadge(verified: email.verified),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            email.verified
                ? l10n.profileEmailLoginReady
                : l10n.profileEmailNotLoginReady,
            style: AppTypography.caption4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "ยืนยันแล้ว" (green) / "ยังไม่ยืนยัน" (amber) pill.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: verified
            ? AppColors.semanticSuccessBgLow
            : AppColors.semanticWarningBgLowOnGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        verified ? l10n.profileEmailVerified : l10n.profileEmailUnverified,
        style: AppTypography.caption5.copyWith(
          color: verified
              ? AppColors.semanticSuccessFgHigh
              : AppColors.textPrimary,
        ),
      ),
    );
  }
}
