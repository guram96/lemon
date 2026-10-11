import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

/// Error body returned by the server for any non-2xx response.
@freezed
abstract class ApiError with _$ApiError {
  const factory ApiError({
    /// Stable, machine-readable code, for example `not_found`.
    required String code,

    /// Human-readable message. Not meant for localization.
    required String message,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, Object?> json) =>
      _$ApiErrorFromJson(json);
}

/// Well-known [ApiError.code] values.
abstract final class ApiErrorCodes {
  static const notFound = 'not_found';
  static const unauthorized = 'unauthorized';
  static const forbidden = 'forbidden';
  static const badRequest = 'bad_request';
  static const internal = 'internal';
  static const setupRequired = 'setup_required';
  static const alreadyConfigured = 'already_configured';
  static const loopbackOnly = 'loopback_only';
  static const invalidCredentials = 'invalid_credentials';
  static const rateLimited = 'rate_limited';
  static const pathInvalid = 'path_invalid';
  static const conflict = 'conflict';

  /// Client-side only: the server could not be reached.
  static const unreachable = 'unreachable';
}
