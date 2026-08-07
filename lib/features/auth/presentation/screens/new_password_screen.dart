import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/widgets/gradient_auth_button.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String resetToken;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validate);
    _confirmPasswordController.addListener(_validate);
  }

  void _validate() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _isValid = password.length >= 8 && password == confirmPassword;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isValid) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: widget.email,
          password: _passwordController.text,
          refId: widget.resetToken,
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.passwordChangedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      // Navigate all the way back to login
      while (context.canPop()) {
        context.pop();
      }
      context.pushReplacement('/auth/email_login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.setNewPassword,
                style: AppTypography.heading3.copyWith(
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.setNewPasswordSubtitle,
                style: AppTypography.caption4.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 40),

              // Password Field
              _buildLabel(l10n.newPasswordLabel),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••',
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Password Field
              _buildLabel(l10n.confirmNewPasswordLabel),
              _buildTextField(
                controller: _confirmPasswordController,
                hintText: '••••••••',
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Submit Button
              GradientAuthButton(
                label: l10n.changePassword,
                isLoading: authState.isLoading,
                onPressed: _isValid ? _submit : null,
              ),
            ],
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
        style: AppTypography.caption4.copyWith(color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0x8064748B), fontSize: 16),
        fillColor: const Color(0xFFF1F5F9),
        filled: true,
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }
}
