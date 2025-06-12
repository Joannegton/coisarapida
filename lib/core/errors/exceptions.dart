/// Exceções customizadas do aplicativo
library;

/// Exceção base para erros do aplicativo
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

/// Exceção para erros de autenticação
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Exceção para erros de rede
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Exceção para erros de servidor
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Exceção para erros de cache
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Exceção para erros de validação
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Exceção para recursos não encontrados
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Exceção para operações não permitidas
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}
