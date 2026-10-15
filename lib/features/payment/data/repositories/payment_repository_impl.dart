import 'package:customer_app/core/error/server_exception.dart';
import 'package:customer_app/core/localization/locale_controller.dart';
import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/features/payment/data/datasources/payment_data_source.dart';
import 'package:customer_app/features/payment/domain/models/payment_intent.dart';
import 'package:customer_app/features/payment/domain/repositories/i_payment_repository.dart';
import 'package:customer_app/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'payment_repository_impl.g.dart';

@riverpod
IPaymentRepository paymentRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  // Fallback error messages follow the app language.
  final locale = ref.watch(localeControllerProvider);
  return PaymentRepositoryImpl(
    PaymentDataSource(apiService),
    lookupAppLocalizations(Locale(locale.languageCode)),
  );
}

class PaymentRepositoryImpl implements IPaymentRepository {
  final PaymentDataSource _dataSource;
  final AppLocalizations _l10n;

  PaymentRepositoryImpl(this._dataSource, this._l10n);

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
    String? cardToken,
  }) async {
    try {
      final data = await _dataSource.createIntent(
        jobId: jobId,
        paymentMethod: paymentMethod,
        cardToken: cardToken,
      );
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      throw _serverError(e, _l10n.payCreateIntentFailed);
    }
  }

  @override
  Future<PaymentIntent> getIntent(String intentId) async {
    try {
      final data = await _dataSource.getIntent(intentId);
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      throw ServerException(_message(e, _l10n.payCheckStatusFailed));
    }
  }

  @override
  Future<PaymentIntent?> getIntentByJob(String jobId) async {
    try {
      final data = await _dataSource.getIntentByJob(jobId);
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ServerException(_message(e, _l10n.payCheckIntentFailed));
    }
  }

  @override
  Future<PaymentIntent> createIntentForOrder({
    required String orderId,
    required String paymentMethod,
    String? cardToken,
  }) async {
    try {
      final data = await _dataSource.createIntentForOrder(
        orderId: orderId,
        paymentMethod: paymentMethod,
        cardToken: cardToken,
      );
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      throw _serverError(e, _l10n.payCreateIntentFailed);
    }
  }

  @override
  Future<PaymentIntent?> getIntentByOrder(String orderId) async {
    try {
      final data = await _dataSource.getIntentByOrder(orderId);
      return PaymentIntent.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ServerException(_message(e, _l10n.payCheckIntentFailed));
    }
  }

  /// Keeps the status code and body `code` so callers can tell a 409 (the
  /// backend refusing a new intent) from a genuine failure.
  ServerException _serverError(DioException e, String fallback) {
    final data = e.response?.data;
    return ServerException(
      _message(e, fallback),
      statusCode: e.response?.statusCode,
      code: data is Map ? data['code']?.toString() : null,
    );
  }

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }
}
