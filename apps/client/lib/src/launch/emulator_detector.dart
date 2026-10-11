import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../platform/client_capabilities.dart';
import 'emulator_manifest.dart';
import 'emulator_manifest_data.dart';
import 'emulator_probe.dart';

/// A libretro core that was found in a RetroArch cores directory.
@immutable
class DetectedCore {
  DetectedCore({
    required this.path,
    required this.match,
    required List<String> systems,
  }) : systems = List.unmodifiable(systems);

  /// Absolute path of the core file.
  final String path;

  /// Manifest stem this file matched, for example `snes9x_libretro`.
  final String match;

  final List<String> systems;

  @override
  bool operator ==(Object other) =>
      other is DetectedCore &&
      other.path == path &&
      other.match == match &&
      listEquals(other.systems, systems);

  @override
  int get hashCode => Object.hash(path, match, Object.hashAll(systems));

  @override
  String toString() => 'DetectedCore($match, $path, systems: $systems)';
}

/// An emulator whose executable is present on this machine.
@immutable
class DetectedEmulator {
  DetectedEmulator({
    required this.id,
    required this.name,
    required this.kind,
    required this.executable,
    required List<String> args,
    required List<String> systems,
    required List<DetectedCore> cores,
  }) : args = List.unmodifiable(args),
       systems = List.unmodifiable(systems),
       cores = List.unmodifiable(cores);

  final String id;
  final String name;
  final EmulatorKind kind;

  /// Absolute path to run. For a macOS `.app`, this is the inner executable
  /// when that file exists, otherwise the bundle path.
  final String executable;

  /// Argument template from the manifest. `{rom}` and `{core}` are not
  /// replaced here.
  final List<String> args;

  /// Standalone systems come from the manifest entry. RetroArch systems are
  /// the union of [cores].
  final List<String> systems;

  /// Empty for a standalone emulator, and for RetroArch when no core matches.
  final List<DetectedCore> cores;

  @override
  bool operator ==(Object other) =>
      other is DetectedEmulator &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.executable == executable &&
      listEquals(other.args, args) &&
      listEquals(other.systems, systems) &&
      listEquals(other.cores, cores);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    kind,
    executable,
    Object.hashAll(args),
    Object.hashAll(systems),
    Object.hashAll(cores),
  );

  @override
  String toString() =>
      'DetectedEmulator($id, $kind, $executable, systems: $systems, '
      'cores: $cores)';
}

/// Finds installed emulators described by [manifest].
class EmulatorDetector {
  const EmulatorDetector({required this.manifest, required this.probe});

  final EmulatorManifest manifest;
  final EmulatorProbe probe;

  /// Installed emulators for [platform] (`macos`, `windows`, `linux`,
  /// `android`, `ios`, or `web`). Android, iOS, and web are empty.
  List<DetectedEmulator> detect(String platform) {
    if (platform == 'android' || platform == 'ios' || platform == 'web') {
      return const [];
    }
    final found = <DetectedEmulator>[];
    for (final entry in manifest.entries) {
      final spec = entry.platforms[platform];
      if (spec == null) continue;
      final executable = _executable(spec);
      if (executable == null) continue;
      if (entry.kind == EmulatorKind.retroarch) {
        final cores = _cores(spec, entry.cores);
        found.add(
          DetectedEmulator(
            id: entry.id,
            name: entry.name,
            kind: entry.kind,
            executable: executable,
            args: spec.args,
            systems: _unionSystems(cores),
            cores: cores,
          ),
        );
        continue;
      }
      found.add(
        DetectedEmulator(
          id: entry.id,
          name: entry.name,
          kind: entry.kind,
          executable: executable,
          args: spec.args,
          systems: entry.systems,
          cores: const [],
        ),
      );
    }
    return List.unmodifiable(found);
  }

