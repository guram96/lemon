import 'package:freezed_annotation/freezed_annotation.dart';

import '../library/library_root.dart';
import '../scan/scan_status.dart';

part 'server_event.freezed.dart';
part 'server_event.g.dart';

/// Push event sent by the server over the [ApiRoutes.events] WebSocket.
///
/// Encoded as JSON with a `type` discriminator: `scan_progress`,
/// `library_changed` or `root_status_changed`.
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
sealed class ServerEvent with _$ServerEvent {
  /// Scan progress. Throttled to at most 4 per second.
  const factory ServerEvent.scanProgress({required ScanStatus status}) =
      ScanProgressEvent;

  /// Games were added, updated or removed.
  const factory ServerEvent.libraryChanged({
    @Default([]) List<String> addedIds,
    @Default([]) List<String> updatedIds,
    @Default([]) List<String> removedIds,
  }) = LibraryChangedEvent;

  /// A library root went online, offline or read-only.
  const factory ServerEvent.rootStatusChanged({required LibraryRoot root}) =
      RootStatusChangedEvent;

  factory ServerEvent.fromJson(Map<String, Object?> json) =>
      _$ServerEventFromJson(json);
}
