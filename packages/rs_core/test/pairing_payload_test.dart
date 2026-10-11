import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

void main() {
  const payload = PairingPayload(
    serverId: 'abc',
    hosts: ['192.168.1.10', 'retro.local'],
    port: 47320,
    token: 't0k3n',
  );

  test('round-trips through a URI string', () {
    final parsed = PairingPayload.tryParse(payload.toUri().toString());
    expect(parsed, payload);
  });

  test('rejects foreign or incomplete URIs', () {
    expect(PairingPayload.tryParse('https://example.com'), isNull);
    expect(PairingPayload.tryParse('retrosteam://pair?id=abc&port=1'), isNull);
    expect(PairingPayload.tryParse('not a uri at all %%%'), isNull);
  });
}
