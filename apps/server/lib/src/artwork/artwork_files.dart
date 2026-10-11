import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Why an image was rejected or could not be read.
class ArtworkException implements Exception {
  const ArtworkException(this.message);

  final String message;

  @override
  String toString() => 'ArtworkException: $message';
}

/// A processed image written under the data directory.
class StoredImage {
  const StoredImage({
    required this.relPath,
    required this.width,
    required this.height,
    required this.hasAlpha,
  });

  /// File name inside the artwork directory, never a path.
  final String relPath;
  final int width;
  final int height;
  final bool hasAlpha;
}

/// Decodes, bounds-checks, and stores artwork. Callers never serve the
/// original download: only the re-encoded file and its resized cache.
class ArtworkFiles {
  ArtworkFiles({required this.artworkDir, required this.cacheDir});

  /// Processed originals (`{id}.png` or `{id}.jpg`).
  final String artworkDir;

  /// Resized copies (`{id}/w{width}.png` or `.jpg`).
  final String cacheDir;

  static const maxBytes = 25 * 1024 * 1024;
  static const maxEdge = 8192;
  static const maxPixels = 16 * 1000 * 1000;

  /// Largest `?w=` the server will render.
  static const maxServeWidth = 2048;

  /// Decodes [bytes] and writes `{id}.png` when the image has alpha, otherwise
  /// `{id}.jpg`.
  StoredImage save(String id, Uint8List bytes) {
    _checkId(id);
    if (bytes.length > maxBytes) {
      throw const ArtworkException('Image is larger than 25 MB.');
    }
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const ArtworkException('Not a supported image.');
    }
    if (decoded.width > maxEdge ||
        decoded.height > maxEdge ||
        decoded.width * decoded.height > maxPixels) {
      throw const ArtworkException('Image is too large.');
    }
    final alpha = decoded.numChannels == 4;
    final relPath = alpha ? '$id.png' : '$id.jpg';
    final encoded = alpha
        ? img.encodePng(decoded)
        : img.encodeJpg(decoded, quality: 90);
    Directory(artworkDir).createSync(recursive: true);
    File(p.join(artworkDir, relPath)).writeAsBytesSync(encoded);
    return StoredImage(
      relPath: relPath,
      width: decoded.width,
      height: decoded.height,
      hasAlpha: alpha,
    );
  }

  /// Original bytes, or a cached resize when [width] is smaller.
  Uint8List variant(String relPath, {int? width}) {
    final file = _original(relPath);
    if (width == null) return file.readAsBytesSync();
    if (width < 1 || width > maxServeWidth) {
      throw const ArtworkException('Width is out of range.');
    }
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) {
      throw const ArtworkException('Stored image is unreadable.');
    }
    if (width >= decoded.width) return file.readAsBytesSync();

    final alpha = decoded.numChannels == 4;
    final ext = alpha ? 'png' : 'jpg';
    final cacheName = 'w$width.$ext';
    final dir = Directory(
      p.join(cacheDir, p.basenameWithoutExtension(relPath)),
    );
    final cached = File(p.join(dir.path, cacheName));
    if (cached.existsSync()) return cached.readAsBytesSync();

    final resized = img.copyResize(decoded, width: width);
    final encoded = alpha
        ? img.encodePng(resized)
        : img.encodeJpg(resized, quality: 85);
    dir.createSync(recursive: true);
    cached.writeAsBytesSync(encoded);
    return Uint8List.fromList(encoded);
  }

  /// `image/png` or `image/jpeg` for [relPath].
  String contentType(String relPath) =>
      relPath.endsWith('.png') ? 'image/png' : 'image/jpeg';

  /// Removes a stored original. Missing files are ignored.
  void delete(String relPath) {
    if (!_safeName.hasMatch(relPath)) return;
    final file = File(p.join(artworkDir, relPath));
    if (file.existsSync()) file.deleteSync();
  }

  File _original(String relPath) {
    if (!_safeName.hasMatch(relPath)) {
      throw const ArtworkException('Artwork path is not a stored file.');
    }
    final file = File(p.join(artworkDir, relPath));
    if (!file.existsSync()) {
      throw const ArtworkException('Artwork file is missing.');
    }
    final String resolved;
    final String root;
    try {
      resolved = file.resolveSymbolicLinksSync();
      root = Directory(artworkDir).resolveSymbolicLinksSync();
    } on FileSystemException {
      throw const ArtworkException('Artwork file is missing.');
    }
    if (p.dirname(resolved) != root) {
      throw const ArtworkException('Artwork path escapes its directory.');
    }
    return file;
  }

  static final _safeName = RegExp(r'^[A-Za-z0-9_-]+\.(png|jpg)$');
  static final _safeId = RegExp(r'^[A-Za-z0-9_-]{1,80}$');

  static void _checkId(String id) {
    if (!_safeId.hasMatch(id)) {
      throw const ArtworkException('Artwork id is not safe to store.');
    }
  }
}
