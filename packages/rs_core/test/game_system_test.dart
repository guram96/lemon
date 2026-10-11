import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

void main() {
  test('system IDs are unique', () {
    final ids = GameSystems.all.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('lookup is case-insensitive', () {
    expect(GameSystems.byId('SNES')?.id, 'snes');
    expect(GameSystems.byId('unknown'), isNull);
  });

  test('matches extensions case-insensitively', () {
    final snes = GameSystems.byId('snes')!;
    expect(snes.acceptsFile('Chrono Trigger (USA).SFC'), isTrue);
    expect(snes.acceptsFile('readme.txt'), isFalse);
    expect(snes.acceptsFile('noextension'), isFalse);
  });
}
