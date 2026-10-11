// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerInfo _$ServerInfoFromJson(Map<String, dynamic> json) => _ServerInfo(
  serverId: json['serverId'] as String,
  name: json['name'] as String,
  version: json['version'] as String,
  apiVersion: (json['apiVersion'] as num).toInt(),
  setupState: $enumDecode(_$ServerSetupStateEnumMap, json['setupState']),
);

Map<String, dynamic> _$ServerInfoToJson(_ServerInfo instance) =>
    <String, dynamic>{
      'serverId': instance.serverId,
      'name': instance.name,
      'version': instance.version,
      'apiVersion': instance.apiVersion,
      'setupState': _$ServerSetupStateEnumMap[instance.setupState]!,
    };

const _$ServerSetupStateEnumMap = {
  ServerSetupState.unconfigured: 'unconfigured',
  ServerSetupState.ready: 'ready',
};
