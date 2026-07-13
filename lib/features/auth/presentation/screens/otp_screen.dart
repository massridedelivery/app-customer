import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 6; i++) {
      _controllers[i].addListener(() {
        _checkComplete();
        if (_controllers[i].text.isNotEmpty && i < 5) {
          _focusNodes[i + 1].requestFocus();
        }
      });
    }
  }

  void _checkComplete() {
    final complete = _controllers.every((c) => c.text.isNotEmpty);
    if (_isComplete != complete) {
      setState(() => _isComplete = complete);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6) {
      // await ref.read(authControllerProvider.notifier).verifyOtp(
      //       phone: widget.phone,
      //       otp: otp,
      //       refId: widget.refId,
      //       role: 'customer',
      //     );

      final success = await ref
          .read(authControllerProvider.notifier)
          .sendVerifyOtp(
            phone: widget.phone,
            otp: otp,
            refId: widget.refId,
            role: 'customer',
            isRegistered: widget.isRegistered,
          );

      if (success && mounted) {
        if (!widget.isRegistered) {
          context.push('/auth/register', extra: {'phone': widget.phone});
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF8FAFC), // Aber green
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  // Verified Icon Header
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Color(0xFF1E3A8A),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.verifyIdentity,
                    style: AppTypography.heading3.copyWith(
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.otpSentMsg(widget.phone),
                    textAlign: TextAlign.center,
                    style: AppTypography.caption4.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // OTP Input Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width:
                            (MediaQuery.of(context).size.width -
                                48 -
                                (5 * 12)) /
                            6,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: TextField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: AppTypography.label1.copyWith(
                              color: const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              fillColor: const Color(0xFFF1F5F9),
                              filled: true,
                              contentPadding: EdgeInsets.zero,
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
                                borderSide: const BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 48),

                  // Verify Button
                  GestureDetector(
                    onTap:
                        _isComplete &&
                            !ref.watch(authControllerProvider).isLoading
                        ? _verifyOtp
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: _isComplete
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              )
                            : null,
                        color: _isComplete ? null : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _isComplete
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1E3A8A,
                                  ).withValues(alpha: 0.15),
                                  blurRadius: 15,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: ref.watch(authControllerProvider).isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)!.verify,
                                style: AppTypography.heading4.copyWith(
                                  color: _isComplete
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                      ),
                    ),
                  ),

                  if (ref.watch(authControllerProvider).error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        ref.watch(authControllerProvider).error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 32),
                  // Resend Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.resendCode,
                        style: AppTypography.label2.copyWith(
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 12,
                        height: 1,
                        color: AppColors.semanticGrayNeutralFgHigh.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '00:54',
                        style: AppTypography.label2.copyWith(
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 64),
                  // Help Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                      ),
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
                          child: const Icon(
                            Icons.help_outline,
                            color: Color(0xFF1E3A8A),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.needHelp,
                                style: AppTypography.label1,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.helpSubMsg,
                                style: AppTypography.support2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
