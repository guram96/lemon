import 'package:freezed_annotation/freezed_annotation.dart';

import 'artwork.dart';

part 'game.freezed.dart';
part 'game.g.dart';

/// A single file belonging to a game. Multi-file games (`.cue`/`.bin`,
/// `.m3u`, multi-disc) have several.
@freezed
abstract class GameFile with _$GameFile {
  const factory GameFile({
    /// Path relative to the game's system folder, using `/` separators.
    required String path,
    required int sizeBytes,
    String? sha1,
  }) = _GameFile;

  factory GameFile.fromJson(Map<String, Object?> json) =>
      _$GameFileFromJson(json);
}

/// A game in the server catalog. Always downloaded and installed as one unit.
@freezed
abstract class Game with _$Game {
  const Game._();

  const factory Game({
    required String id,

    /// EmulationStation system ID, see [GameSystems].
    required String systemId,
    required String title,

    /// ID of the [LibraryRoot] the game lives in.
    required String rootId,
    required List<GameFile> files,

    /// Selected artwork per kind. Per-game overrides replace entries here.
    @Default({}) Map<ArtworkKind, Artwork> artwork,
    String? description,
    String? developer,
    String? publisher,
    int? releaseYear,
  }) = _Game;

  factory Game.fromJson(Map<String, Object?> json) => _$GameFromJson(json);

  int get sizeBytes => files.fold(0, (sum, f) => sum + f.sizeBytes);
}
