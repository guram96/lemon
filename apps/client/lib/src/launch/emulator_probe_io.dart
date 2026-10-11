import 'dart:io';

import 'emulator_probe.dart';

/// Probe backed by [dart:io] and the process environment. No shell.
EmulatorProbe openEmulatorProbe() => IoEmulatorProbe();

class IoEmulatorProbe implements EmulatorProbe {
  IoEmulatorProbe() : home = _readHome();

  @override
  final String home;

  @override
  bool exists(String path) {
    if (path.isEmpty) return false;
    try {
      return FileSystemEntity.typeSync(path, followLinks: true) !=
          FileSystemEntityType.notFound;
    } on FileSystemException {
      return false;
    }
  }

  @override
  List<String> listFiles(String directory) {
    if (directory.isEmpty) return const [];
    final dir = Directory(directory);
    try {
      if (!dir.existsSync()) return const [];
      final names = <String>[];
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! File) continue;
        final name = _basename(entity.path);
        if (name.isEmpty) continue;
        names.add(name);
      }
      return names;
    } on FileSystemException {
      return const [];
    }
  }

  @override
  String? findOnPath(String name) {
    if (name.isEmpty || name.contains('/') || name.contains(r'\')) {
      return null;
    }
    final pathEnv = Platform.environment['PATH'];
    if (pathEnv == null || pathEnv.isEmpty) return null;
    final separator = Platform.isWindows ? ';' : ':';
    final withExe = Platform.isWindows && !name.contains('.');
    for (final directory in pathEnv.split(separator)) {
      if (directory.isEmpty) continue;
      final candidate = _join(directory, name);
      if (_isFile(candidate)) return candidate;
      if (withExe && _isFile('$candidate.exe')) return '$candidate.exe';
    }
    return null;
  }
}

String _readHome() {
  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'];
    if (profile != null && profile.isNotEmpty) return profile;
    final drive = Platform.environment['HOMEDRIVE'] ?? '';
    final path = Platform.environment['HOMEPATH'] ?? '';
    if (drive.isNotEmpty && path.isNotEmpty) return '$drive$path';
    return '';
  }
  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) return home;
  return '';
}

bool _isFile(String path) {
  try {
    return File(path).existsSync();
  } on FileSystemException {
    return false;
  }
}

String _join(String parent, String child) {
  final sep = Platform.pathSeparator;
  final trimmed =
      parent.length > 1 && (parent.endsWith('/') || parent.endsWith(r'\'))
      ? parent.substring(0, parent.length - 1)
      : parent;
  return '$trimmed$sep$child';
}

String _basename(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  if (slash < 0) return normalized;
  return normalized.substring(slash + 1);
}
