import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/payment/data/datasources/payment_data_source.dart';
import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:customer_app/features/payment/domain/repositories/i_payment_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_repository_impl.g.dart';

@riverpod
IPaymentRepository paymentRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return PaymentRepositoryImpl(PaymentDataSource(apiService));
}

class PaymentRepositoryImpl implements IPaymentRepository {
  final PaymentDataSource _dataSource;

  PaymentRepositoryImpl(this._dataSource);

  @override
  Future<void> saveCard({
    required String cardToken,
    required String email,
  }) async {
    return _dataSource.saveCard(cardToken: cardToken, email: email);
  }

  @override
  Future<PaymentIntent> createIntent({
    required String jobId,
    required String paymentMethod,
  }) async {
    try {
      final data = await _dataSource.createIntent(
        jobId: jobId,
        paymentMethod: paymentMethod,
      );
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'สร้างรายการชำระเงินไม่สำเร็จ'));
    }
  }

  @override
  Future<PaymentIntent> getIntent(String intentId) async {
    try {
      final data = await _dataSource.getIntent(intentId);
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'ตรวจสอบสถานะการชำระเงินไม่สำเร็จ'));
    }
  }

  @override
  Future<PaymentIntent?> getIntentByJob(String jobId) async {
    try {
      final data = await _dataSource.getIntentByJob(jobId);
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ServerException(_message(e, 'ตรวจสอบรายการชำระเงินไม่สำเร็จ'));
    }
  }

  @override
  Future<PaymentIntent> createIntentForOrder({
    required String orderId,
    required String paymentMethod,
  }) async {
    try {
      final data = await _dataSource.createIntentForOrder(
        orderId: orderId,
        paymentMethod: paymentMethod,
      );
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_message(e, 'สร้างรายการชำระเงินไม่สำเร็จ'));
    }
  }

  @override
  Future<PaymentIntent?> getIntentByOrder(String orderId) async {
    try {
      final data = await _dataSource.getIntentByOrder(orderId);
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ServerException(_message(e, 'ตรวจสอบรายการชำระเงินไม่สำเร็จ'));
    }
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}
