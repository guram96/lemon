// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_root.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibraryRoot _$LibraryRootFromJson(Map<String, dynamic> json) => _LibraryRoot(
  id: json['id'] as String,
  label: json['label'] as String,
  status: $enumDecode(_$LibraryRootStatusEnumMap, json['status']),
);

Map<String, dynamic> _$LibraryRootToJson(_LibraryRoot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'status': _$LibraryRootStatusEnumMap[instance.status]!,
    };

const _$LibraryRootStatusEnumMap = {
  LibraryRootStatus.online: 'online',
  LibraryRootStatus.readOnly: 'readOnly',
  LibraryRootStatus.offline: 'offline',
};
