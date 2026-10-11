import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Random bearer tokens (device tokens, session tokens, pairing tokens).
///
/// Tokens are 32 random bytes from a CSPRNG, base64url-encoded without
/// padding (43 characters). The server stores only [hash]: a leaked database
/// does not leak usable tokens.
abstract final class Tokens {
  static final Random _random = Random.secure();

  /// Number of random bytes in a token.
  static const byteLength = 32;

  /// A new random token.
  static String generate([int bytes = byteLength]) =>
      base64Url.encode(randomBytes(bytes)).replaceAll('=', '');

  /// [length] bytes from a cryptographically secure RNG.
  static Uint8List randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  /// SHA-256 of [token], lowercase hex. This is what the database stores and
  /// what lookups use.
  static String hash(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  /// Whether [token] looks like one of ours (cheap pre-check before a DB hit).
  static bool isWellFormed(String token) =>
      token.length >= 22 &&
      token.length <= 128 &&
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(token);
}

/// Compares two byte lists in time independent of where they differ.
bool constantTimeEquals(List<int> a, List<int> b) {
  var diff = a.length ^ b.length;
  final n = min(a.length, b.length);
  for (var i = 0; i < n; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Constant-time comparison of two strings (UTF-8 bytes).
bool constantTimeStringEquals(String a, String b) =>
    constantTimeEquals(utf8.encode(a), utf8.encode(b));
