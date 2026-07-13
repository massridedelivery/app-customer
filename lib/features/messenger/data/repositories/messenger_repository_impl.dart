import 'package:customer_app/core/managers/providers.dart';
import 'package:customer_app/core/services/api_service.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_estimate.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_order.dart';
import 'package:customer_app/features/messenger/domain/models/messenger_vehicle_type.dart';
import 'package:customer_app/features/messenger/domain/repositories/i_messenger_repository.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'messenger_repository_impl.g.dart';

@riverpod
IMessengerRepository messengerRepository(Ref ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MessengerRepositoryImpl(apiService);
}

class MessengerRepositoryImpl implements IMessengerRepository {
  final ApiService _apiService;

  MessengerRepositoryImpl(this._apiService);

  /// Error bodies are `{"message": …}` or `{"error": …}` (SCRUM-41 §0).
  Never _throwFrom(DioException e, String fallback) {
    final data = e.response?.data;
    final message = data is Map
        ? (data['message'] ?? data['error']) as String?
        : null;
    throw Exception(message ?? fallback);
  }

  @override
  Future<List<MessengerVehicleType>> getMessengerVehicleTypes() async {
    try {
      final response = await _apiService.dio.get('/api/vehicle-types');
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(MessengerVehicleType.fromJson)
          .where((v) => v.isMessenger && v.isActive)
          .toList();
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to fetch vehicle types');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<MessengerEstimate> estimate({
    required String vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String packageSizeTier,
    required double packageWeightKg,
    double? packageLengthCm,
    double? packageWidthCm,
    double? packageHeightCm,
    String? promoCode,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/messenger/customer/estimate',
        data: {
          'vehicle_type_id': vehicleTypeId,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
          'package_size_tier': packageSizeTier,
          'package_weight_kg': packageWeightKg,
          'package_length_cm': ?packageLengthCm,
          'package_width_cm': ?packageWidthCm,
          'package_height_cm': ?packageHeightCm,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode,
        },
      );
      return MessengerEstimate.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to estimate fare');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<MessengerOrder> createOrder({
    required String vehicleTypeId,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required String packageSizeTier,
    required double packageWeightKg,
    required String paymentMethod,
    String? pickupAddress,
    String? dropoffAddress,
    String? recipientName,
    String? recipientPhone,
    String? notes,
    double? packageLengthCm,
    double? packageWidthCm,
    double? packageHeightCm,
    double? codAmount,
    String? promoCode,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/messenger/customer/orders',
        data: {
          'vehicle_type_id': vehicleTypeId,
          'pickup_lat': pickupLat,
          'pickup_lng': pickupLng,
          'dropoff_lat': dropoffLat,
          'dropoff_lng': dropoffLng,
          'package_size_tier': packageSizeTier,
          'package_weight_kg': packageWeightKg,
          'payment_method': paymentMethod,
          if (pickupAddress != null && pickupAddress.isNotEmpty)
            'pickup_address': pickupAddress,
          if (dropoffAddress != null && dropoffAddress.isNotEmpty)
            'dropoff_address': dropoffAddress,
          if (recipientName != null && recipientName.isNotEmpty)
            'recipient_name': recipientName,
          if (recipientPhone != null && recipientPhone.isNotEmpty)
            'recipient_phone': recipientPhone,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'package_length_cm': ?packageLengthCm,
          'package_width_cm': ?packageWidthCm,
          'package_height_cm': ?packageHeightCm,
          if (codAmount != null && codAmount > 0) 'cod_amount': codAmount,
          if (promoCode != null && promoCode.isNotEmpty)
            'promo_code': promoCode,
        },
      );
      return MessengerOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to create order');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<MessengerOrder>> getOrders() async {
    try {
      final response = await _apiService.dio.get(
        '/api/messenger/customer/orders',
      );
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(MessengerOrder.fromJson)
          .toList();
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to fetch orders');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<MessengerOrder> getOrder(String id) async {
    try {
      final response = await _apiService.dio.get(
        '/api/messenger/customer/orders/$id',
      );
      return MessengerOrder.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to fetch order');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> cancelOrder(String id, {String? reason}) async {
    try {
      await _apiService.dio.post(
        '/api/messenger/customer/orders/$id/cancel',
        data: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to cancel order');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> reviewOrder(
    String id, {
    required int rating,
    String? comment,
  }) async {
    try {
      await _apiService.dio.post(
        '/api/messenger/customer/orders/$id/review',
        data: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );
    } on DioException catch (e) {
      // Distinct message for the already-reviewed case so the UI can bow out
      // gracefully rather than inviting a doomed retry.
      if (e.response?.statusCode == 409) {
        throw Exception('ALREADY_REVIEWED');
      }
      _throwFrom(e, 'Failed to submit review');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<dynamic>> getChat(
    String id, {
    int limit = 50,
    String? before,
  }) async {
    try {
      final response = await _apiService.dio.get(
        '/api/messenger/customer/orders/$id/chat',
        queryParameters: {'limit': limit, 'before': ?before},
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to fetch chat messages');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> sendChatMessage(
    String id, {
    required String text,
    String msgType = 'text',
    String? fileKey,
  }) async {
    try {
      await _apiService.dio.post(
        '/api/messenger/customer/orders/$id/chat',
        data: {
          'text': text,
          'msg_type': msgType,
          'file_key': ?fileKey,
        },
      );
    } on DioException catch (e) {
      _throwFrom(e, 'Failed to send message');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
