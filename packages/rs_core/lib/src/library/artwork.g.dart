// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artwork.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Artwork _$ArtworkFromJson(Map<String, dynamic> json) => _Artwork(
  id: json['id'] as String,
  kind: $enumDecode(_$ArtworkKindEnumMap, json['kind']),
  source: $enumDecode(_$ArtworkSourceEnumMap, json['source']),
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
);

Map<String, dynamic> _$ArtworkToJson(_Artwork instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$ArtworkKindEnumMap[instance.kind]!,
  'source': _$ArtworkSourceEnumMap[instance.source]!,
  'width': ?instance.width,
  'height': ?instance.height,
};

const _$ArtworkKindEnumMap = {
  ArtworkKind.cover: 'cover',
  ArtworkKind.hero: 'hero',
  ArtworkKind.logo: 'logo',
  ArtworkKind.capsule: 'capsule',
  ArtworkKind.icon: 'icon',
  ArtworkKind.screenshot: 'screenshot',
};

const _$ArtworkSourceEnumMap = {
  ArtworkSource.screenScraper: 'screenScraper',
  ArtworkSource.steamGridDb: 'steamGridDb',
  ArtworkSource.upload: 'upload',
};
