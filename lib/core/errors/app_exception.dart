import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// The only error type the UI ever shows. [message] is always user-safe.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message (cause: $cause)';
}

class NetworkException extends AppException {
  const NetworkException({Object? cause})
      : super(
          'No internet connection. Please check your network and try again.',
          cause: cause,
        );
}

class ConfigException extends AppException {
  const ConfigException(super.message);
}

class AuthFailure extends AppException {
  const AuthFailure({Object? cause})
      : super(
          "We couldn't set up your session. Please try again.",
          cause: cause,
        );
}

class InsufficientCreditsException extends AppException {
  const InsufficientCreditsException()
      : super("You're out of credits. Get more to continue.");
}

class RateLimitedException extends AppException {
  const RateLimitedException()
      : super("You're going a bit fast. Please wait a few minutes and retry.");
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message);
}

class UserCancelledException extends AppException {
  const UserCancelledException() : super('Cancelled.');
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Something went wrong on our side. Please try again.',
  ]) : super(cause: null);
}

class UnknownException extends AppException {
  const UnknownException({Object? cause})
      : super('Something went wrong. Please try again.', cause: cause);
}

/// Maps any thrown object to a friendly [AppException].
AppException mapError(Object error) {
  return switch (error) {
    AppException() => error,
    SocketException() || TimeoutException() || HttpException() =>
      NetworkException(cause: error),
    AuthRetryableFetchException() => NetworkException(cause: error),
    AuthException() => AuthFailure(cause: error),
    FunctionException() => _mapFunctionError(error),
    PostgrestException() => UnknownException(cause: error),
    StorageException() => UnknownException(cause: error),
    _ => UnknownException(cause: error),
  };
}

/// Edge Functions reply with `{ "code": "...", "message": "..." }` on errors.
AppException _mapFunctionError(FunctionException error) {
  final details = error.details;
  final code = details is Map ? details['code'] as String? : null;
  final message = details is Map ? details['message'] as String? : null;
  return switch (code) {
    'insufficient_credits' => const InsufficientCreditsException(),
    'rate_limited' => const RateLimitedException(),
    _ when error.status >= 500 => const ServerException(),
    _ when message != null => ServerException(message),
    _ => const ServerException(),
  };
}
