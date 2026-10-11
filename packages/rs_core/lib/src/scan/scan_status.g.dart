// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScanStatus _$ScanStatusFromJson(Map<String, dynamic> json) => _ScanStatus(
  phase: $enumDecode(_$ScanPhaseEnumMap, json['phase']),
  processed: (json['processed'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt() ?? 0,
  currentSystemId: json['currentSystemId'] as String?,
  currentFile: json['currentFile'] as String?,
  added: (json['added'] as num?)?.toInt() ?? 0,
  updated: (json['updated'] as num?)?.toInt() ?? 0,
  removed: (json['removed'] as num?)?.toInt() ?? 0,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  finishedAt: json['finishedAt'] == null
      ? null
      : DateTime.parse(json['finishedAt'] as String),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ScanStatusToJson(_ScanStatus instance) =>
    <String, dynamic>{
      'phase': _$ScanPhaseEnumMap[instance.phase]!,
      'processed': instance.processed,
      'total': instance.total,
      'currentSystemId': ?instance.currentSystemId,
      'currentFile': ?instance.currentFile,
      'added': instance.added,
      'updated': instance.updated,
      'removed': instance.removed,
      'startedAt': ?instance.startedAt?.toIso8601String(),
      'finishedAt': ?instance.finishedAt?.toIso8601String(),
      'error': ?instance.error,
    };

const _$ScanPhaseEnumMap = {
  ScanPhase.idle: 'idle',
  ScanPhase.discovering: 'discovering',
  ScanPhase.hashing: 'hashing',
  ScanPhase.saving: 'saving',
  ScanPhase.done: 'done',
  ScanPhase.failed: 'failed',
};
