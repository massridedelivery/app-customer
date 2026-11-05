import 'dart:typed_data';

import 'package:customer_app/core/error/api_error.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/core/services/idempotency.dart';
import 'package:customer_app/features/support/domain/support_ticket.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiServiceProvider)),
);

/// The customer's reports to the support team:
///   - `POST /api/customer/support/tickets` files one
///   - `GET  /api/customer/support/tickets` lists them, newest first
///   - `GET  /api/customer/support/tickets/{id}` one, with the team's replies
///   - `POST /api/customer/support/tickets/{id}/reply` adds details
/// Photos go up with the media protocol, category `support`.
///
/// Every failure is thrown as an [ApiError] (the backend's own message).
class SupportRepository {
  SupportRepository(this._api, {Dio? storageDio})
    : _storageDio = storageDio ?? Dio();

  final ApiService _api;

  // Bare client for the presigned PUT: the app's auth header would break the
  // storage signature.
  final Dio _storageDio;

  static const _base = '/api/customer/support/tickets';

  /// Files [ticket]. [idempotencyKey] is minted once per tap of "ส่ง" and
  /// reused on retry, so a resend never files it twice.
  Future<SupportTicket> create(
    NewSupportTicket ticket, {
    required String idempotencyKey,
  }) async {
    try {
      final res = await _api.dio.post(
        _base,
        data: ticket.toJson(),
        options: Options(headers: {kIdempotencyHeader: idempotencyKey}),
      );
      return SupportTicket.fromJson(_ticketBody(res.data));
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<List<SupportTicket>> list({int page = 1, int limit = 20}) async {
    try {
      final res = await _api.dio.get(
        _base,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = res.data;
      final raw = data is List
          ? data
          : (data is Map ? (data['tickets'] ?? data['data']) : null);
      return [
        for (final t in (raw as List?) ?? const [])
          if (t is Map) SupportTicket.fromJson(Map<String, dynamic>.from(t)),
      ];
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<SupportTicket> get(String id) async {
    try {
      final res = await _api.dio.get('$_base/$id');
      return SupportTicket.fromJson(_ticketBody(res.data));
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> reply(String id, String message) async {
    try {
      await _api.dio.post('$_base/$id/reply', data: {'message': message});
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// Uploads one JPEG for a report and returns its `file_key`:
  ///   1. `GET /api/media/upload-url?category=support&content_type=image/jpeg`
  ///   2. `PUT` the bytes to `upload_url`
  ///   3. `POST /api/media/confirm {file_key}`
  Future<String> uploadPhoto(Uint8List jpeg) async {
    const contentType = 'image/jpeg';
    try {
      final res = await _api.dio.get(
        '/api/media/upload-url',
        queryParameters: {'category': 'support', 'content_type': contentType},
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      final uploadUrl = data['upload_url'] as String?;
      final fileKey = data['file_key'] as String?;
      if (uploadUrl == null || uploadUrl.isEmpty || fileKey == null) {
        throw const ApiError(message: '');
      }
      await _storageDio.put(
        uploadUrl,
        data: Stream.fromIterable([jpeg]),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: jpeg.length,
          },
        ),
      );
      await _api.dio.post('/api/media/confirm', data: {'file_key': fileKey});
      return fileKey;
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  /// The ticket in `{ticket: {...}}` or bare.
  static Map<String, dynamic> _ticketBody(Object? data) {
    final m = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final inner = m['ticket'];
    return inner is Map ? Map<String, dynamic>.from(inner) : m;
  }
}
