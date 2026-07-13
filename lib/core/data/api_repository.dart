import 'package:dio/dio.dart';

/// Central repository that wraps all Customer API endpoints.
/// Depends on ApiService (Dio with auth interceptor + auto-refresh).
class ApiRepository {
  final Dio _dio;

  ApiRepository(this._dio);

  // ─── AUTH ─────────────────────────────────────────────────────────────────

  /// POST /auth/otp/send
  Future<Map<String, dynamic>> sendOtp(String phone, {String? deviceId}) async {
    final res = await _dio.post(
      '/auth/otp/send',
      data: {'phone': phone, if (deviceId != null) 'device_id': deviceId},
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
    required String refId,
    required String role,
    String? fullName,
  }) async {
    final res = await _dio.post(
      '/auth/otp/verify',
      data: {
        'phone': phone,
        'otp': otp,
        'ref_id': refId,
        'role': role,
        if (fullName != null) 'full_name': fullName,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── FORGOT PASSWORD ──────────────────────────────────────────────────────

  /// POST /auth/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /auth/forgot-password/verify
  Future<Map<String, dynamic>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _dio.post(
      '/auth/forgot-password/verify',
      data: {'email': email, 'otp': otp},
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /auth/forgot-password/reset
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String password,
    required String refId,
  }) async {
    final res = await _dio.post(
      '/auth/forgot-password/reset',
      data: {'email': email, 'password': password, 'ref_id': refId},
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── DEVICES (push notifications) ─────────────────────────────────────────
  // TODO(backend): endpoints not implemented server-side yet — proposed
  // contract lives in docs/push-notifications.md. Callers swallow failures so
  // login/logout keep working until the backend ships.

  /// POST /api/customer/devices — register this device's FCM token.
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post(
      '/api/customer/devices',
      data: {'token': token, 'platform': platform},
    );
  }

  /// DELETE /api/customer/devices — remove the token on logout.
  Future<void> unregisterDeviceToken(String token) async {
    await _dio.delete('/api/customer/devices', data: {'token': token});
  }

  // ─── TRIPS ────────────────────────────────────────────────────────────────

  /// GET /api/customer/trips
  Future<Map<String, dynamic>> getTripHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final res = await _dio.get(
      '/api/customer/trips',
      queryParameters: {'page': page, 'limit': limit},
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── JOBS ─────────────────────────────────────────────────────────────────

  /// POST /api/customer/jobs
  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/customer/jobs', data: body);
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/jobs/{id}
  Future<Map<String, dynamic>> getJob(String id) async {
    final res = await _dio.get('/api/customer/jobs/$id');
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/jobs/{id}/cancel
  Future<Map<String, dynamic>> cancelJob(String id) async {
    final res = await _dio.post('/api/customer/jobs/$id/cancel');
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/jobs/estimate
  Future<Map<String, dynamic>> estimateJob(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/customer/jobs/estimate', data: body);
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/jobs/{id}/rate
  Future<Map<String, dynamic>> rateJob(
    String id, {
    required int rating,
    String? comment,
  }) async {
    final res = await _dio.post(
      '/api/customer/jobs/$id/rate',
      data: {'rating': rating, if (comment != null) 'comment': comment},
    );
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/jobs/{id}/chat
  Future<List<dynamic>> getJobChat(
    String id, {
    int limit = 50,
    String? before,
  }) async {
    final res = await _dio.get(
      '/api/customer/jobs/$id/chat',
      queryParameters: {'limit': limit, if (before != null) 'before': before},
    );
    return res.data as List<dynamic>;
  }

  /// POST /api/customer/jobs/{id}/chat
  Future<Map<String, dynamic>> sendJobChatMessage(
    String id, {
    required String text,
    required String msgType,
    String? fileKey,
  }) async {
    final res = await _dio.post(
      '/api/customer/jobs/$id/chat',
      data: {
        'text': text,
        'msg_type': msgType,
        if (fileKey != null) 'file_key': fileKey,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/jobs/schedule
  Future<Map<String, dynamic>> scheduleJob(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/customer/jobs/schedule', data: body);
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/jobs/scheduled
  Future<List<dynamic>> getScheduledJobs({String status = 'PENDING'}) async {
    final res = await _dio.get(
      '/api/customer/jobs/scheduled',
      queryParameters: {'status': status},
    );
    return res.data as List<dynamic>;
  }

  /// POST /api/customer/jobs/scheduled/{id}/cancel
  Future<Map<String, dynamic>> cancelScheduledJob(String id) async {
    final res = await _dio.post('/api/customer/jobs/scheduled/$id/cancel');
    return res.data as Map<String, dynamic>;
  }

  // ─── FOOD ORDERS ──────────────────────────────────────────────────────────

  /// POST /api/customer/orders
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> body) async {
    final res = await _dio.post('/api/customer/orders', data: body);
    return res.data as Map<String, dynamic>;
  }

  /// GET /api/customer/orders/{id}/chat
  Future<List<dynamic>> getOrderChat(
    String id, {
    int limit = 50,
    String? before,
  }) async {
    final res = await _dio.get(
      '/api/customer/orders/$id/chat',
      queryParameters: {'limit': limit, if (before != null) 'before': before},
    );
    return res.data as List<dynamic>;
  }

  /// POST /api/customer/orders/{id}/chat
  Future<Map<String, dynamic>> sendOrderChatMessage(
    String id, {
    required String text,
    required String msgType,
    String? fileKey,
  }) async {
    final res = await _dio.post(
      '/api/customer/orders/$id/chat',
      data: {
        'text': text,
        'msg_type': msgType,
        if (fileKey != null) 'file_key': fileKey,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /api/customer/orders/{id}/review
  Future<Map<String, dynamic>> reviewOrder(
    String id, {
    required int rating,
    String? comment,
  }) async {
    final res = await _dio.post(
      '/api/customer/orders/$id/review',
      data: {'rating': rating, if (comment != null) 'comment': comment},
    );
    return res.data as Map<String, dynamic>;
  }

  // ─── GEO / PIN SNAP ──────────────────────────────────────────────────────

  /// GET /api/geospatial/place-search?query=X&lat=Y&lng=Z
  Future<List<dynamic>> searchPlaces(
    String query, {
    double? lat,
    double? lng,
  }) async {
    final res = await _dio.get(
      '/api/geospatial/place-search',
      queryParameters: {
        'query': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return res.data as List<dynamic>;
  }

  /// GET /api/customer/pin-snap?lat=X&lng=Y
  Future<Map<String, dynamic>> pinSnap({
    required double lat,
    required double lng,
  }) async {
    final res = await _dio.get(
      '/api/customer/pin-snap',
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return res.data as Map<String, dynamic>;
  }
}
