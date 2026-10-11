import 'package:freezed_annotation/freezed_annotation.dart';

import '../users/user.dart';

part 'login.freezed.dart';
part 'login.g.dart';

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, Object?> json) =>
      _$LoginRequestFromJson(json);
}

/// A logged-in session, returned by login and by first-run setup.
@freezed
abstract class AuthResult with _$AuthResult {
  const factory AuthResult({
    /// Sent as `Authorization: Bearer <token>` from now on.
    required String sessionToken,
    required User user,

    /// Set only by `POST /setup`, which also joins the setup device.
    String? deviceId,

    /// Set only by `POST /setup`.
    String? deviceToken,
  }) = _AuthResult;

  factory AuthResult.fromJson(Map<String, Object?> json) =>
      _$AuthResultFromJson(json);
}
