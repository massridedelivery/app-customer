import 'package:customer_app/core/error/server_exception.dart';
import 'package:dio/dio.dart';

sealed class FoodDeliveryException extends ServerException {
  final int? statusCode;

  FoodDeliveryException(super.message, [this.statusCode]);
}

class BelowMinOrderAmountException extends FoodDeliveryException {
  BelowMinOrderAmountException(super.message, [super.statusCode = 400]);
}

class RestaurantClosedException extends FoodDeliveryException {
  RestaurantClosedException(super.message, [super.statusCode = 400]);
}

class ItemNotAvailableException extends FoodDeliveryException {
  ItemNotAvailableException(super.message, [super.statusCode = 400]);
}

class InvalidTransitionException extends FoodDeliveryException {
  InvalidTransitionException(super.message, [super.statusCode = 400]);
}

class UnauthorizedException extends FoodDeliveryException {
  UnauthorizedException(super.message, [super.statusCode = 401]);
}

class ForbiddenException extends FoodDeliveryException {
  ForbiddenException(super.message, [super.statusCode = 403]);
}

class NotFoundException extends FoodDeliveryException {
  NotFoundException(super.message, [super.statusCode = 404]);
}

class CoverageException extends FoodDeliveryException {
  CoverageException(super.message, [super.statusCode = 422]);
}

class RateLimitException extends FoodDeliveryException {
  RateLimitException(super.message, [super.statusCode = 429]);
}

class InternalServerErrorException extends FoodDeliveryException {
  InternalServerErrorException(super.message, [super.statusCode = 500]);
}

class UnknownFoodDeliveryException extends FoodDeliveryException {
  UnknownFoodDeliveryException(super.message, [super.statusCode]);
}

ServerException mapDioErrorToException(DioException e, String defaultMessage) {
  final statusCode = e.response?.statusCode;
  final data = e.response?.data;
  final message = (data is Map)
      ? (data['message'] ?? data['error'] ?? defaultMessage)
      : defaultMessage;

  if (statusCode == 400) {
    final lowerMessage = message.toString().toLowerCase();
    if (lowerMessage.contains('min_order_amount') || lowerMessage.contains('below')) {
      return BelowMinOrderAmountException(message.toString());
    } else if (lowerMessage.contains('open') || lowerMessage.contains('closed')) {
      return RestaurantClosedException(message.toString());
    } else if (lowerMessage.contains('available') || lowerMessage.contains('stock') || lowerMessage.contains('oos')) {
      return ItemNotAvailableException(message.toString());
    } else if (lowerMessage.contains('transition') || lowerMessage.contains('cancel')) {
      return InvalidTransitionException(message.toString());
    }
    return UnknownFoodDeliveryException(message.toString(), 400);
  } else if (statusCode == 401) {
    return UnauthorizedException(message.toString());
  } else if (statusCode == 403) {
    return ForbiddenException(message.toString());
  } else if (statusCode == 404) {
    return NotFoundException(message.toString());
  } else if (statusCode == 422) {
    return CoverageException(message.toString());
  } else if (statusCode == 429) {
    return RateLimitException(message.toString());
  } else if (statusCode == 500) {
    return InternalServerErrorException(message.toString());
  }
  return ServerException(message.toString());
}
