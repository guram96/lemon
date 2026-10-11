import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this client build can do. Features check these flags instead of
/// testing the platform directly.
@immutable
class ClientCapabilities {
  const ClientCapabilities({
    required this.canInstallGames,
    required this.canLaunchGames,
  });

  /// Full clients. Web is browse + admin only, like Steam on the web.
  static const full = ClientCapabilities(
    canInstallGames: true,
    canLaunchGames: true,
  );
  static const web = ClientCapabilities(
    canInstallGames: false,
    canLaunchGames: false,
  );

  final bool canInstallGames;
  final bool canLaunchGames;
}

final clientCapabilitiesProvider = Provider<ClientCapabilities>(
  (_) => kIsWeb ? ClientCapabilities.web : ClientCapabilities.full,
);
