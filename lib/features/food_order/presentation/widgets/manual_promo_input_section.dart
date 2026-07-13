import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/features/food_order/presentation/controllers/checkout_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualPromoInputSection extends ConsumerStatefulWidget {
  const ManualPromoInputSection({super.key});

  @override
  ConsumerState<ManualPromoInputSection> createState() =>
      _ManualPromoInputSectionState();
}

class _ManualPromoInputSectionState
    extends ConsumerState<ManualPromoInputSection> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  bool _isFocused = false;
  bool _isSubmitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _textController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _localError = 'กรุณากรอกรหัสคูปอง');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    _focusNode.unfocus();

    // Check if already applied
    final appliedCodes = ref.read(
      checkoutProvider.select((s) => s.appliedPromoCodes),
    );
    if (appliedCodes.contains(code)) {
      setState(() {
        _isSubmitting = false;
        _localError = 'คูปอง "$code" ถูกใช้งานแล้ว';
      });
      return;
    }

    ref.read(checkoutProvider.notifier).updatePromoCode(code);
    _textController.clear();
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    // Listen for promoError from provider to surface in local error
    ref.listen<String?>(
      checkoutProvider.select((s) => s.promoError),
      (previous, next) {
        if (next != null && next != previous) {
          setState(() {
            _localError = next;
            _isSubmitting = false;
          });
        }
      },
    );

    final hasError = _localError != null;
    final borderColor = hasError
        ? AppColors.error
        : _isFocused
            ? AppColors.primary
            : Colors.grey[300]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  hasError
                      ? Icons.error_outline
                      : Icons.local_offer_outlined,
                  key: ValueKey(hasError),
                  color: hasError
                      ? AppColors.error
                      : _isFocused
                          ? AppColors.primary
                          : Colors.grey[400],
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  // Auto-uppercase as the user types
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldVal, newVal) {
                      return newVal.copyWith(
                        text: newVal.text.toUpperCase(),
                        selection: newVal.selection,
                      );
                    }),
                  ],
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) {
                    if (_localError != null) {
                      setState(() => _localError = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    hintText: 'กรอกรหัสคูปองด้วยตนเอง',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Apply button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(9),
                    bottomRight: Radius.circular(9),
                  ),
                ),
                child: TextButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    disabledForegroundColor: Colors.white54,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ใช้งาน',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        // Inline error message
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _localError != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _localError!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
