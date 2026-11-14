// Dev tool: draws original placeholder artwork (cover, capsule, hero) for
// every game in a data directory, so the client can be previewed without
// scraping. Art is procedural: a gradient sky, one of several scene motifs
// and a title band, seeded by the game title.
//
//   dart run tool/seed_demo_artwork.dart <dataDir>
//
// Safe to run while the server is up (SQLite WAL). Restart the client to
// pick the new artwork up.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:rs_core/rs_core.dart';
import 'package:rs_server/src/artwork/artwork_files.dart';
import 'package:rs_server/src/artwork/artwork_repo.dart';
import 'package:rs_server/src/db/database.dart';
import 'package:rs_server/src/storage/data_dir.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/seed_demo_artwork.dart <dataDir>');
    return;
  }
  final dir = args.single;
  final db = RsDatabase.open(p.join(dir, DataDir.dbFileName));
  final repo = ArtworkRepo(
    db,
    ArtworkFiles(
      artworkDir: p.join(dir, DataDir.artworkDirName),
      cacheDir: p.join(dir, DataDir.cacheDirName),
    ),
  );
  final games = db.db.select('SELECT id, title, system_id FROM games');
  for (final row in games) {
    final id = row['id'] as String;
    final title = row['title'] as String;
    final system = (row['system_id'] as String).toUpperCase();
    final art = _Art(title, system);
    for (final (kind, w, h, withTitle) in [
      (ArtworkKind.cover, 600, 900, true),
      (ArtworkKind.capsule, 920, 430, true),
      (ArtworkKind.hero, 1920, 620, false),
    ]) {
      repo.putScraped(
        gameId: id,
        kind: kind,
        source: ArtworkSource.upload,
        bytes: art.render(w, h, withTitle: withTitle),
      );
    }
    stdout.writeln('art: $title');
  }
  db.close();
}

class _Art {
  _Art(this.title, this.system) : seed = _hash(title);

  final String title;
  final String system;
  final int seed;

  static int _hash(String s) {
    var h = 0x811C9DC5;
    for (final c in s.codeUnits) {
      h = ((h ^ c) * 0x01000193) & 0x7FFFFFFF;
    }
    return h;
  }

  img.ColorRgb8 _hsl(double h, double s, double l) {
    final c = (1 - (2 * l - 1).abs()) * s;
    final hp = (h % 360) / 60;
    final x = c * (1 - (hp % 2 - 1).abs());
    final (r, g, b) = switch (hp.floor()) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    final m = l - c / 2;
    int v(double t) => ((t + m) * 255).round().clamp(0, 255);
    return img.ColorRgb8(v(r), v(g), v(b));
  }

  Uint8List render(int w, int h, {required bool withTitle}) {
    final rnd = math.Random(seed);
    final hue = (seed % 360).toDouble();
    final hue2 = hue + 40 + rnd.nextInt(80);
    final im = img.Image(width: w, height: h);

    // Sky gradient.
    for (var y = 0; y < h; y++) {
      final t = y / h;
      final c = _lerp(_hsl(hue2, 0.7, 0.12), _hsl(hue, 0.85, 0.5), t);
      img.drawLine(im, x1: 0, y1: y, x2: w - 1, y2: y, color: c);
    }

    final u = math.min(w, h).toDouble();
    final horizon = (h * (0.55 + rnd.nextDouble() * 0.1)).round();
    switch (seed % 5) {
      case 0: // Synth sun over a perspective grid.
        _sun(im, w ~/ 2, horizon, (u * 0.32).round(), hue);
        _grid(im, horizon, _hsl(hue + 180, 0.9, 0.6));
      case 1: // Layered mountains.
        for (var layer = 0; layer < 4; layer++) {
          _ridge(
            im,
            rnd,
            horizon - (3 - layer) * (h * 0.06).round(),
            _hsl(hue2, 0.5, 0.08 + layer * 0.07),
          );
        }
        img.fillCircle(
          im,
          x: (w * 0.72).round(),
          y: (h * 0.22).round(),
          radius: (u * 0.09).round(),
          color: _hsl(hue + 30, 0.9, 0.85),
        );
      case 2: // Planet in a starfield.
        _stars(im, rnd, 160);
        final r = (u * 0.3).round();
        final cx = (w * (0.35 + rnd.nextDouble() * 0.3)).round();
        final cy = (h * 0.42).round();
        for (var i = r; i > 0; i -= 2) {
          img.fillCircle(
            im,
            x: cx - (r - i) ~/ 3,
            y: cy - (r - i) ~/ 3,
            radius: i,
            color: _hsl(hue + 160, 0.7, 0.2 + 0.5 * (1 - i / r)),
          );
        }
        img.drawCircle(
          im,
          x: cx,
          y: cy,
          radius: (r * 1.45).round(),
          color: _hsl(hue + 200, 0.9, 0.75),
        );
      case 3: // City skyline at dusk.
        _stars(im, rnd, 60);
        var x = 0;
        while (x < w) {
          final bw = (u * (0.06 + rnd.nextDouble() * 0.1)).round();
          final bh = (h * (0.15 + rnd.nextDouble() * 0.4)).round();
          final top = horizon + (h * 0.15).round() - bh;
          img.fillRect(
            im,
            x1: x,
            y1: top,
            x2: x + bw,
            y2: h,
            color: _hsl(hue2, 0.4, 0.07),
          );
          for (var wy = top + 8; wy < h - 8; wy += 14) {
            for (var wx = x + 5; wx < x + bw - 5; wx += 10) {
              if (rnd.nextDouble() < 0.35) {
                img.fillRect(
                  im,
                  x1: wx,
                  y1: wy,
                  x2: wx + 4,
                  y2: wy + 6,
                  color: _hsl(hue + 30, 0.9, 0.7),
                );
              }
            }
          }
          x += bw + 3;
        }
      default: // Speed stripes.
        for (var i = 0; i < 9; i++) {
          final y0 = (h * (0.15 + i * 0.09)).round();
          final thick = (u * (0.02 + rnd.nextDouble() * 0.05)).round();
          img.fillPolygon(
            im,
            vertices: [
              img.Point(0, y0 + w ~/ 3),
              img.Point(w, y0),
              img.Point(w, y0 + thick),
              img.Point(0, y0 + w ~/ 3 + thick),
            ],
            color: _hsl(hue + i * 18, 0.95, 0.45 + (i % 3) * 0.12),
          );
        }
    }

    if (withTitle) _titleBand(im, hue);
    return img.encodeJpg(im, quality: 88);
  }

