import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_info.freezed.dart';
part 'server_info.g.dart';

/// Lifecycle state of a server.
enum ServerSetupState {
  /// First-run setup has not been completed: no admin, no data directory.
  unconfigured,

  /// Setup is complete and the server is serving its library.
  ready,
}

/// Public, unauthenticated description of a server.
@freezed
abstract class ServerInfo with _$ServerInfo {
  const factory ServerInfo({
    /// Stable unique ID, generated once on first start.
    required String serverId,

    /// Display name, for example the host machine name.
    required String name,

    /// Server build version.
    required String version,

    /// API version, see [ApiRoutes.version].
    required int apiVersion,
    required ServerSetupState setupState,
  }) = _ServerInfo;

  factory ServerInfo.fromJson(Map<String, Object?> json) =>
      _$ServerInfoFromJson(json);
}
