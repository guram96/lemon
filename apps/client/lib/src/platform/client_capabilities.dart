import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_info_stub.dart'
    if (dart.library.io) 'platform_info_io.dart'
    as platform_info;

/// What this client build can do and which platform it runs on. Features
/// check these instead of testing `kIsWeb` or `Platform` directly.
@immutable
class ClientCapabilities {
  const ClientCapabilities({
    required this.canInstallGames,
    required this.canLaunchGames,
    required this.platform,
    required this.deviceName,
  });

  /// Full clients. Web is browse + admin only, like Steam on the web.
  factory ClientCapabilities.full({
    required String platform,
    required String deviceName,
  }) => ClientCapabilities(
    canInstallGames: true,
    canLaunchGames: true,
    platform: platform,
    deviceName: deviceName,
  );

  factory ClientCapabilities.web() => const ClientCapabilities(
    canInstallGames: false,
    canLaunchGames: false,
    platform: 'web',
    deviceName: 'Web browser',
  );

  /// Detects the running platform.
  factory ClientCapabilities.current() => kIsWeb
      ? ClientCapabilities.web()
      : ClientCapabilities.full(
          platform: platform_info.platformId(),
          deviceName: platform_info.deviceName(),
        );

  final bool canInstallGames;
  final bool canLaunchGames;

  /// `macos`, `windows`, `linux`, `android`, `ios` or `web`, as sent in
  /// `DeviceJoinRequest.platform`.
  final String platform;

  /// Human-readable name this device registers with, for example the host
  /// name.
  final String deviceName;
}

final clientCapabilitiesProvider = Provider<ClientCapabilities>(
  (_) => ClientCapabilities.current(),
);
