import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/auth/data/models/send_otp_response.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Neutral slate palette shared with the rest of the auth flow (see otp_screen).
// Kept as named constants so the values live in one place.
const Color _kBg = Color(0xFFF8FAFC);
const Color _kFieldFill = Color(0xFFF1F5F9);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kDisabledBg = Color(0xFFE2E8F0);
const Color _kDisabledText = Color(0xFF94A3B8);

class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  bool _isValidPhone = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isValidPhone = _phoneController.text.trim().length >= 9;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (!_isValidPhone) return;

    String phone = _phoneController.text.trim();
    // Ensure format +66
    if (phone.startsWith('0')) {
      phone = '+66${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      phone = '+66$phone';
    }

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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Brand hero (red gradient, curved bottom) ───────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, topInset + 8, 24, 52),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondaryRed],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Standard app back button (white on the hero). Shown only when
                // login was pushed (guest arriving from a gate) — same icon the
                // rest of the app uses.
                SizedBox(
                  height: 44,
                  child: context.canPop()
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 4),
                Text(
                  'Mass Move',
                  style: AppTypography.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'รับส่ง · ส่งของ · สั่งอาหาร',
                  style: AppTypography.body2.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // ── Floating form card (pulled up over the hero) ───────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยินดีต้อนรับสู่ Mass Move',
                        style: AppTypography.heading4.copyWith(
                          color: _kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'กรอกเบอร์โทรเพื่อเข้าสู่ระบบหรือสมัครใช้งาน',
                        style: AppTypography.body2.copyWith(
                          color: _kTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLabel('เบอร์โทรศัพท์'),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: '+66 999999999',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      _buildContinueButton(authState.isLoading),
                      if (authState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            authState.error!,
                            style: TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(bool isLoading) {
    const label = 'ขอรหัส OTP';
    final enabled = _isValidPhone && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? _requestOtp : null,
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
                      label,
                      style: AppTypography.label2.copyWith(
                        color: enabled ? Colors.white : _kDisabledText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTypography.caption4.copyWith(color: _kTextSecondary),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: const [AutofillHints.telephoneNumber],
      style: AppTypography.body1.copyWith(color: _kTextPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.caption3.copyWith(
          color: _kTextSecondary.withValues(alpha: 0.5),
        ),
        fillColor: _kFieldFill,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
