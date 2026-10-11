// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_join.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceJoinRequest _$DeviceJoinRequestFromJson(Map<String, dynamic> json) =>
    _DeviceJoinRequest(
      deviceName: json['deviceName'] as String,
      platform: json['platform'] as String,
    );

Map<String, dynamic> _$DeviceJoinRequestToJson(_DeviceJoinRequest instance) =>
    <String, dynamic>{
      'deviceName': instance.deviceName,
      'platform': instance.platform,
    };

_DeviceJoinResult _$DeviceJoinResultFromJson(Map<String, dynamic> json) =>
    _DeviceJoinResult(
      deviceId: json['deviceId'] as String,
      deviceToken: json['deviceToken'] as String,
    );

Map<String, dynamic> _$DeviceJoinResultToJson(_DeviceJoinResult instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceToken': instance.deviceToken,
    };
