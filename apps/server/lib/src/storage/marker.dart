import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// What a marked directory is.
enum MarkerKind { data, library }

/// The identity file of a data directory or library root:
/// `<dir>/.retrosteam/root.json`.
///
/// When a drive moves to another machine or mount point, the server finds the
/// directory again by [id] instead of by its absolute path.
class RootMarker {
  const RootMarker({
    required this.id,
    required this.kind,
    required this.label,
    required this.createdAt,
  });

  factory RootMarker.fromJson(Map<String, Object?> json) => RootMarker(
    id: json['id']! as String,
    kind: MarkerKind.values.byName(json['kind']! as String),
    label: (json['label'] as String?) ?? '',
    createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
  );

  final String id;
  final MarkerKind kind;
  final String label;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'label': label,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is RootMarker &&
      other.id == id &&
      other.kind == kind &&
      other.label == label &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, kind, label, createdAt);

  @override
  String toString() => 'RootMarker($id, ${kind.name}, "$label")';
}

/// Reads and writes [RootMarker] files.
abstract final class MarkerStore {
  /// Name of the hidden per-directory folder Retro Steam owns.
  static const dirName = '.retrosteam';
  static const fileName = 'root.json';

  static String markerDir(String dirPath) => p.join(dirPath, dirName);

  static String markerPath(String dirPath) =>
      p.join(dirPath, dirName, fileName);

  /// The marker of [dirPath], or `null` if there is none or it is unreadable
  /// or corrupt. Never throws.
  static Future<RootMarker?> read(String dirPath) async {
    final file = File(markerPath(dirPath));
    try {
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, Object?>) return null;
      return RootMarker.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Writes [marker] into [dirPath] atomically (write temp file, then rename).
  ///
  /// Throws [FileSystemException] when the directory is not writable, for
  /// example on a read-only mount.
  static Future<void> write(String dirPath, RootMarker marker) async {
    final dir = Directory(markerDir(dirPath));
    await dir.create(recursive: true);
    final target = File(markerPath(dirPath));
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(marker.toJson()),
      flush: true,
    );
    await tmp.rename(target.path);
  }
}
