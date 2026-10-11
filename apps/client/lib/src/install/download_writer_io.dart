import 'dart:io';

/// Writes [bytes] to an install [path] that already sits inside [folder].
///
/// [append] adds to the file. A fresh file is replaced. Returns false when
/// [path] is outside [folder] or a symlink along it would leave [folder].
/// Parent directories are created.
Future<bool> writeDownloadFile({
  required String folder,
  required String path,
  required List<int> bytes,
  required bool append,
}) async {
  if (bytes.isEmpty) return true;
  if (await _symlinkLeaves(folder, path)) return false;
  final file = File(path);
  await file.parent.create(recursive: true);
  if (await _symlinkLeaves(folder, path)) return false;
  await file.writeAsBytes(
    bytes,
    mode: append ? FileMode.append : FileMode.write,
    flush: true,
  );
  return true;
}

Future<bool> _symlinkLeaves(String folder, String absolutePath) async {
  final sep = Platform.pathSeparator;
  final root = _stripTrailing(folder, sep);
  final full = _stripTrailing(absolutePath, sep);
  final prefix = '$root$sep';
  if (!_hasPrefix(full, prefix)) return true;

  final segments = full
      .substring(root.length)
      .split(sep)
      .where((segment) => segment.isNotEmpty);
  var current = root;
  for (final segment in segments) {
    current = '$current$sep$segment';
    final type = await FileSystemEntity.type(current, followLinks: false);
    if (type == FileSystemEntityType.notFound) return false;
    if (type != FileSystemEntityType.link) continue;
    final String resolved;
    try {
      resolved = _stripTrailing(
        await Link(current).resolveSymbolicLinks(),
        sep,
      );
    } on FileSystemException {
      return true;
    }
    if (!_hasPrefix(resolved, prefix) && _fold(resolved) != _fold(root)) {
      return true;
    }
    current = resolved;
  }
  return false;
}

bool _hasPrefix(String path, String prefix) =>
    _fold(path).startsWith(_fold(prefix));

String _fold(String value) =>
    Platform.isMacOS || Platform.isWindows ? value.toLowerCase() : value;

String _stripTrailing(String path, String sep) {
  if (path.length > 1 && path.endsWith(sep)) {
    return path.substring(0, path.length - 1);
  }
  return path;
}
