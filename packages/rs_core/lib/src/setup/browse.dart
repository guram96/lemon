import 'package:freezed_annotation/freezed_annotation.dart';

part 'browse.freezed.dart';
part 'browse.g.dart';

/// Asks the server to list a folder on its own filesystem.
@freezed
abstract class BrowseRequest with _$BrowseRequest {
  const factory BrowseRequest({
    /// Absolute path to list. `null` lists the roots: the home directory and
    /// mounted volumes or drives.
    String? path,
  }) = _BrowseRequest;

  factory BrowseRequest.fromJson(Map<String, Object?> json) =>
      _$BrowseRequestFromJson(json);
}

/// One entry of a [BrowseResult].
@freezed
abstract class BrowseEntry with _$BrowseEntry {
  const factory BrowseEntry({
    required String name,

    /// Absolute path on the server.
    required String path,
    required bool isDirectory,
    required bool readable,
  }) = _BrowseEntry;

  factory BrowseEntry.fromJson(Map<String, Object?> json) =>
      _$BrowseEntryFromJson(json);
}

/// Contents of a folder on the server.
@freezed
abstract class BrowseResult with _$BrowseResult {
  const factory BrowseResult({
    /// The listed folder, normalized and absolute.
    required String path,

    /// Parent folder, `null` at a filesystem root.
    String? parent,
    @Default([]) List<BrowseEntry> entries,

    /// Home, Desktop, Documents and mounted volumes (`/Volumes/*`, drive
    /// letters, `/media`, `/mnt`).
    @Default([]) List<BrowseEntry> shortcuts,
  }) = _BrowseResult;

  factory BrowseResult.fromJson(Map<String, Object?> json) =>
      _$BrowseResultFromJson(json);
}
