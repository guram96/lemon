// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'path_check.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PathCheckRequest _$PathCheckRequestFromJson(Map<String, dynamic> json) =>
    _PathCheckRequest(
      path: json['path'] as String,
      kind: $enumDecode(_$PathKindEnumMap, json['kind']),
    );

Map<String, dynamic> _$PathCheckRequestToJson(_PathCheckRequest instance) =>
    <String, dynamic>{
      'path': instance.path,
      'kind': _$PathKindEnumMap[instance.kind]!,
    };

const _$PathKindEnumMap = {
  PathKind.dataDir: 'dataDir',
  PathKind.libraryRoot: 'libraryRoot',
};

_DetectedSystem _$DetectedSystemFromJson(Map<String, dynamic> json) =>
    _DetectedSystem(
      systemId: json['systemId'] as String,
      fileCount: (json['fileCount'] as num).toInt(),
    );

Map<String, dynamic> _$DetectedSystemToJson(_DetectedSystem instance) =>
    <String, dynamic>{
      'systemId': instance.systemId,
      'fileCount': instance.fileCount,
    };

_PathCheckResult _$PathCheckResultFromJson(Map<String, dynamic> json) =>
    _PathCheckResult(
      path: json['path'] as String,
      kind: $enumDecode(_$PathKindEnumMap, json['kind']),
      exists: json['exists'] as bool,
      readable: json['readable'] as bool,
      writable: json['writable'] as bool,
      permissionDenied: json['permissionDenied'] as bool? ?? false,
      existingMarkerId: json['existingMarkerId'] as String?,
      detectedSystems:
          (json['detectedSystems'] as List<dynamic>?)
              ?.map((e) => DetectedSystem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      freeBytes: (json['freeBytes'] as num?)?.toInt(),
      warnings:
          (json['warnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PathCheckResultToJson(
  _PathCheckResult instance,
) => <String, dynamic>{
  'path': instance.path,
  'kind': _$PathKindEnumMap[instance.kind]!,
  'exists': instance.exists,
  'readable': instance.readable,
  'writable': instance.writable,
  'permissionDenied': instance.permissionDenied,
  'existingMarkerId': ?instance.existingMarkerId,
  'detectedSystems': instance.detectedSystems.map((e) => e.toJson()).toList(),
  'freeBytes': ?instance.freeBytes,
  'warnings': instance.warnings,
};
