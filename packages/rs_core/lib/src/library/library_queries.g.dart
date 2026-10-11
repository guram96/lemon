// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_queries.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SystemSummary _$SystemSummaryFromJson(Map<String, dynamic> json) =>
    _SystemSummary(
      systemId: json['systemId'] as String,
      name: json['name'] as String,
      gameCount: (json['gameCount'] as num).toInt(),
    );

Map<String, dynamic> _$SystemSummaryToJson(_SystemSummary instance) =>
    <String, dynamic>{
      'systemId': instance.systemId,
      'name': instance.name,
      'gameCount': instance.gameCount,
    };

_GamePage _$GamePageFromJson(Map<String, dynamic> json) => _GamePage(
  games: (json['games'] as List<dynamic>)
      .map((e) => Game.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$GamePageToJson(_GamePage instance) => <String, dynamic>{
  'games': instance.games.map((e) => e.toJson()).toList(),
  'total': instance.total,
};
