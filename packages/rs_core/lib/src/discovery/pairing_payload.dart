import 'package:meta/meta.dart';

/// Contents of the pairing QR code a device scans to join a server.
///
/// Encoded as a URI so it is also usable as a deep link:
/// `retrosteam://pair?id=<serverId>&host=<h1>&host=<h2>&port=<port>&token=<token>`
@immutable
class PairingPayload {
  const PairingPayload({
    required this.serverId,
    required this.hosts,
    required this.port,
    required this.token,
  });

  static const scheme = 'retrosteam';
  static const _path = 'pair';

  final String serverId;

  /// Addresses the server is reachable on (IPs and/or DNS names), best first.
  final List<String> hosts;
  final int port;

  /// One-time pairing token.
  final String token;

  Uri toUri() => Uri(
    scheme: scheme,
    host: _path,
    queryParameters: {
      'id': serverId,
      'host': hosts,
      'port': '$port',
      'token': token,
    },
  );

  /// Parses a scanned QR string. Returns `null` if it is not a valid payload.
  static PairingPayload? tryParse(String input) {
    final uri = Uri.tryParse(input);
    if (uri == null || uri.scheme != scheme || uri.host != _path) return null;
    final params = uri.queryParametersAll;
    final id = params['id']?.firstOrNull;
    final hosts = params['host'] ?? const [];
    final port = int.tryParse(params['port']?.firstOrNull ?? '');
    final token = params['token']?.firstOrNull;
    if (id == null || hosts.isEmpty || port == null || token == null) {
      return null;
    }
    return PairingPayload(
      serverId: id,
      hosts: List.unmodifiable(hosts),
      port: port,
      token: token,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PairingPayload &&
      other.serverId == serverId &&
      _listEquals(other.hosts, hosts) &&
      other.port == port &&
      other.token == token;

  @override
  int get hashCode => Object.hash(serverId, Object.hashAll(hosts), port, token);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
