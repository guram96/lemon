// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BrowseRequest _$BrowseRequestFromJson(Map<String, dynamic> json) =>
    _BrowseRequest(path: json['path'] as String?);

Map<String, dynamic> _$BrowseRequestToJson(_BrowseRequest instance) =>
    <String, dynamic>{'path': ?instance.path};

_BrowseEntry _$BrowseEntryFromJson(Map<String, dynamic> json) => _BrowseEntry(
  name: json['name'] as String,
  path: json['path'] as String,
  isDirectory: json['isDirectory'] as bool,
  readable: json['readable'] as bool,
);

Map<String, dynamic> _$BrowseEntryToJson(_BrowseEntry instance) =>
    <String, dynamic>{
      'name': instance.name,
      'path': instance.path,
      'isDirectory': instance.isDirectory,
      'readable': instance.readable,
    };

_BrowseResult _$BrowseResultFromJson(Map<String, dynamic> json) =>
    _BrowseResult(
      path: json['path'] as String,
      parent: json['parent'] as String?,
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => BrowseEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      shortcuts:
          (json['shortcuts'] as List<dynamic>?)
              ?.map((e) => BrowseEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$BrowseResultToJson(_BrowseResult instance) =>
    <String, dynamic>{
      'path': instance.path,
      'parent': ?instance.parent,
      'entries': instance.entries.map((e) => e.toJson()).toList(),
      'shortcuts': instance.shortcuts.map((e) => e.toJson()).toList(),
    };
