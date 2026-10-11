import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  /// The single admin account. Can manage the library, server and users.
  admin,

  /// Can browse and download games. No server-side changes.
  user,
}

@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String username,
    required UserRole role,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
