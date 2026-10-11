// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanProgressEvent _$ScanProgressEventFromJson(Map<String, dynamic> json) =>
    ScanProgressEvent(
      status: ScanStatus.fromJson(json['status'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$ScanProgressEventToJson(ScanProgressEvent instance) =>
    <String, dynamic>{
      'status': instance.status.toJson(),
      'type': instance.$type,
    };

LibraryChangedEvent _$LibraryChangedEventFromJson(Map<String, dynamic> json) =>
    LibraryChangedEvent(
      addedIds:
          (json['addedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updatedIds:
          (json['updatedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      removedIds:
          (json['removedIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$LibraryChangedEventToJson(
  LibraryChangedEvent instance,
) => <String, dynamic>{
  'addedIds': instance.addedIds,
  'updatedIds': instance.updatedIds,
  'removedIds': instance.removedIds,
  'type': instance.$type,
};

RootStatusChangedEvent _$RootStatusChangedEventFromJson(
  Map<String, dynamic> json,
) => RootStatusChangedEvent(
  root: LibraryRoot.fromJson(json['root'] as Map<String, dynamic>),
  $type: json['type'] as String?,
);

Map<String, dynamic> _$RootStatusChangedEventToJson(
  RootStatusChangedEvent instance,
) => <String, dynamic>{'root': instance.root.toJson(), 'type': instance.$type};
