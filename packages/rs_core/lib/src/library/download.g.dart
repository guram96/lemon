// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadFile _$DownloadFileFromJson(Map<String, dynamic> json) =>
    _DownloadFile(
      index: (json['index'] as num).toInt(),
      path: json['path'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      sha1: json['sha1'] as String?,
    );

Map<String, dynamic> _$DownloadFileToJson(_DownloadFile instance) =>
    <String, dynamic>{
      'index': instance.index,
      'path': instance.path,
      'sizeBytes': instance.sizeBytes,
      'sha1': ?instance.sha1,
    };

_DownloadManifest _$DownloadManifestFromJson(Map<String, dynamic> json) =>
    _DownloadManifest(
      gameId: json['gameId'] as String,
      systemId: json['systemId'] as String,
      files: (json['files'] as List<dynamic>)
          .map((e) => DownloadFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DownloadManifestToJson(_DownloadManifest instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'systemId': instance.systemId,
      'files': instance.files.map((e) => e.toJson()).toList(),
    };
