import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_root.freezed.dart';
part 'library_root.g.dart';

enum LibraryRootStatus {
  /// Mounted and writable.
  online,

  /// Mounted but read-only (for example NTFS on macOS). Browse and download only.
  readOnly,

  /// Not found (drive unplugged or moved). Its games stay in the catalog.
  offline,
}

/// A ROM folder on the server, laid out with EmulationStation system folder names.
///
/// Identified by [id], stored in a marker file inside the folder, so it is
/// found again when the drive is mounted at another path or on another machine.
@freezed
abstract class LibraryRoot with _$LibraryRoot {
  const factory LibraryRoot({
    required String id,
    required String label,
    required LibraryRootStatus status,
  }) = _LibraryRoot;

  factory LibraryRoot.fromJson(Map<String, Object?> json) =>
      _$LibraryRootFromJson(json);
}
