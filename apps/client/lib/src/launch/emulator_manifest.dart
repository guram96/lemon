import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rs_core/rs_core.dart';

/// How an installed emulator is launched.
enum EmulatorKind {
  /// RetroArch plus the libretro cores found on disk.
  retroarch,

  /// One program that plays the systems listed on its manifest entry.
  standalone;

  static EmulatorKind _parse(String value) => switch (value) {
    'retroarch' => EmulatorKind.retroarch,
    'standalone' => EmulatorKind.standalone,
    _ => throw FormatException(
      'emulator manifest kind "$value" is not retroarch or standalone',
    ),
  };
}

/// One executable candidate from the manifest.
@immutable
class EmulatorCandidate {
  const EmulatorCandidate.path(this.path) : findOnPath = null;

  const EmulatorCandidate.onPath(this.findOnPath) : path = null;

  /// Filesystem path. A leading `~` is the probe home.
  final String? path;

  /// Program name resolved with the probe's `findOnPath`.
  final String? findOnPath;

  static EmulatorCandidate _parse(Map<String, Object?> json, String field) {
    final path = json['path'];
    final onPath = json['findOnPath'];
    if (path is String && path.isNotEmpty && onPath == null) {
      return EmulatorCandidate.path(path);
    }
    if (onPath is String && onPath.isNotEmpty && path == null) {
      return EmulatorCandidate.onPath(onPath);
    }
    throw FormatException(
      'emulator manifest $field must set path or findOnPath',
    );
  }
}

/// One libretro core stem and the systems it plays.
@immutable
class EmulatorCoreMatch {
  const EmulatorCoreMatch({required this.match, required this.systems});

  /// Filename prefix, for example `snes9x_libretro`.
  final String match;

  final List<String> systems;

  static EmulatorCoreMatch _parse(Map<String, Object?> json, String field) {
    final match = json['match'];
    if (match is! String || match.isEmpty) {
      throw FormatException('emulator manifest $field.match is empty');
    }
    final systems = _systemList(json['systems'], '$field.systems');
    if (systems.isEmpty) {
      throw FormatException('emulator manifest $field.systems is empty');
    }
    return EmulatorCoreMatch(match: match, systems: systems);
  }
}

/// Detection data for one operating system (`macos`, `windows`, `linux`).
@immutable
class EmulatorPlatform {
  const EmulatorPlatform({
    required this.executables,
    required this.args,
    required this.coresDirectories,
    required this.coreExtension,
  });

  /// Tried in order. The first one that exists is the executable.
  final List<EmulatorCandidate> executables;

  /// Argument template. Tokens such as `{rom}` are replaced at launch.
  final List<String> args;

  /// Directories whose file names are matched against [EmulatorEntry.cores].
  final List<String> coresDirectories;

  /// Core filename suffix, including the dot (`.dylib`, `.dll`, `.so`).
  final String? coreExtension;
}

/// One emulator in the manifest.
@immutable
class EmulatorEntry {
  const EmulatorEntry({
    required this.id,
    required this.name,
    required this.kind,
    required this.systems,
    required this.platforms,
    required this.cores,
  });

  final String id;
  final String name;
  final EmulatorKind kind;

  /// Systems a standalone entry plays. Empty for RetroArch.
  final List<String> systems;

  /// Keyed by `macos`, `windows`, or `linux`.
  final Map<String, EmulatorPlatform> platforms;

  /// RetroArch core stems. Empty for a standalone entry.
  final List<EmulatorCoreMatch> cores;

  static EmulatorEntry _parse(Map<String, Object?> json) {
    final id = _nonEmptyString(json['id'], 'id');
    final name = _nonEmptyString(json['name'], '$id.name');
    final kind = EmulatorKind._parse(_nonEmptyString(json['kind'], '$id.kind'));
    final systems = json['systems'] == null
        ? const <String>[]
        : _systemList(json['systems'], '$id.systems');
    if (kind == EmulatorKind.standalone && systems.isEmpty) {
      throw FormatException('emulator manifest $id.systems is empty');
    }
    final cores = json['cores'] == null
        ? const <EmulatorCoreMatch>[]
        : [
            for (final item in _asList(json['cores'], '$id.cores'))
              EmulatorCoreMatch._parse(_asMap(item, '$id.cores'), '$id.cores'),
          ];
    final rawPlatforms = json['platforms'];
    if (rawPlatforms == null) {
      throw FormatException('emulator manifest $id is missing platforms');
    }
    final platforms = <String, EmulatorPlatform>{};
    for (final entry in _asMap(rawPlatforms, '$id.platforms').entries) {
      platforms[entry.key] = _parsePlatform(
        _asMap(entry.value, '$id.platforms.${entry.key}'),
        '$id.platforms.${entry.key}',
        retroarch: kind == EmulatorKind.retroarch,
      );
    }
    return EmulatorEntry(
      id: id,
      name: name,
      kind: kind,
      systems: systems,
      platforms: Map.unmodifiable(platforms),
      cores: List.unmodifiable(cores),
    );
  }
}

