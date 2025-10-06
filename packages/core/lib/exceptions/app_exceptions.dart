/// 앱 전용 예외 클래스들

/// API 관련 예외
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  const ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${endpoint != null ? ' at $endpoint' : ''}';
  }
}

/// 인증 관련 예외
class AuthException implements Exception {
  final String message;
  final String? errorCode;

  const AuthException({
    required this.message,
    this.errorCode,
  });

  @override
  String toString() {
    return 'AuthException: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
  }
}

/// 네트워크 관련 예외
class NetworkException implements Exception {
  final String message;
  final String? originalError;

  const NetworkException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() {
    return 'NetworkException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
  }
}

/// 저장소 관련 예외
class StorageException implements Exception {
  final String message;
  final String? key;

  const StorageException({
    required this.message,
    this.key,
  });

  @override
  String toString() {
    return 'StorageException: $message${key != null ? ' (Key: $key)' : ''}';
  }
}

/// 유효성 검사 관련 예외
class ValidationException implements Exception {
  final String message;
  final String? field;

  const ValidationException({
    required this.message,
    this.field,
  });

  @override
  String toString() {
    return 'ValidationException: $message${field != null ? ' (Field: $field)' : ''}';
  }
}
