// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GameFile _$GameFileFromJson(Map<String, dynamic> json) => _GameFile(
  path: json['path'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  sha1: json['sha1'] as String?,
);

Map<String, dynamic> _$GameFileToJson(_GameFile instance) => <String, dynamic>{
  'path': instance.path,
  'sizeBytes': instance.sizeBytes,
  'sha1': ?instance.sha1,
};

_Game _$GameFromJson(Map<String, dynamic> json) => _Game(
  id: json['id'] as String,
  systemId: json['systemId'] as String,
  title: json['title'] as String,
  rootId: json['rootId'] as String,
  files: (json['files'] as List<dynamic>)
      .map((e) => GameFile.fromJson(e as Map<String, dynamic>))
      .toList(),
  artwork:
      (json['artwork'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          $enumDecode(_$ArtworkKindEnumMap, k),
          Artwork.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const {},
  description: json['description'] as String?,
  developer: json['developer'] as String?,
  publisher: json['publisher'] as String?,
  releaseYear: (json['releaseYear'] as num?)?.toInt(),
);

Map<String, dynamic> _$GameToJson(_Game instance) => <String, dynamic>{
  'id': instance.id,
  'systemId': instance.systemId,
  'title': instance.title,
  'rootId': instance.rootId,
  'files': instance.files.map((e) => e.toJson()).toList(),
  'artwork': instance.artwork.map(
    (k, e) => MapEntry(_$ArtworkKindEnumMap[k]!, e.toJson()),
  ),
  'description': ?instance.description,
  'developer': ?instance.developer,
  'publisher': ?instance.publisher,
  'releaseYear': ?instance.releaseYear,
};

const _$ArtworkKindEnumMap = {
  ArtworkKind.cover: 'cover',
  ArtworkKind.hero: 'hero',
  ArtworkKind.logo: 'logo',
  ArtworkKind.capsule: 'capsule',
  ArtworkKind.icon: 'icon',
  ArtworkKind.screenshot: 'screenshot',
};
