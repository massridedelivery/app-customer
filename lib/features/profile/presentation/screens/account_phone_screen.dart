import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/phone_format.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/profile/data/account_email.dart';
import 'package:customer_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:customer_app/features/profile/presentation/screens/account_email_screen.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Add or change the account's phone: SMS code (valid 5 minutes), then the
/// new number replaces the old one and SMS login with it opens this account.
class AccountPhoneScreen extends ConsumerStatefulWidget {
  const AccountPhoneScreen({super.key});

  @override
  ConsumerState<AccountPhoneScreen> createState() => _AccountPhoneScreenState();
}

class _AccountPhoneScreenState extends ConsumerState<AccountPhoneScreen> {
  final _phoneController = TextEditingController();
  bool _sending = false;

  /// The server's 400 INVALID_PHONE text, shown under the field until the
  /// number is edited.
  String? _serverError;
  String _lastText = '';

  String get _e164 => toE164Thai(_phoneController.text);
  bool get _isValid => isValidThaiMobile(_phoneController.text);

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(
      () => setState(() {
        if (_phoneController.text == _lastText) return;
        _lastText = _phoneController.text;
        _serverError = null;
      }),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_isValid || _sending) return;
    final l10n = AppLocalizations.of(context)!;
    final phone = _e164;
    setState(() => _sending = true);
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendAccountPhone(phone);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result.error == EmailOtpError.invalidPhone) {
      final message = result.message;
      setState(
        () => _serverError = message != null && message.isNotEmpty
            ? message
            : l10n.profilePhoneInvalid,
      );
      return;
    }
    if (!result.ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(switch (result.error) {
              EmailOtpError.phoneInUse => l10n.profilePhoneInUse,
              EmailOtpError.rateLimited => l10n.authOtpRateLimited,
              _ => l10n.profilePhoneSendFailed,
            }),
          ),
        );
      return;
    }
    final verified = await context.push<bool>(
      '/account-phone/otp',
      extra: {'phone': phone, 'refId': result.refId},
    );
    if (!mounted || verified != true) return;
    ref.invalidate(accountPhoneProvider);
    ref.invalidate(profileControllerProvider); // the header shows the phone
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.profilePhoneVerifiedDone)),
    );
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(accountPhoneProvider).asData?.value;
    final hasPhone = current != null && !current.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.profilePhone, style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (hasPhone) ...[
              Container(
                key: const Key('accountPhoneCurrent'),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE5E2E1),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayThaiPhone(current.phone),
                        style: AppTypography.body1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (current.verified) const VerifiedBadge(verified: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              hasPhone ? l10n.profilePhoneChange : l10n.profilePhoneAdd,
              style: AppTypography.heading5,
            ),
            const SizedBox(height: 6),
            Text(
              hasPhone
                  ? '${l10n.profilePhoneHint} ${l10n.profilePhoneReplaceNote}'
                  : l10n.profilePhoneHint,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('accountPhoneInput'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: const [ThaiMobileInputFormatter()],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _sendCode(),
              style: AppTypography.body1,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                hintText: '0812345678',
                helperText: _phoneController.text.isNotEmpty && !_isValid
                    ? l10n.phoneMobileHint
                    : null,
                errorText: _serverError,
                errorMaxLines: 2,
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
              key: const Key('accountPhoneSend'),
              onPressed: _isValid && !_sending ? _sendCode : null,
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
                  : Text(l10n.authRequestOtp),
            ),
          ],
        ),
      ),
    );
  }
}
