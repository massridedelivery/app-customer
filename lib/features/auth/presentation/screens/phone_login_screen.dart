import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/core/utils/phone_format.dart';
import 'package:customer_app/core/widgets/hero_header.dart';
import 'package:customer_app/core/widgets/pill_tabs.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Field / text tokens of the login card (RodChao login spec, Mass red brand).
const Color _kFieldFill = Color(0xFFF8F8F9);
const Color _kFieldBorder = Color(0xFFEBECEF);
const Color _kInk = Color(0xFF1C1B1B);
const Color _kInkSoft = Color(0xFF444651);
const Color _kMuted = Color(0xFF6A6E83);

enum LoginMethod { phone, email }

/// Login: one screen with "เบอร์โทร / อีเมล" pill tabs under a red wave hero. Phone → POST /auth/otp/send, then the OTP screen
/// (which also starts sign-up for a new number); email → password login.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key, this.initialMethod = LoginMethod.phone});

  final LoginMethod initialMethod;

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneFocus = FocusNode();

  late LoginMethod _method = widget.initialMethod;

  /// Email login isn't offered by this backend (503 EMAIL_LOGIN_UNAVAILABLE,
  /// e.g. prod before launch): hide the email tab and stay on phone.
  bool _emailUnavailable = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_phoneController, _emailController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  bool get _isValidPhone => _phoneController.text.trim().length >= 9;

  bool get _isValidEmail => RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  ).hasMatch(_emailController.text.trim());

  Future<void> _requestOtp() async {
    if (!_isValidPhone) return;

    final phone = toE164Thai(_phoneController.text.trim());

    final SendOtpResponse? response = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(phone);

    if (response != null && mounted) {
      context.push(
        '/auth/otp',
        extra: {
          'phone': phone,
          'refId': response.refId,
          'isRegistered': response.isRegistered,
        },
      );
    }
  }

  /// Email login is a one-time code (no password): send it, then the OTP
  /// screen. The backend signs a new email up on verify, so there's no
  /// separate sign-up.
  Future<void> _sendEmailCode() async {
    if (!_isValidEmail) return;
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendEmailOtp(email);
    if (!mounted) return;
    if (result.ok) {
      context.push(
        '/auth/email-otp',
        extra: {
          'email': email,
          'refId': result.refId,
          'isRegistered': result.isRegistered,
        },
      );
      return;
    }
    if (result.error == EmailOtpError.accountBlocked) return; // own screen
    if (result.error == EmailOtpError.unavailable) {
      setState(() {
        _emailUnavailable = true;
        _method = LoginMethod.phone;
      });
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result.error!) {
            EmailOtpError.invalidEmail => l10n.authEmailInvalid,
            EmailOtpError.rateLimited => l10n.authOtpRateLimited,
            EmailOtpError.unavailable => l10n.authEmailUnavailable,
            _ => l10n.authEmailSendFailed,
          }),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );

    ref.listen(authControllerProvider.select((s) => s.error), (prev, next) {
      // The OTP / sign-up screens pushed on top report their own errors.
      if (ModalRoute.of(context)?.isCurrent != true) return;
      if (next != null && next != prev) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    });

    // White status-bar icons over the red hero.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: AutofillGroup(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(canPop: context.canPop(), onBack: () => context.pop()),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: _form(l10n, isLoading),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(AppLocalizations l10n, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // No tabs when email login isn't offered (503 from the backend).
        if (!_emailUnavailable) ...[
        PillTabs<LoginMethod>(
          key: const Key('loginMethodTabs'),
          items: [
            PillTabItem(value: LoginMethod.phone, label: l10n.authTabPhone),
            PillTabItem(value: LoginMethod.email, label: l10n.authEmail),
          ],
          selected: _method,
          onChanged: (m) => setState(() => _method = m),
        ),
        const SizedBox(height: 18),
        ],
        if (_method == LoginMethod.phone)
          ..._phoneSection(l10n, isLoading)
        else
          ..._emailSection(l10n, isLoading),
      ],
    );
  }

  List<Widget> _phoneSection(AppLocalizations l10n, bool isLoading) {
    return [
      TextField(
        key: const Key('loginPhone'),
        controller: _phoneController,
        focusNode: _phoneFocus,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
          LengthLimitingTextInputFormatter(15),
        ],
        style: AppTypography.body1.copyWith(color: _kInk),
        decoration: _decoration(
          label: l10n.phoneNumber,
          hint: '812345678',
          prefix: '+66 ',
        ),
      ),
      const SizedBox(height: 14),
      _PrimaryButton(
        key: const Key('loginRequestOtp'),
        label: l10n.authRequestOtp,
        loading: isLoading,
        onPressed: _isValidPhone && !isLoading ? _requestOtp : null,
      ),
    ];
  }

  List<Widget> _emailSection(AppLocalizations l10n, bool isLoading) {
    return [
      TextField(
        key: const Key('loginIdentifier'),
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendEmailCode(),
        style: AppTypography.body1.copyWith(color: _kInk),
        decoration: _decoration(label: l10n.authEmail, hint: 'you@email.com'),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.authEmailCodeHint,
        style: AppTypography.caption5.copyWith(color: _kMuted),
      ),
      const SizedBox(height: 14),
      _PrimaryButton(
        key: const Key('loginEmailSend'),
        label: l10n.authSendCode,
        loading: isLoading,
        onPressed: _isValidEmail && !isLoading ? _sendEmailCode : null,
      ),
    ];
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    String? prefix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      // Keep the label up so the "+66" prefix and the hint show before focus.
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixText: prefix,
      prefixStyle: AppTypography.body1.copyWith(color: _kInkSoft),
      labelStyle: AppTypography.body1.copyWith(color: _kMuted),
      floatingLabelStyle: AppTypography.body1.copyWith(
        color: AppColors.primary,
      ),
      hintStyle: AppTypography.body1.copyWith(color: _kMuted),
      filled: true,
      fillColor: _kFieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border(_kFieldBorder),
      enabledBorder: border(_kFieldBorder),
      focusedBorder: border(AppColors.primary, 1.5),
    );
  }
}

/// Brand-red gradient hero with the S-curve wave bottom shared by the home,
/// ride and messenger headers: back button, the white M mark beside the
/// welcome copy.
class _Hero extends StatelessWidget {
  const _Hero({required this.canPop, required this.onBack});

  final bool canPop;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;
    return ClipPath(
      clipper: HeroWaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.foundationRed700, AppColors.foundationRed900],
          ),
        ),
        child: Stack(
          children: [
            const HeroPatternOverlay(),
            Padding(
              padding: EdgeInsets.fromLTRB(24, topPad + 12, 24, 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 40,
                    child: canPop
                        ? IconButton(
                            onPressed: onBack,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // The mark PNG has a faint white rounded-square outline
                      // baked into its outer few pixels; trim it so the logo
                      // doesn't sit in a box on the red.
                      ClipRect(
                        child: Align(
                          widthFactor: 0.92,
                          heightFactor: 0.92,
                          child: Image.asset(
                            'assets/icon/icon_m_mark.png',
                            width: 56,
                            semanticLabel: 'Mass Move',
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.authWelcome,
                              // Same title style as the ride / messenger heroes.
                              style: AppTypography.heading2.copyWith(
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.authLoginSubtitle,
                              style: AppTypography.body2.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
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
    );
  }
}

/// Full-width 52px red button; a white spinner replaces the label while busy.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: loading
            ? AppColors.primary
            : AppColors.semanticDisabledBgLow,
        disabledForegroundColor: loading
            ? Colors.white
            : AppColors.semanticDisabledFgOnGray,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: AppTypography.label1,
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}
