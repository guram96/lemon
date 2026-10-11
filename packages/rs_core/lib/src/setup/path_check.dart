import 'package:freezed_annotation/freezed_annotation.dart';

part 'path_check.freezed.dart';
part 'path_check.g.dart';

/// What a checked path is meant to be used for.
enum PathKind { dataDir, libraryRoot }

@freezed
abstract class PathCheckRequest with _$PathCheckRequest {
  const factory PathCheckRequest({
    required String path,
    required PathKind kind,
  }) = _PathCheckRequest;

  factory PathCheckRequest.fromJson(Map<String, Object?> json) =>
      _$PathCheckRequestFromJson(json);
}

/// A system folder found in a candidate library root.
@freezed
abstract class DetectedSystem with _$DetectedSystem {
  const factory DetectedSystem({
    /// EmulationStation system ID, see [GameSystems].
    required String systemId,
    required int fileCount,
  }) = _DetectedSystem;

  factory DetectedSystem.fromJson(Map<String, Object?> json) =>
      _$DetectedSystemFromJson(json);
}

/// The server's verdict on a path picked during setup or in settings.
@freezed
abstract class PathCheckResult with _$PathCheckResult {
  const PathCheckResult._();

  const factory PathCheckResult({
    /// Normalized absolute path.
    required String path,

    /// The kind that was checked, echoed from [PathCheckRequest.kind].
    required PathKind kind,
    required bool exists,
    required bool readable,

    /// For a missing [PathKind.dataDir], whether it can be created.
    required bool writable,

    /// The OS refused access (macOS TCC, ACLs). The client shows how to grant
    /// it.
    @Default(false) bool permissionDenied,

    /// ID from an existing `.retrosteam/root.json`: the folder can be adopted.
    String? existingMarkerId,

    /// System folders found. Only for [PathKind.libraryRoot].
    @Default([]) List<DetectedSystem> detectedSystems,
    int? freeBytes,

    /// Human-readable notes, for example "read-only filesystem", "not empty".
    @Default([]) List<String> warnings,
  }) = _PathCheckResult;

  factory PathCheckResult.fromJson(Map<String, Object?> json) =>
      _$PathCheckResultFromJson(json);

  /// Whether the path can be used for [kind].
  ///
  /// A data directory must be writable (the server reports a missing but
  /// creatable folder as writable). A library root must exist and be
  /// readable.
  bool get ok => switch (kind) {
    PathKind.dataDir => writable && !permissionDenied,
    PathKind.libraryRoot => exists && readable && !permissionDenied,
  };
}