  void _sun(img.Image im, int cx, int cy, int r, double hue) {
    for (var y = cy - r; y < cy; y++) {
      final dy = cy - y;
      // Cut the classic horizontal slits into the lower half.
      if (dy < r * 0.5 && (dy ~/ math.max(3, r ~/ 14)).isOdd) continue;
      final half = math.sqrt(math.max(0, r * r - dy * dy)).round();
      final t = dy / r;
      img.drawLine(
        im,
        x1: cx - half,
        y1: y,
        x2: cx + half,
        y2: y,
        color: _lerp(_hsl(hue + 330, 0.95, 0.55), _hsl(hue + 50, 1, 0.7), t),
      );
    }
  }

  void _grid(img.Image im, int horizon, img.Color line) {
    final w = im.width;
    final h = im.height;
    img.fillRect(
      im,
      x1: 0,
      y1: horizon,
      x2: w,
      y2: h,
      color: img.ColorRgb8(8, 4, 20),
    );
    for (var i = 1; i < 14; i++) {
      final y = horizon + ((h - horizon) * math.pow(i / 13, 2)).round();
      img.drawLine(im, x1: 0, y1: y, x2: w, y2: y, color: line);
    }
    for (var i = -12; i <= 12; i++) {
      img.drawLine(
        im,
        x1: w ~/ 2 + i * w ~/ 40,
        y1: horizon,
        x2: w ~/ 2 + i * w ~/ 6,
        y2: h,
        color: line,
      );
    }
  }

  void _ridge(img.Image im, math.Random rnd, int base, img.Color color) {
    final w = im.width;
    final pts = <img.Point>[img.Point(0, im.height)];
    var y = base.toDouble();
    for (var x = 0; x <= w; x += w ~/ 12) {
      y = (base + (rnd.nextDouble() - 0.5) * im.height * 0.18).clamp(
        im.height * 0.25,
        im.height * 0.95,
      );
      pts.add(img.Point(x, y.round()));
    }
    pts.add(img.Point(w, im.height));
    img.fillPolygon(im, vertices: pts, color: color);
  }

  void _stars(img.Image im, math.Random rnd, int n) {
    for (var i = 0; i < n; i++) {
      final b = 150 + rnd.nextInt(105);
      img.fillCircle(
        im,
        x: rnd.nextInt(im.width),
        y: rnd.nextInt(im.height),
        radius: rnd.nextDouble() < 0.1 ? 2 : 1,
        color: img.ColorRgb8(b, b, b),
      );
    }
  }

  void _titleBand(img.Image im, double hue) {
    final w = im.width;
    final h = im.height;
    final bandH = (h * 0.22).round();
    final top = h - bandH;
    for (var y = top; y < h; y++) {
      final t = (y - top) / bandH;
      img.drawLine(
        im,
        x1: 0,
        y1: y,
        x2: w,
        y2: y,
        color: img.ColorRgba8(0, 0, 0, (t * 200 + 40).round()),
      );
    }
    img.fillRect(
      im,
      x1: 0,
      y1: top,
      x2: w,
      y2: top + 4,
      color: _hsl(hue, 0.9, 0.6),
    );
    final font = img.arial48;
    final lines = _wrap(title.toUpperCase(), font, w - 48);
    var y = top + 18;
    for (final line in lines.take(2)) {
      img.drawString(
        im,
        line,
        font: font,
        x: 26,
        y: y + 3,
        color: img.ColorRgb8(0, 0, 0),
      );
      img.drawString(
        im,
        line,
        font: font,
        x: 24,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
      y += font.lineHeight;
    }
    img.drawString(
      im,
      system,
      font: img.arial24,
      x: 24,
      y: 18,
      color: _hsl(hue + 60, 0.9, 0.85),
    );
  }

  List<String> _wrap(String text, img.BitmapFont font, int maxWidth) {
    int width(String s) => s.codeUnits.fold(
      0,
      (sum, c) => sum + (font.characters[c]?.xAdvance ?? font.base ~/ 2),
    );
    final out = <String>[];
    var line = '';
    for (final word in text.split(' ')) {
      final next = line.isEmpty ? word : '$line $word';
      if (width(next) > maxWidth && line.isNotEmpty) {
        out.add(line);
        line = word;
      } else {
        line = next;
      }
    }
    if (line.isNotEmpty) out.add(line);
    return out;
  }

  img.ColorRgb8 _lerp(img.ColorRgb8 a, img.ColorRgb8 b, double t) =>
      img.ColorRgb8(
        (a.r + (b.r - a.r) * t).round(),
        (a.g + (b.g - a.g) * t).round(),
        (a.b + (b.b - a.b) * t).round(),
      );
}
