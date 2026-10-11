import 'package:freezed_annotation/freezed_annotation.dart';

part 'download.freezed.dart';
part 'download.g.dart';

/// One catalog file in a [DownloadManifest].
///
/// [path] is relative to the system folder, the same value as [GameFile.path].
/// [index] is the only selector the client sends when fetching the bytes.
@freezed
abstract class DownloadFile with _$DownloadFile {
  const factory DownloadFile({
    required int index,

    /// Path relative to the game's system folder, using `/` separators.
    required String path,
    required int sizeBytes,
    String? sha1,
  }) = _DownloadFile;

  factory DownloadFile.fromJson(Map<String, Object?> json) =>
      _$DownloadFileFromJson(json);
}

/// Every catalog file of one game. The client downloads the game as this unit.
@freezed
abstract class DownloadManifest with _$DownloadManifest {
  const factory DownloadManifest({
    required String gameId,
    required String systemId,
    required List<DownloadFile> files,
  }) = _DownloadManifest;

  factory DownloadManifest.fromJson(Map<String, Object?> json) =>
      _$DownloadManifestFromJson(json);
}
