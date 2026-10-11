import 'config/bootstrap_config.dart';

/// Long-lived server state shared by request handlers.
class ServerContext {
  ServerContext({required this.config, required this.name});

  final BootstrapConfig config;

  /// Display name, defaults to the host machine name.
  final String name;
}
