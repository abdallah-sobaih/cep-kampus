/// Sealed exception hierarchy for all recoverable application errors.
/// Every error that can reach the UI should be one of these types.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

/// The server returned an error status code (4xx / 5xx).
final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

/// The request timed out before the server responded.
final class TimeoutException extends AppException {
  const TimeoutException()
      : super('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
}

/// The device has no network connectivity.
final class NetworkException extends AppException {
  const NetworkException()
      : super('İnternet bağlantısı bulunamadı.');
}

/// An unexpected error that does not fit the categories above.
final class UnknownException extends AppException {
  const UnknownException(super.message);
}