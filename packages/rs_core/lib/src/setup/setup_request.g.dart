// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setup_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SetupRequest _$SetupRequestFromJson(Map<String, dynamic> json) =>
    _SetupRequest(
      adminUsername: json['adminUsername'] as String,
      adminPassword: json['adminPassword'] as String,
      dataDir: json['dataDir'] as String,
      libraryRoots: (json['libraryRoots'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      deviceName: json['deviceName'] as String,
    );

Map<String, dynamic> _$SetupRequestToJson(_SetupRequest instance) =>
    <String, dynamic>{
      'adminUsername': instance.adminUsername,
      'adminPassword': instance.adminPassword,
      'dataDir': instance.dataDir,
      'libraryRoots': instance.libraryRoots,
      'deviceName': instance.deviceName,
    };
