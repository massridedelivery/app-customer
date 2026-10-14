import 'package:customer_app/core/auth/account_block.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Response<dynamic> _res(int status, Object? data) => Response(
  requestOptions: RequestOptions(path: '/x'),
  statusCode: status,
  data: data,
);

void main() {
  test('reads the suspended / deleted codes from a 403', () {
    expect(
      accountBlockOf(_res(403, {'code': 'account_suspended'})),
      AccountBlock.suspended,
    );
    expect(
      accountBlockOf(_res(403, {'code': 'account_deleted'})),
      AccountBlock.deleted,
    );
  });

  test('ignores other errors', () {
    expect(accountBlockOf(_res(403, {'code': 'file_forbidden'})), isNull);
    expect(accountBlockOf(_res(401, {'code': 'account_suspended'})), isNull);
    expect(accountBlockOf(_res(403, 'forbidden')), isNull);
    expect(accountBlockOf(null), isNull);
  });
}
