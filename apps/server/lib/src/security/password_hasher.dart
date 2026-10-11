import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'tokens.dart';

/// Argon2id cost parameters.
class Argon2Params {
  const Argon2Params({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
    this.saltLength = 16,
  });

  /// OWASP's recommended minimum: m=19 MiB, t=2, p=1.
  static const recommended = Argon2Params();

  /// Very cheap, for tests only.
  static const insecureFastForTests = Argon2Params(
    memoryKiB: 64,
    iterations: 1,
  );

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int hashLength;
  final int saltLength;
}

/// Hashes and verifies passwords with Argon2id (pure Dart, pointycastle).
///
/// Hashes are PHC strings, so parameters can change later without breaking
/// existing hashes:
/// `$argon2id$v=19$m=19456,t=2,p=1$<salt b64>$<hash b64>`.
///
/// Hashing runs in a separate isolate so it never blocks the server's event
/// loop.
class PasswordHasher {
  const PasswordHasher({this.params = Argon2Params.recommended});

  final Argon2Params params;

  /// Longest accepted password, to bound hashing cost.
  static const maxPasswordLength = 1024;

  Future<String> hash(String password) {
    _checkLength(password);
    final salt = Tokens.randomBytes(params.saltLength);
    final p = params;
    return Isolate.run(() => _encode(p, salt, _derive(password, salt, p)));
  }

  /// Whether [password] matches [encoded]. Malformed hashes return `false`.
  Future<bool> verify(String password, String encoded) async {
    if (password.length > maxPasswordLength) return false;
    final parsed = _Phc.tryParse(encoded);
    if (parsed == null) return false;
    final derived = await Isolate.run(
      () => _derive(password, parsed.salt, parsed.params),
    );
    return constantTimeEquals(derived, parsed.hash);
  }

  /// Whether [encoded] was made with weaker parameters than [params] (rehash
  /// after the next successful login).
  bool needsRehash(String encoded) {
    final parsed = _Phc.tryParse(encoded);
    if (parsed == null) return true;
    return parsed.params.memoryKiB < params.memoryKiB ||
        parsed.params.iterations < params.iterations ||
        parsed.hash.length < params.hashLength;
  }

  static void _checkLength(String password) {
    if (password.length > maxPasswordLength) {
      throw ArgumentError.value('<redacted>', 'password', 'too long');
    }
  }

  static Uint8List _derive(String password, Uint8List salt, Argon2Params p) {
    final generator = Argon2BytesGenerator()
      ..init(
        Argon2Parameters(
          Argon2Parameters.ARGON2_id,
          salt,
          desiredKeyLength: p.hashLength,
          iterations: p.iterations,
          memory: p.memoryKiB,
          lanes: p.parallelism,
          version: Argon2Parameters.ARGON2_VERSION_13,
        ),
      );
    return generator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static String _encode(Argon2Params p, Uint8List salt, Uint8List hash) =>
      '\$argon2id\$v=19\$m=${p.memoryKiB},t=${p.iterations},'
      'p=${p.parallelism}\$${_b64(salt)}\$${_b64(hash)}';

  static String _b64(List<int> bytes) =>
      base64.encode(bytes).replaceAll('=', '');
}

class _Phc {
  _Phc(this.params, this.salt, this.hash);

  final Argon2Params params;
  final Uint8List salt;
  final Uint8List hash;

  static _Phc? tryParse(String encoded) {
    final parts = encoded.split(r'$');
    // ['', 'argon2id', 'v=19', 'm=..,t=..,p=..', salt, hash]
    if (parts.length != 6 || parts[0].isNotEmpty) return null;
    if (parts[1] != 'argon2id' || parts[2] != 'v=19') return null;
    final values = <String, int>{};
    for (final kv in parts[3].split(',')) {
      final i = kv.indexOf('=');
      if (i <= 0) return null;
      final v = int.tryParse(kv.substring(i + 1));
      if (v == null) return null;
      values[kv.substring(0, i)] = v;
    }
    final m = values['m'], t = values['t'], par = values['p'];
    if (m == null || t == null || par == null) return null;
    // Refuse absurd parameters from a tampered database.
    if (m < 8 || m > 4 * 1024 * 1024 || t < 1 || t > 64) return null;
    if (par < 1 || par > 64) return null;
    try {
      final salt = _decode(parts[4]);
      final hash = _decode(parts[5]);
      if (salt.length < 8 || hash.length < 16) return null;
      return _Phc(
        Argon2Params(
          memoryKiB: m,
          iterations: t,
          parallelism: par,
          hashLength: hash.length,
          saltLength: salt.length,
        ),
        salt,
        hash,
      );
    } on FormatException {
      return null;
    }
  }

  static Uint8List _decode(String s) =>
      base64.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));
}
