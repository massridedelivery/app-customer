// lib/core/exceptions/server_exception.dart

class ServerException implements Exception {
  final String message;

  /// HTTP status of the failed call, when there was a response (e.g. 409 for
  /// a payment intent the backend refuses to create).
  final int? statusCode;

  /// Machine-readable `code` from the error body, when the backend sent one.
  final String? code;

  ServerException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;
}
