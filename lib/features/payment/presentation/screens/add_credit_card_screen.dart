import 'package:customer_app/core/constants/app_colors.dart';
import 'package:customer_app/core/constants/app_typography.dart';
import 'package:customer_app/features/payment/presentation/controllers/credit_cards_controller.dart';
import 'package:customer_app/features/payment/presentation/screens/credit_card_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Add-credit-card form with a live card preview. UI-only: on save it appends a
/// mock [CreditCardUi] to [creditCardsProvider] and pops back to the list — no
/// payment API call (no backend list/tokenization endpoint yet).
class AddCreditCardScreen extends ConsumerStatefulWidget {
  const AddCreditCardScreen({super.key});

  @override
  ConsumerState<AddCreditCardScreen> createState() =>
      _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends ConsumerState<AddCreditCardScreen> {
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final c in [
      _numberController,
      _nameController,
      _expiryController,
      _cvvController,
    ]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _digits => _numberController.text.replaceAll(' ', '');
  bool get _isValid =>
      _digits.length >= 15 &&
      _nameController.text.trim().isNotEmpty &&
      _expiryController.text.length == 5 &&
      _cvvController.text.length >= 3;

  void _save() {
    if (!_isValid) return;
    final digits = _digits;
    ref.read(creditCardsProvider.notifier).add(
      CreditCardUi(
        id: 'card_${DateTime.now().microsecondsSinceEpoch}',
        holder: _nameController.text.trim(),
        last4: digits.substring(digits.length - 4),
        expiry: _expiryController.text,
        brand: cardBrandFromNumber(digits),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('เพิ่มบัตรเรียบร้อยแล้ว')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralBgWhite,
      appBar: AppBar(
        title: const Text('เพิ่มบัตรเครดิต', style: AppTypography.heading4),
        backgroundColor: AppColors.semanticGrayNeutralBgWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Live preview.
                  CreditCardVisual(
                    brand: cardBrandFromNumber(_digits),
                    last4: _digits.length >= 4
                        ? _digits.substring(_digits.length - 4)
                        : '',
                    holder: _nameController.text,
                    expiry: _expiryController.text,
                  ),
                  const SizedBox(height: 28),
                  _label('หมายเลขบัตร'),
                  _field(
                    controller: _numberController,
                    hint: '1234 5678 9012 3456',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _label('ชื่อบนบัตร'),
                  _field(
                    controller: _nameController,
                    hint: 'ชื่อ นามสกุล',
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('วันหมดอายุ'),
                            _field(
                              controller: _expiryController,
                              hint: 'MM/YY',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryFormatter(),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('CVV'),
                            _field(
                              controller: _cvvController,
                              hint: '123',
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isValid ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.foundationGrayscale200,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'บันทึกบัตร',
                    style: AppTypography.heading4.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTypography.label2.copyWith(color: AppColors.textSecondary),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: AppTypography.body1.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body1.copyWith(color: AppColors.textDisabled),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

/// Groups the card number into blocks of four (1234 5678 9012 3456).
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}

/// Formats an expiry as MM/YY as the user types.
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('/', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    return TextEditingValue(
      text: buf.toString(),
      selection: TextSelection.collapsed(offset: buf.length),
    );
  }
}
