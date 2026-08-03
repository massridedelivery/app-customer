import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/register/presentation/controllers/register_controller.dart';
import 'package:customer_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:customer_app/features/auth/presentation/widgets/gradient_auth_button.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String phone;
  const RegisterScreen({super.key, this.phone = ''});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    // Basic validation
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.fillAllFields)),
      );
      return;
    }

    await ref
        .read(registerControllerProvider.notifier)
        .register(fullName: name, email: email);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen<AsyncValue<void>>(registerControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next is AsyncData && previous is! AsyncData) {
        ref.read(authControllerProvider.notifier).setAuthenticated();
        context.go('/main');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    l10n.createYourAccount,
                    style: AppTypography.heading3.copyWith(
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  RegisterLabel(label: l10n.fullName),
                  RegisterTextField(
                    controller: _nameController,
                    hintText: l10n.fullNameHint,
                  ),
                  const SizedBox(height: 24),

                  RegisterLabel(
                    label: l10n.emailAddress,
                  ),
                  RegisterTextField(
                    controller: _emailController,
                    hintText: 'mass@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  // Create Account Button
                  Consumer(
                    builder: (context, ref, child) {
                      final isLoading = ref.watch(
                        registerControllerProvider.select((s) => s.isLoading),
                      );
                      return GradientAuthButton(
                        label: l10n.createAccount,
                        isLoading: isLoading,
                        onPressed: _submit,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.alreadyHaveAccount,
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralFgHigh,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go('/auth/email_login'),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 2,
                            ),
                            child: Text(
                              l10n.signIn,
                              style: AppTypography.caption4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterLabel extends StatelessWidget {
  final String label;

  const RegisterLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTypography.caption4.copyWith(color: const Color(0xFF64748B)),
      ),
    );
  }
}

class RegisterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;

  const RegisterTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.caption3.copyWith(
          color: const Color(0x8064748B),
        ),
        fillColor: const Color(0xFFF1F5F9),
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
