import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

/// What people type, minus the separators: `081-234 5678` → `0812345678`.
String compactPhone(String input) => input.replaceAll(RegExp(r'[\s\-().]'), '');

/// A Thai mobile number as typed: exactly 10 digits starting with 0
/// (`0812345678`), or `+66` and exactly 9 digits (`+66812345678`). Spaces and
/// dashes are ignored. The server refuses anything else with 400
/// INVALID_PHONE.
bool isValidThaiMobile(String input) {
  final p = compactPhone(input);
  return RegExp(r'^0\d{9}$').hasMatch(p) || RegExp(r'^\+66\d{9}$').hasMatch(p);
}

/// Thai phone input → E.164 (`+66…`), which every `/auth/*` phone endpoint
/// requires: `0812345678` / `812345678` / `+66812345678` → `+66812345678`.
String toE164Thai(String input) {
  var p = compactPhone(input);
  if (p.startsWith('+')) return p;
  if (p.startsWith('66') && p.length >= 11) return '+$p';
  if (p.startsWith('0')) p = p.substring(1);
  return '+66$p';
}

/// A Thai number as E.164: +66 then 8–9 digits.
bool isThaiE164(String phone) => RegExp(r'^\+66\d{8,9}$').hasMatch(phone);

/// `+66812345678` → `081 234 5678` for display; other formats pass through.
String displayThaiPhone(String e164) {
  if (!e164.startsWith('+66')) return e164;
  final local = '0${e164.substring(3)}';
  if (local.length != 10) return local;
  return '${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6)}';
}

/// Phone field input: drops spaces and dashes (typed or pasted), keeps digits
/// and a leading `+`, and caps the number at 10 digits — 12 characters with
/// `+66`.
class ThaiMobileInputFormatter extends TextInputFormatter {
  const ThaiMobileInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final plus = raw.trimLeft().startsWith('+');
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    final max = plus ? 11 : 10;
    if (digits.length > max) digits = digits.substring(0, max);
    final text = plus ? '+$digits' : digits;
    if (text == raw) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// The server's text for a 400 INVALID_PHONE answer (`error`, else
/// `message`; "" when it sent neither), or null for any other error.
String? invalidPhoneMessage(Object error) {
  if (error is! DioException) return null;
  final res = error.response;
  final data = res?.data;
  if (res?.statusCode != 400 || data is! Map) return null;
  if (data['code']?.toString() != 'INVALID_PHONE') return null;
  final text = data['error'] ?? data['message'];
  return text is String ? text : '';
}
