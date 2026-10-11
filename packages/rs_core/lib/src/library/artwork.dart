import 'package:freezed_annotation/freezed_annotation.dart';

part 'artwork.freezed.dart';
part 'artwork.g.dart';

/// Kinds of artwork, following Steam's library asset types.
enum ArtworkKind {
  /// Vertical library capsule / box art.
  cover,

  /// Wide background at the top of the game page.
  hero,

  /// Transparent title logo drawn over the hero.
  logo,

  /// Horizontal capsule used in shelves and recents.
  capsule,

  icon,
  screenshot,
}

enum ArtworkSource { screenScraper, steamGridDb, upload }

/// Reference to a processed artwork file served by the server.
@freezed
abstract class Artwork with _$Artwork {
  const factory Artwork({
    required String id,
    required ArtworkKind kind,
    required ArtworkSource source,
    int? width,
    int? height,
  }) = _Artwork;

  factory Artwork.fromJson(Map<String, Object?> json) =>
      _$ArtworkFromJson(json);
}
