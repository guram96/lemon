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
}
