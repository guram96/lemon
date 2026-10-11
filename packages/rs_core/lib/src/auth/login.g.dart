// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

_AuthResult _$AuthResultFromJson(Map<String, dynamic> json) => _AuthResult(
  sessionToken: json['sessionToken'] as String,
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  deviceId: json['deviceId'] as String?,
  deviceToken: json['deviceToken'] as String?,
);

Map<String, dynamic> _$AuthResultToJson(_AuthResult instance) =>
    <String, dynamic>{
      'sessionToken': instance.sessionToken,
      'user': instance.user.toJson(),
      'deviceId': ?instance.deviceId,
      'deviceToken': ?instance.deviceToken,
    };
