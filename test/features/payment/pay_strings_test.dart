import 'package:customer_app/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final th = lookupAppLocalizations(const Locale('th'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('PromptPay strings keep the Thai wording and read English in en', () {
    expect(th.payQrExpiresIn('04:59'), 'QR หมดอายุใน 04:59');
    expect(en.payQrExpiresIn('04:59'), 'QR expires in 04:59');
    expect(th.payPromptPayTitle, 'ชำระเงินด้วย PromptPay');
    expect(en.payPromptPayTitle, 'Pay with PromptPay');
    expect(
      th.payAmountChangedNotice,
      'ยอดชำระมีการเปลี่ยนแปลง กรุณาสแกน QR ใหม่นี้แทน QR เดิม',
    );
    expect(en.payAmountChangedNotice, startsWith('The amount has changed'));
  });
}
