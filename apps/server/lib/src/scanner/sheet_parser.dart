/// Parsers for disc sheet / playlist files: `.cue`, `.gdi`, `.m3u`.
///
/// Each returns the referenced file names exactly as written (possibly with
/// `\` separators); resolution against the filesystem happens in grouping.
library;

import 'dart:convert';

/// Extensions whose content lists other files of the same game unit.
const sheetExtensions = {'.cue', '.gdi', '.m3u'};

/// Decodes sheet bytes leniently (UTF-8 with malformed fallback, BOM removed).
String decodeSheet(List<int> bytes) {
  var text = utf8.decode(bytes, allowMalformed: true);
  if (text.startsWith('﻿')) text = text.substring(1);
  return text;
}

/// Parses a sheet by extension (`.cue`, `.gdi`, `.m3u`, lowercase).
List<String> parseSheet(String extension, String content) =>
    switch (extension) {
      '.cue' => parseCue(content),
      '.gdi' => parseGdi(content),
      '.m3u' => parseM3u(content),
      _ => const [],
    };

final _cueFile = RegExp(
  r'^\s*FILE\s+(?:"([^"]+)"|(\S+))(?:\s+\S+)?\s*$',
  caseSensitive: false,
);

/// `FILE "Track 01.bin" BINARY` lines of a cue sheet.
List<String> parseCue(String content) {
  final out = <String>[];
  for (final line in const LineSplitter().convert(content)) {
    final m = _cueFile.firstMatch(line);
    if (m == null) continue;
    final name = (m.group(1) ?? m.group(2) ?? '').trim();
    if (name.isNotEmpty && !out.contains(name)) out.add(name);
  }
  return out;
}

final _gdiTrack = RegExp(
  r'^\s*\d+\s+\d+\s+\d+\s+\d+\s+(?:"([^"]+)"|(\S+))\s+-?\d+\s*$',
);

/// Track lines of a `.gdi`: `1 0 4 2352 "track01.bin" 0`.
List<String> parseGdi(String content) {
  final out = <String>[];
  final lines = const LineSplitter().convert(content);
  for (final line in lines.skip(1)) {
    final m = _gdiTrack.firstMatch(line);
    if (m == null) continue;
    final name = (m.group(1) ?? m.group(2) ?? '').trim();
    if (name.isNotEmpty && !out.contains(name)) out.add(name);
  }
  return out;
}

/// Non-empty, non-comment lines of an `.m3u` playlist.
List<String> parseM3u(String content) {
  final out = <String>[];
  for (final raw in const LineSplitter().convert(content)) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (!out.contains(line)) out.add(line);
  }
  return out;
}
