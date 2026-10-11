import 'package:rs_server/src/scanner/scanner.dart';
import 'package:test/test.dart';

void main() {
  group('parseTitle', () {
    test('strips extension, tags and keeps region', () {
      final t = parseTitle('Super Mario World (USA) [!].sfc');
      expect(t.title, 'Super Mario World');
      expect(t.region, 'USA');
      expect(t.disc, isNull);
      expect(t.tags, ['USA', '!']);
    });

    test('multi-region and revision tags', () {
      final t = parseTitle('Sonic the Hedgehog (USA, Europe) (Rev 1).md');
      expect(t.title, 'Sonic the Hedgehog');
      expect(t.region, 'USA, Europe');
    });

    test('disc number', () {
      final t = parseTitle('Final Fantasy VII (USA) (Disc 2).cue');
      expect(t.title, 'Final Fantasy VII');
      expect(t.region, 'USA');
      expect(t.disc, 2);
      expect(parseTitle('Game (Disk 3 of 4).chd').disc, 3);
      expect(parseTitle('Game (CD1).chd').disc, 1);
    });

    test('GoodTools region codes', () {
      expect(parseTitle('Zelda (U) [!].nes').region, 'USA');
      expect(parseTitle('Zelda (JUE).nes').region, 'Japan, USA, Europe');
    });

    test('non-region tags are not regions', () {
      final t = parseTitle('Game (Beta) (En,Fr,De).gba');
      expect(t.region, isNull);
      expect(t.title, 'Game');
    });

    test('moves trailing article', () {
      expect(
        parseTitle('Legend of Zelda, The - A Link to the Past (USA).sfc').title,
        'The Legend of Zelda - A Link to the Past',
      );
      expect(parseTitle('Ooze, The (Europe).md').title, 'The Ooze');
    });

    test('underscores become spaces when there are no spaces', () {
      expect(parseTitle('metal_slug_x.zip').title, 'metal slug x');
    });

    test('keeps dots inside names', () {
      expect(parseTitle('Dr. Mario (World).nes').title, 'Dr. Mario');
    });

    test('falls back to the raw name when everything is a tag', () {
      expect(parseTitle('(USA).sfc').title, '(USA)');
    });

    test('directory names', () {
      final t = parseTitle('Demon\'s Souls (USA).ps3');
      expect(t.title, 'Demon\'s Souls');
      expect(t.region, 'USA');
    });
  });

  test('discGroupKey ignores only the disc tag', () {
    expect(
      discGroupKey('Game (USA) (Disc 1).cue'),
      discGroupKey('Game (USA) (Disc 2).cue'),
    );
    expect(
      discGroupKey('Game (USA) (Disc 1).cue'),
      isNot(discGroupKey('Game (Europe) (Disc 1).cue')),
    );
  });
}