/// Parsed emulator manifest. Paths and templates are data, not code.
@immutable
class EmulatorManifest {
  EmulatorManifest._(List<EmulatorEntry> entries)
    : entries = List.unmodifiable(entries);

  final List<EmulatorEntry> entries;

  /// Parses [source]. Unknown system ids and malformed entries throw
  /// [FormatException].
  factory EmulatorManifest.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('emulator manifest is not a JSON object');
    }
    final json = Map<String, Object?>.from(decoded);
    final rawEntries = json['emulators'];
    if (rawEntries == null) {
      throw const FormatException('emulator manifest is missing emulators');
    }
    final entries = <EmulatorEntry>[];
    final seen = <String>{};
    for (final item in _asList(rawEntries, 'emulators')) {
      final entry = EmulatorEntry._parse(_asMap(item, 'emulators'));
      if (!seen.add(entry.id)) {
        throw FormatException(
          'emulator manifest id "${entry.id}" is duplicated',
        );
      }
      entries.add(entry);
    }
    return EmulatorManifest._(entries);
  }
}

EmulatorPlatform _parsePlatform(
  Map<String, Object?> json,
  String field, {
  required bool retroarch,
}) {
  final rawExecutables = json['executables'];
  if (rawExecutables == null) {
    throw FormatException('emulator manifest $field is missing executables');
  }
  final executables = [
    for (final item in _asList(rawExecutables, '$field.executables'))
      EmulatorCandidate._parse(_asMap(item, '$field.executables'), field),
  ];
  if (executables.isEmpty) {
    throw FormatException('emulator manifest $field.executables is empty');
  }
  final args = _stringList(json['args'], '$field.args');
  if (args.isEmpty) {
    throw FormatException('emulator manifest $field.args is empty');
  }
  final coresDirectories = json['coresDirectories'] == null
      ? const <String>[]
      : _stringList(json['coresDirectories'], '$field.coresDirectories');
  final rawExtension = json['coreExtension'];
  if (rawExtension != null && rawExtension is! String) {
    throw FormatException(
      'emulator manifest $field.coreExtension is not a string',
    );
  }
  final coreExtension = rawExtension as String?;
  if (retroarch) {
    if (coreExtension == null || !coreExtension.startsWith('.')) {
      throw FormatException(
        'emulator manifest $field.coreExtension must start with a dot',
      );
    }
    if (json['coresDirectories'] == null) {
      throw FormatException(
        'emulator manifest $field is missing coresDirectories',
      );
    }
  }
  return EmulatorPlatform(
    executables: List.unmodifiable(executables),
    args: args,
    coresDirectories: coresDirectories,
    coreExtension: coreExtension,
  );
}

String _nonEmptyString(Object? value, String field) {
  if (value is! String || value.isEmpty) {
    throw FormatException('emulator manifest $field is not a non-empty string');
  }
  return value;
}

List<String> _stringList(Object? value, String field) {
  final strings = <String>[];
  for (final item in _asList(value, field)) {
    if (item is! String || item.isEmpty) {
      throw FormatException(
        'emulator manifest $field has an empty or non-string item',
      );
    }
    strings.add(item);
  }
  return List.unmodifiable(strings);
}

List<String> _systemList(Object? value, String field) {
  final systems = <String>[];
  for (final id in _stringList(value, field)) {
    final system = GameSystems.byId(id);
    if (system == null) {
      throw FormatException(
        'emulator manifest $field has unknown system "$id"',
      );
    }
    systems.add(system.id);
  }
  return List.unmodifiable(systems);
}

Map<String, Object?> _asMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('emulator manifest $field is not an object');
  }
  return Map<String, Object?>.from(value);
}

List<Object?> _asList(Object? value, String field) {
  if (value is! List) {
    throw FormatException('emulator manifest $field is not a list');
  }
  return List<Object?>.from(value);
}
