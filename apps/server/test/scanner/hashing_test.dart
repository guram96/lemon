import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:rs_server/src/scanner/scanner.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('rs_hash_');
  });
  tearDown(() => tmp.delete(recursive: true));

  test('Crc32 matches the check value', () {
    final crc = Crc32()..add(Uint8List.fromList(ascii.encode('123456789')));
    expect(crc.hex, 'cbf43926');
  });

  test('hashFileSync computes all three hashes in one pass', () async {
    final f = File(p.join(tmp.path, 'abc.bin'))..writeAsStringSync('abc');
    final h = hashFileSync(f.path);
    expect(h.crc32, '352441c2');
    expect(h.md5, '900150983cd24fb0d6963f7d28e17f72');
    expect(h.sha1, 'a9993e364706816aba3e25717850c26c9cd0d89d');
    expect(h.size, 3);
    expect(h.partial, isFalse);
  });

  test('hashes multi-buffer files correctly', () async {
    final bytes = Uint8List.fromList(
      List.generate(3 * 1024 * 1024 + 17, (i) => (i * 31) & 0xFF),
    );
    final f = File(p.join(tmp.path, 'big.bin'))..writeAsBytesSync(bytes);
    final h = hashFileSync(f.path);
    expect(h.md5, md5.convert(bytes).toString());
    expect(h.sha1, sha1.convert(bytes).toString());
  });

  test('large files get a partial hash of head + tail + size', () async {
    final bytes = Uint8List.fromList(List.generate(4096, (i) => i & 0xFF));
    final f = File(p.join(tmp.path, 'large.iso'))..writeAsBytesSync(bytes);
    final h = hashFileSync(f.path, partialThreshold: 1024, partialChunk: 256);
    expect(h.partial, isTrue);
    final sizeLe = ByteData(8)..setUint64(0, 4096, Endian.little);
    final expected = <int>[
      ...bytes.sublist(0, 256),
      ...bytes.sublist(4096 - 256),
      ...sizeLe.buffer.asUint8List(),
    ];
    expect(h.md5, md5.convert(expected).toString());
    expect(h.sha1, sha1.convert(expected).toString());
    final crc = Crc32()..add(Uint8List.fromList(expected));
    expect(h.crc32, crc.hex);
  });

  test('HashPool hashes in isolates and reports failures', () async {
    final pool = await HashPool.spawn(2);
    addTearDown(pool.kill);
    final files = [
      for (var i = 0; i < 5; i++)
        File(p.join(tmp.path, 'f$i.bin'))..writeAsStringSync('file $i'),
    ];
    final results = await Future.wait(files.map((f) => pool.hash(f.path)));
    for (var i = 0; i < 5; i++) {
      expect(results[i].md5, md5.convert(utf8.encode('file $i')).toString());
    }
    await expectLater(
      pool.hash(p.join(tmp.path, 'missing.bin')),
      throwsA(isA<HashFailure>()),
    );
  });

  test('killing the pool fails pending jobs', () async {
    final pool = await HashPool.spawn(1);
    final f = File(p.join(tmp.path, 'x.bin'))..writeAsStringSync('x');
    final futures = [for (var i = 0; i < 3; i++) pool.hash(f.path)];
    pool.kill();
    for (final fut in futures) {
      await expectLater(fut, throwsA(isA<HashPoolClosed>()));
    }
    await expectLater(pool.hash(f.path), throwsA(isA<HashPoolClosed>()));
  });
}