  String? _executable(EmulatorPlatform spec) {
    for (final candidate in spec.executables) {
      final onPath = candidate.findOnPath;
      final String? found;
      if (onPath != null) {
        final hit = probe.findOnPath(onPath);
        found = (hit == null || hit.isEmpty) ? null : hit;
      } else {
        final path = _expandHome(candidate.path!, probe.home);
        found = probe.exists(path) ? path : null;
      }
      if (found == null) continue;
      return _reportedExecutable(found);
    }
    return null;
  }

  String _reportedExecutable(String path) {
    final base = _basename(path);
    if (!base.endsWith('.app')) return path;
    final bundleName = base.substring(0, base.length - '.app'.length);
    if (bundleName.isEmpty) return path;
    final inner = _join(path, 'Contents/MacOS/$bundleName');
    if (probe.exists(inner)) return inner;
    return path;
  }

  List<DetectedCore> _cores(
    EmulatorPlatform spec,
    List<EmulatorCoreMatch> matches,
  ) {
    final extension = spec.coreExtension;
    if (extension == null || matches.isEmpty) return const [];
    final ranked = [...matches]
      ..sort((a, b) => b.match.length.compareTo(a.match.length));
    final cores = <DetectedCore>[];
    for (final directory in spec.coresDirectories) {
      final expanded = _expandHome(directory, probe.home);
      for (final name in probe.listFiles(expanded)) {
        if (!name.endsWith(extension)) continue;
        EmulatorCoreMatch? hit;
        for (final match in ranked) {
          if (!name.startsWith(match.match)) continue;
          hit = match;
          break;
        }
        if (hit == null) continue;
        cores.add(
          DetectedCore(
            path: _join(expanded, name),
            match: hit.match,
            systems: hit.systems,
          ),
        );
      }
    }
    return cores;
  }
}

List<String> _unionSystems(List<DetectedCore> cores) {
  final systems = <String>[];
  for (final core in cores) {
    for (final system in core.systems) {
      if (!systems.contains(system)) systems.add(system);
    }
  }
  return systems;
}

/// Replaces one leading `~` or `~/` with [home]. Later tildes are left as-is.
String _expandHome(String path, String home) {
  if (path == '~') return _trimTrailingSeparator(home);
  if (!path.startsWith('~/')) return path;
  final rest = path.substring(2);
  final trimmed = _trimTrailingSeparator(home);
  if (trimmed.isEmpty) return rest;
  final windows = trimmed.contains(r'\');
  final sep = windows ? r'\' : '/';
  final tail = windows ? rest.replaceAll('/', r'\') : rest;
  return '$trimmed$sep$tail';
}

String _join(String parent, String child) {
  final windows = parent.contains(r'\');
  final sep = windows ? r'\' : '/';
  final tail = windows ? child.replaceAll('/', r'\') : child;
  return '${_trimTrailingSeparator(parent)}$sep$tail';
}

String _trimTrailingSeparator(String path) {
  if (path.length <= 1) return path;
  if (path.endsWith('/') || path.endsWith(r'\')) {
    return path.substring(0, path.length - 1);
  }
  return path;
}

String _basename(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final end = normalized.length > 1 && normalized.endsWith('/')
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
  final slash = end.lastIndexOf('/');
  if (slash < 0) return end;
  return end.substring(slash + 1);
}

/// Built-in manifest, parsed once per container.
final emulatorManifestProvider = Provider<EmulatorManifest>(
  (ref) => EmulatorManifest.parse(emulatorManifestJson),
);

/// Filesystem probe for this process. Override in tests.
final emulatorProbeProvider = Provider<EmulatorProbe>(
  (ref) => openEmulatorProbe(),
);

/// Installed emulators on this device.
///
/// Empty when [ClientCapabilities.canLaunchGames] is false.
final detectedEmulatorsProvider = Provider<List<DetectedEmulator>>((ref) {
  final capabilities = ref.watch(clientCapabilitiesProvider);
  if (!capabilities.canLaunchGames) return const [];
  return EmulatorDetector(
    manifest: ref.watch(emulatorManifestProvider),
    probe: ref.watch(emulatorProbeProvider),
  ).detect(capabilities.platform);
});
