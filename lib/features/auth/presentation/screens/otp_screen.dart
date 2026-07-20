import 'dart:async';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Neutral slate palette shared with the rest of the auth flow (see
// phone_login_screen). Kept as named constants here so the values live in one
// place instead of being sprinkled through the widget tree.
const Color _kBg = Color(0xFFF8FAFC);
const Color _kFieldFill = Color(0xFFF1F5F9);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kDisabledBg = Color(0xFFE2E8F0);
const Color _kDisabledText = Color(0xFF94A3B8);

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String refId;
  final bool isRegistered;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.refId,
    required this.isRegistered,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 6;
  static const int _resendSeconds = 60;

  // A single controller (not six) so paste, SMS one-time-code autofill and
  // backspace all work natively; the six boxes are just a display of its text.
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  // refId is refreshed on every resend, so it can't stay `widget.refId`.
  late String _refId = widget.refId;
  int _secondsRemaining = _resendSeconds;
  Timer? _timer;
  bool _autoSubmitted = false;

  String get _otp => _otpController.text;
  bool get _isComplete => _otp.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    _otpFocus.addListener(() => setState(() {}));
    _startResendTimer();
    // Open the keyboard as soon as the screen settles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    setState(() {});
    if (_isComplete && !_autoSubmitted) {
      _autoSubmitted = true;
      _otpFocus.unfocus();
      _verifyOtp();
    } else if (!_isComplete) {
      _autoSubmitted = false;
    }
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _countdownLabel {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Masks the middle of the phone number, keeping the country prefix and the
  /// last three digits so the user can still recognise it.
  String get _maskedPhone {
    final p = widget.phone;
    if (p.length <= 6) return p;
    final head = p.substring(0, 3);
    final tail = p.substring(p.length - 3);
    return '$head${'•' * (p.length - 6)}$tail';
  }

  Future<void> _verifyOtp() async {
    if (!_isComplete) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendVerifyOtp(
          phone: widget.phone,
          otp: _otp,
          refId: _refId,
          role: 'customer',
          isRegistered: widget.isRegistered,
        );

    if (success && mounted && !widget.isRegistered) {
      context.push('/auth/register', extra: {'phone': widget.phone});
    }
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0) return;
    final response = await ref
        .read(authControllerProvider.notifier)
        .sendOtp(widget.phone);
    if (!mounted || response == null) return;
    setState(() {
      _refId = response.refId;
      _autoSubmitted = false;
      _otpController.clear();
    });
    _startResendTimer();
    _otpFocus.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.otpResent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              // Verified icon header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.softRedBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.verifyIdentity,
                style: AppTypography.heading3.copyWith(
                  color: _kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.otpSentMsg(_maskedPhone),
                textAlign: TextAlign.center,
                style: AppTypography.caption4.copyWith(color: _kTextSecondary),
              ),
              const SizedBox(height: 48),

              _buildOtpField(),
              const SizedBox(height: 48),

              _buildVerifyButton(l10n, isLoading),

              if (authState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authState.error!,
                    style: TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),
              _buildResendRow(l10n),

              const SizedBox(height: 64),
              _buildHelpCard(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    final boxSize = (MediaQuery.of(context).size.width - 48 - (5 * 12)) / 6;
    return Semantics(
      label: 'OTP, ${_otp.length} of $_otpLength digits entered',
      textField: true,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_otpLength, (index) {
              final filled = index < _otp.length;
              final isNext = index == _otp.length;
              final highlighted = _otpFocus.hasFocus && isNext;
              return Container(
                width: boxSize,
                height: boxSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _kFieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: highlighted ? AppColors.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  filled ? _otp[index] : '',
                  style: AppTypography.label1.copyWith(color: _kTextPrimary),
                ),
              );
            }),
          ),
          // Transparent field on top captures typing, paste and SMS autofill.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocus,
                keyboardType: TextInputType.number,
                maxLength: _otpLength,
                autofillHints: const [AutofillHints.oneTimeCode],
                showCursor: false,
                cursorColor: Colors.transparent,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(AppLocalizations l10n, bool isLoading) {
    final enabled = _isComplete && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: l10n.verify,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? _verifyOtp : null,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondaryRed],
                    )
                  : null,
              color: enabled ? null : _kDisabledBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.verify,
                      style: AppTypography.heading4.copyWith(
                        color: enabled ? Colors.white : _kDisabledText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendRow(AppLocalizations l10n) {
    if (_secondsRemaining > 0) {
      return Text(
        l10n.resendCodeIn(_countdownLabel),
        style: AppTypography.label2.copyWith(color: _kTextSecondary),
      );
    }
    return TextButton(
      onPressed: _resendOtp,
      child: Text(
        l10n.resendCode,
        style: AppTypography.label2.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildHelpCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kFieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Icon(Icons.help_outline, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.needHelp, style: AppTypography.label1),
                const SizedBox(height: 4),
                Text(l10n.helpSubMsg, style: AppTypography.support2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
