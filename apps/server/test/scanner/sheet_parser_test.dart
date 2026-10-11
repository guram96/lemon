import 'package:rs_server/src/scanner/scanner.dart';
import 'package:test/test.dart';

void main() {
  test('parseCue reads quoted and unquoted FILE lines', () {
    const cue = '''
FILE "Game (Track 1).bin" BINARY
  TRACK 01 MODE2/2352
    INDEX 01 00:00:00
FILE Track2.bin BINARY
  TRACK 02 AUDIO
file "Game (Track 1).bin" BINARY
''';
    expect(parseCue(cue), ['Game (Track 1).bin', 'Track2.bin']);
  });

  test('parseGdi reads track names, skipping the count line', () {
    const gdi = '''
3
1 0 4 2352 track01.bin 0
2 756 0 2352 "track 02.raw" 0
3 45000 4 2352 track03.bin 0
''';
    expect(parseGdi(gdi), ['track01.bin', 'track 02.raw', 'track03.bin']);
  });

  test('parseM3u skips comments and blanks', () {
    const m3u = '#EXTM3U\n\nDisc 1.cue\r\nsub\\Disc 2.cue\n';
    expect(parseM3u(m3u), ['Disc 1.cue', r'sub\Disc 2.cue']);
  });

  test('parseSheet dispatches by extension', () {
    expect(parseSheet('.m3u', 'a.chd'), ['a.chd']);
    expect(parseSheet('.txt', 'a.chd'), isEmpty);
  });
}
