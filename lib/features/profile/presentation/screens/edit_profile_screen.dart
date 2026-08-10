import 'dart:io';

import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    // Surface avatar-upload / update errors as a snackbar.
    ref.listen(profileControllerProvider.select((s) => s.value?.error), (
      prev,
      next,
    ) {
      if (next != null && next.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next)));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลส่วนตัว', style: AppTypography.heading4),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Profile Picture Section
                  _ProfileImageSection(
                    name: state.value?.editName ?? '',
                    imageUrl: state.value?.editAvatarUrl,
                    pickedPath: state.value?.pickedAvatarPath,
                    isUploading: state.value?.isUploadingAvatar ?? false,
                    onEdit: () => ref
                        .read(profileControllerProvider.notifier)
                        .pickAvatar(),
                  ),
                  const SizedBox(height: 40),

                  // Form Fields
                  const _FieldLabel(label: 'ชื่อ-นามสกุล'),
                  const SizedBox(height: 8),
                  _CustomTextField(
                    controller: TextEditingController(
                      text: state.value?.editName ?? '',
                    ),
                    onChanged: (value) => ref
                        .read(profileControllerProvider.notifier)
                        .updateEditName(value),
                    hint: 'กรอกชื่อ-นามสกุล',
                  ),
                ],
              ),
            ),
          ),
          // Pinned to the bottom.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: _SaveButton(
                isUpdating: state.value?.isUpdating ?? false,
                isValid: !(state.value?.isUploadingAvatar ?? false),
                onPressed: () {
                  ref
                      .read(profileControllerProvider.notifier)
                      .updateProfile(fullName: state.value?.editName ?? '');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets (Pure UI) ──────────────────────────────────────────────────

class _ProfileImageSection extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? pickedPath;
  final bool isUploading;
  final VoidCallback onEdit;
  const _ProfileImageSection({
    required this.name,
    required this.onEdit,
    this.imageUrl,
    this.pickedPath,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (pickedPath != null && pickedPath!.isNotEmpty) {
      image = FileImage(File(pickedPath!));
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = NetworkImage(imageUrl!);
    }

    return Center(
      child: GestureDetector(
        onTap: isUploading ? null : onEdit,
        child: Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.foundationGrayscale100,
                border: Border.all(
                  color: AppColors.foundationGrayscale200,
                  width: 2,
                ),
                image: image != null
                    ? DecorationImage(image: image, fit: BoxFit.cover)
                    : null,
              ),
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : image != null
                  ? null
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.primary,
                          fontSize: 40,
                        ),
                      ),
                    ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: AppTypography.label2.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _CustomTextField({
    required this.controller,
    required this.hint,
    this.onChanged,
  }) : keyboardType = TextInputType.text;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body1.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.foundationGrayscale200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isUpdating;
  final bool isValid;
  final VoidCallback onPressed;

  const _SaveButton({
    required this.isUpdating,
    required this.isValid,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (isUpdating || !isValid) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.foundationGrayscale200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isUpdating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'บันทึก',
                style: AppTypography.heading4.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}
