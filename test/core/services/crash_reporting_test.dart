import 'dart:convert';

import 'package:customer_app/core/services/crash_reporting.dart';
import 'package:flutter_test/flutter_test.dart';

String _jwt(Map<String, dynamic> claims) {
  String part(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part(claims)}.sig';
}

void main() {
  test('reads user_id from an access token', () {
    expect(
      userIdFromJwt(_jwt({'user_id': '7f3c2a10-c9d1', 'role': 'customer'})),
      '7f3c2a10-c9d1',
    );
  });

  test('a token without user_id, or garbage, gives null', () {
    expect(userIdFromJwt(_jwt({'role': 'customer'})), isNull);
    expect(userIdFromJwt(_jwt({'user_id': ''})), isNull);
    expect(userIdFromJwt('not-a-jwt'), isNull);
    expect(userIdFromJwt('a.%%%.c'), isNull);
  });

  test('the customer id is hashed, stable and not the raw id', () {
    final h = hashUserId('7f3c2a10-c9d1');
    expect(h, hashUserId('7f3c2a10-c9d1'));
    expect(h, hasLength(64));
    expect(h, isNot(contains('7f3c2a10')));
    expect(h, isNot(hashUserId('7f3c2a10-c9d2')));
  });
}
