import 'package:customer_app/core/services/api_service.dart';

class PaymentDataSource {
  final ApiService _apiService;

  PaymentDataSource(this._apiService);

  Future<void> saveCard({
    required String cardToken,
    required String email,
  }) async {
    await _apiService.dio.post(
      '/api/payment/card',
      data: {'card_token': cardToken, 'email': email},
    );
  }

  /// POST /api/payment/intent — body is `{ job_id, payment_method }`.
  /// No `amount` field: the backend derives the payable from the job fare.
  Future<Map<String, dynamic>> createIntent({
    required String jobId,
    required String paymentMethod,
  }) async {
    final response = await _apiService.dio.post(
      '/api/payment/intent',
      data: {
        'job_id': jobId,
        'payment_method': paymentMethod,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/payment/intent — body is `{ order_id, payment_method }` for
  /// messenger/food orders (SCRUM-35 §3.2/§3.3). Amount is server-derived.
  Future<Map<String, dynamic>> createIntentForOrder({
    required String orderId,
    required String paymentMethod,
  }) async {
    final response = await _apiService.dio.post(
      '/api/payment/intent',
      data: {
        'order_id': orderId,
        'payment_method': paymentMethod,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/payment/intent/{id}
  Future<Map<String, dynamic>> getIntent(String intentId) async {
    final response = await _apiService.dio.get('/api/payment/intent/$intentId');
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/payment/intent/job/{jobId}
  Future<Map<String, dynamic>> getIntentByJob(String jobId) async {
    final response = await _apiService.dio.get(
      '/api/payment/intent/job/$jobId',
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/payment/intent/order/{orderId}
  Future<Map<String, dynamic>> getIntentByOrder(String orderId) async {
    final response = await _apiService.dio.get(
      '/api/payment/intent/order/$orderId',
    );
    return response.data as Map<String, dynamic>;
  }
}
