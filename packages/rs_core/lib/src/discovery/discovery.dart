/// Constants for finding a server on the local network.
abstract final class Discovery {
  /// mDNS / Bonjour service type advertised by the server.
  static const serviceType = '_retrosteam._tcp';

  /// Default HTTP port of the server.
  static const defaultPort = 47320;
}
