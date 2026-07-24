import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/widgets/gradient_auth_button.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Neutral slate palette shared with the rest of the auth flow.
const Color _kBg = Color(0xFFF8FAFC);
const Color _kFieldFill = Color(0xFFF1F5F9);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String refId;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.email,
    required this.refId,
  });

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  static const int _otpLength = 6;

  // A single controller (not six) so paste, autofill and backspace all work
  // natively; the six boxes are just a display of its text. The old six-field
  // version couldn't delete backwards from an already-empty box.
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();
  bool _autoSubmitted = false;

  String get _otp => _otpController.text;
  bool get _isComplete => _otp.length == _otpLength;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
    _otpFocus.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    setState(() {});
    if (_isComplete && !_autoSubmitted) {
      _autoSubmitted = true;
      _otpFocus.unfocus();
      _verify();
    } else if (!_isComplete) {
      _autoSubmitted = false;
    }
  }

  Future<void> _verify() async {
    if (!_isComplete) return;

    final token = await ref
        .read(authControllerProvider.notifier)
        .verifyResetOtp(widget.email, _otp);

    if (mounted && token != null) {
      context.push(
        '/auth/new-password',
        extra: {'email': widget.email, 'resetToken': token},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                l10n.verifyIdentity,
                style: AppTypography.heading3.copyWith(color: _kTextPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.resetOtpSentMsg(widget.email),
                style: AppTypography.caption4.copyWith(color: _kTextSecondary),
              ),
              const SizedBox(height: 48),
              _buildOtpField(),
              const SizedBox(height: 48),
              GradientAuthButton(
                label: l10n.verify,
                isLoading: authState.isLoading,
                onPressed: _isComplete ? _verify : null,
              ),
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
                  style: AppTypography.heading4.copyWith(color: _kTextPrimary),
                ),
              );
            }),
          ),
          // Transparent field on top captures typing, paste and autofill.
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
}
