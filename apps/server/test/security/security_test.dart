import 'dart:convert';

import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:rs_server/src/security/security.dart';
import 'package:test/test.dart';

void main() {
  group('Tokens', () {
    test('32 random bytes, base64url without padding', () {
      final t = Tokens.generate();
      expect(t.length, 43);
      expect(t, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
      expect(base64Url.decode('$t=').length, 32);
      expect(Tokens.generate(), isNot(t));
      expect(Tokens.isWellFormed(t), isTrue);
      expect(Tokens.isWellFormed('short'), isFalse);
      expect(Tokens.isWellFormed('${'a' * 30}/'), isFalse);
    });

    test('hash is hex SHA-256 and deterministic', () {
      expect(
        Tokens.hash('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      final t = Tokens.generate();
      expect(Tokens.hash(t), Tokens.hash(t));
      expect(Tokens.hash(t), isNot(t));
    });

    test('constant-time equals', () {
      expect(constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
      expect(constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
      expect(constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
      expect(constantTimeEquals([], []), isTrue);
      expect(constantTimeStringEquals('héllo', 'héllo'), isTrue);
      expect(constantTimeStringEquals('a', 'b'), isFalse);
    });
  });

  group('PasswordHasher', () {
    const fast = PasswordHasher(params: Argon2Params.insecureFastForTests);

    test('the Argon2id implementation matches RFC 9106 §5.3', () {
      final g = Argon2BytesGenerator()
        ..init(
          Argon2Parameters(
            Argon2Parameters.ARGON2_id,
            Uint8List.fromList(List.filled(16, 2)),
            secret: Uint8List.fromList(List.filled(8, 3)),
            additional: Uint8List.fromList(List.filled(12, 4)),
            desiredKeyLength: 32,
            iterations: 3,
            memory: 32,
            lanes: 4,
            version: Argon2Parameters.ARGON2_VERSION_13,
          ),
        );
      final tag = g.process(Uint8List.fromList(List.filled(32, 1)));
      expect(
        tag.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        '0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659',
      );
    });

    test('hash and verify', () async {
      final h = await fast.hash('correct horse');
      expect(h, startsWith(r'$argon2id$v=19$m=64,t=1,p=1$'));
      expect(await fast.verify('correct horse', h), isTrue);
      expect(await fast.verify('wrong horse', h), isFalse);
      expect(await fast.verify('', h), isFalse);
    });

    test('salted: same password gives different hashes', () async {
      final a = await fast.hash('pw12345678');
      final b = await fast.hash('pw12345678');
      expect(a, isNot(b));
      expect(await fast.verify('pw12345678', a), isTrue);
      expect(await fast.verify('pw12345678', b), isTrue);
    });

    test('unicode passwords', () async {
      final h = await fast.hash('пароль🔑');
      expect(await fast.verify('пароль🔑', h), isTrue);
      expect(await fast.verify('пароль', h), isFalse);
    });

    test('malformed or tampered hashes never verify', () async {
      final h = await fast.hash('pw');
      for (final bad in [
        '',
        'plain',
        r'$argon2i$v=19$m=64,t=1,p=1$c2FsdHNhbHQ$aGFzaGhhc2hoYXNoaGFzaA',
        r'$argon2id$v=16$m=64,t=1,p=1$c2FsdHNhbHQ$aGFzaGhhc2hoYXNoaGFzaA',
        r'$argon2id$v=19$m=999999999,t=1,p=1$c2FsdHNhbHQ$aGFzaGhhc2hoYXNoaGFzaA',
        r'$argon2id$v=19$m=64,t=1$c2FsdHNhbHQ$aGFzaGhhc2hoYXNoaGFzaA',
        r'$argon2id$v=19$m=64,t=1,p=1$!!!$aGFzaGhhc2hoYXNoaGFzaA',
        h.replaceRange(h.length - 4, h.length, 'AAAA'),
      ]) {
        expect(await fast.verify('pw', bad), isFalse, reason: bad);
      }
    });

    test('needsRehash when parameters are weaker', () async {
      final h = await fast.hash('pw');
      expect(const PasswordHasher().needsRehash(h), isTrue);
      expect(fast.needsRehash(h), isFalse);
      expect(fast.needsRehash('garbage'), isTrue);
    });

    test('rejects absurdly long passwords', () async {
      expect(() => fast.hash('x' * 2000), throwsArgumentError);
      expect(await fast.verify('x' * 2000, await fast.hash('x')), isFalse);
    });

    test('recommended params work and match the RFC 9106 shape', () async {
      const hasher = PasswordHasher();
      final sw = Stopwatch()..start();
      final h = await hasher.hash('admin password');
      expect(h, startsWith(r'$argon2id$v=19$m=19456,t=2,p=1$'));
      expect(await hasher.verify('admin password', h), isTrue);
      // Sanity bound so a regression to absurd cost is noticed.
      expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
    });
  });

  group('LoginRateLimiter', () {
    late DateTime now;
    late LoginRateLimiter limiter;
    setUp(() {
      now = DateTime.utc(2026, 1, 1);
      limiter = LoginRateLimiter(clock: () => now);
    });

    test('locks a username after 5 failures, case-insensitively', () {
      for (var i = 0; i < 4; i++) {
        expect(limiter.check('Admin').allowed, isTrue);
        limiter.recordFailure('admin');
      }
      expect(limiter.check('admin').allowed, isTrue);
      limiter.recordFailure('ADMIN');
      final gate = limiter.check(' admin ');
      expect(gate.allowed, isFalse);
      expect(gate.retryAfter, const Duration(minutes: 5));
      expect(limiter.check('someoneelse').allowed, isTrue);
    });

    test('lockout expires, then escalates', () {
      for (var i = 0; i < 5; i++) {
        limiter.recordFailure('u');
      }
      now = now.add(const Duration(minutes: 5, seconds: 1));
      expect(limiter.check('u').allowed, isTrue);
      for (var i = 0; i < 5; i++) {
        limiter.recordFailure('u');
      }
      final gate = limiter.check('u');
      expect(gate.allowed, isFalse);
      expect(gate.retryAfter, const Duration(minutes: 10));
    });

    test('failures outside the window are forgotten', () {
      for (var i = 0; i < 4; i++) {
        limiter.recordFailure('u');
      }
      now = now.add(const Duration(minutes: 16));
      limiter.recordFailure('u');
      expect(limiter.check('u').allowed, isTrue);
    });

    test('success clears the username counter', () {
      for (var i = 0; i < 4; i++) {
        limiter.recordFailure('u');
      }
      limiter.recordSuccess('u');
      limiter.recordFailure('u');
      expect(limiter.check('u').allowed, isTrue);
    });

    test('limits one address spraying many usernames', () {
      for (var i = 0; i < 20; i++) {
        limiter.recordFailure('user$i', address: '10.0.0.5');
      }
      expect(limiter.check('fresh', address: '10.0.0.5').allowed, isFalse);
      expect(limiter.check('fresh', address: '10.0.0.6').allowed, isTrue);
    });

    test('lockout is capped at maxLockout', () {
      for (var i = 0; i < 5 * 12; i++) {
        limiter.recordFailure('u');
      }
      expect(limiter.check('u').retryAfter, const Duration(hours: 1));
    });
  });
}
