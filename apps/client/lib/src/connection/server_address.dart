import 'package:rs_core/rs_core.dart';

/// The server on this machine, probed at startup when nothing is saved.
final defaultLocalServerUri = Uri(
  scheme: 'http',
  host: '127.0.0.1',
  port: Discovery.defaultPort,
);

/// Whether [uri] points at this machine, which allows same-machine auto-join
/// (`POST /devices/local`) and first-run setup.
bool isLoopbackUri(Uri uri) {
  final host = uri.host.toLowerCase();
  return host == 'localhost' ||
      host == '::1' ||
      host == '[::1]' ||
      host.startsWith('127.');
}

/// Parses what a user typed in the manual address field: `192.168.1.10`,
/// `nas.local:47320` or `http://host:port`. Missing scheme → `http`, missing
/// port → [Discovery.defaultPort]. Returns `null` when it isn't an address.
Uri? parseServerAddress(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final withScheme = text.contains('://') ? text : 'http://$text';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  final hasPort = RegExp(r':\d+$').hasMatch(uri.authority);
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: hasPort ? uri.port : Discovery.defaultPort,
  );
}

/// `host:port` for display.
String displayAddress(Uri uri) =>
    uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
