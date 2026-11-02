import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/services/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_remote_data_source.g.dart';

@riverpod
AccountRemoteDataSource accountRemoteDataSource(Ref ref) =>
    AccountRemoteDataSource(ref.watch(apiServiceProvider));

/// Why the "my data" export couldn't be loaded. Carries no value from the
/// response body except the backend's own rate-limit message.
sealed class DataExportException implements Exception {
  const DataExportException();
}

/// 404 `{"error": "account not found"}`: the account is gone (deleted), so
/// the app signs out. A 404 for a missing route (a backend without the export
/// yet) is a [DataExportFailed] instead — it must never sign anyone out.
class DataExportAccountGone extends DataExportException {
  const DataExportAccountGone();
}

/// 429 `DATA_EXPORT_RATE_LIMITED`: [message] is shown as is, and retrying is
/// allowed again after [retryAfter].
class DataExportRateLimited extends DataExportException {
  const DataExportRateLimited(this.message, this.retryAfter);
  final String? message;
  final Duration retryAfter;
}

/// Anything else: 5xx, network, timeout, a body that isn't an object.
class DataExportFailed extends DataExportException {
  const DataExportFailed();
}

/// Remote endpoints for account management & PDPA (data export, deletion).
class AccountRemoteDataSource {
  AccountRemoteDataSource(this._api);

  final ApiService _api;

  /// DELETE /api/customer/account
  Future<Map<String, dynamic>> requestDeletion(String reason) async {
    final res = await _api.dio.delete(
      '/api/customer/account',
      data: {'reason': reason},
    );
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/export — everything the platform holds about the
  /// customer, for the "ข้อมูลของฉัน" screen. Personal data: never log it.
  /// Throws a [DataExportException].
  Future<Map<String, dynamic>> exportData() =>
      _getObject('/api/customer/export');

  /// GET /api/customer/export/{section} — the next [page] of a long history
  /// (trips, orders, points_history, search_history), in the same shape as
  /// that section in [exportData]. Throws a [DataExportException].
  Future<Map<String, dynamic>> exportSection(
    String section, {
    required int page,
    int limit = 20,
  }) => _getObject(
    '/api/customer/export/${Uri.encodeComponent(section)}',
    query: {'page': page, 'limit': limit},
  );

  Future<Map<String, dynamic>> _getObject(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _api.dio.get(
        path,
        queryParameters: query,
        // The limit is per customer: show the wait instead of sitting in
        // silent retries that use up the same allowance.
        options: Options(extra: {RetryInterceptor.noRetryOn429: true}),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
    } on DioException catch (e) {
      throw dataExportError(e.response);
    }
    throw const DataExportFailed();
  }
}

/// The [DataExportException] for a failed export response (null: no response
/// at all, e.g. offline).
DataExportException dataExportError(Response<dynamic>? response) {
  final body = response?.data;
  switch (response?.statusCode) {
    case 404 when body is Map && body['error'] == 'account not found':
      return const DataExportAccountGone();
    case 429:
      final map = body is Map ? body : const {};
      final header = int.tryParse(response?.headers.value('retry-after') ?? '');
      final seconds = (map['retry_after'] as num?)?.toInt() ?? header ?? 60;
      final message = map['error'];
      return DataExportRateLimited(
        message is String && message.trim().isNotEmpty ? message : null,
        Duration(seconds: seconds.clamp(1, 3600)),
      );
    default:
      return const DataExportFailed();
  }
}
