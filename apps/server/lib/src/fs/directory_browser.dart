import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'fs_errors.dart';
import 'path_guard.dart';

/// Host operating systems the server runs on.
enum HostOs {
  macos,
  windows,
  linux;

  static HostOs get current => Platform.isMacOS
      ? macos
      : Platform.isWindows
      ? windows
      : linux;
}

/// One folder in a [BrowseListing]. Mirrors the API's `BrowseEntry`.
class BrowseItem {
  const BrowseItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.readable,
  });

  final String name;

  /// Absolute, normalized.
  final String path;
  final bool isDirectory;

  /// `false` when the OS denies listing it (permissions, macOS privacy
  /// protection).
  final bool readable;

  @override
  String toString() => 'BrowseItem($name, $path, readable: $readable)';
}

/// Result of [DirectoryBrowser.browse]. Mirrors the API's `BrowseResult`.
class BrowseListing {
  const BrowseListing({
    required this.path,
    required this.parent,
    required this.entries,
    required this.shortcuts,
  });

  final String path;

  /// `null` at a filesystem root.
  final String? parent;

  /// Sub-folders, sorted case-insensitively. Hidden folders are left out.
  final List<BrowseItem> entries;

  /// Home, Desktop, Documents, Downloads and mounted volumes / drives.
  final List<BrowseItem> shortcuts;
}

/// Lists folders on the server machine for the setup and settings folder
/// pickers. Only directories are listed; nothing is ever written.
class DirectoryBrowser {
  DirectoryBrowser({
    String? homeDir,
    HostOs? os,
    this._volumeParents,
    this._driveLetters,
  }) : homeDir = homeDir ?? userHomeDir(),
       os = os ?? HostOs.current;

  final String? homeDir;
  final HostOs os;
  final List<String>? _volumeParents;
  final List<String>? _driveLetters;

  /// Folders whose children are mounted volumes on this OS.
  List<String> get volumeParents {
    final custom = _volumeParents;
    if (custom != null) return custom;
    switch (os) {
      case HostOs.macos:
        return const ['/Volumes'];
      case HostOs.linux:
        final user = Platform.environment['USER'];
        return [
          if (user != null && user.isNotEmpty) ...[
            '/media/$user',
            '/run/media/$user',
          ],
          '/media',
          '/mnt',
        ];
      case HostOs.windows:
        return const [];
    }
  }

  /// Lists the sub-folders of [path]. `null` lists the home directory.
  ///
  /// Throws [PathGuardException] for a malformed path and
  /// [FsAccessException] when the folder is missing, not a folder, or access
  /// is denied (macOS TCC denial is [FsErrorKind.permissionDenied]).
  Future<BrowseListing> browse(String? path, {bool showHidden = false}) async {
    final target = path == null || path.trim().isEmpty
        ? (homeDir ?? p.rootPrefix(Directory.current.path))
        : PathGuard.normalizeAbsolute(path, homeDir: homeDir);

    final type = await FileSystemEntity.type(target);
    if (type == FileSystemEntityType.notFound) {
      throw FsAccessException(FsErrorKind.notFound, target);
    }
    if (type != FileSystemEntityType.directory) {
      throw FsAccessException(FsErrorKind.notADirectory, target);
    }

    final dirs = <Directory>[];
    try {
      await for (final e in Directory(target).list()) {
        if (e is! Directory) continue;
        final name = p.basename(e.path);
        if (!showHidden && _isHidden(name)) continue;
        dirs.add(e);
      }
    } on FileSystemException catch (e) {
      throw FsAccessException(classifyFsError(e), target, e.message);
    }

    final entries = await Future.wait(
      dirs.map((d) => _item(p.basename(d.path), d.path)),
    );
    entries.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final parent = p.dirname(target);
    return BrowseListing(
      path: target,
      parent: parent == target ? null : parent,
      entries: entries,
      shortcuts: await shortcuts(),
    );
  }

  /// Home, Desktop, Documents, Downloads, then mounted volumes or drives.
  /// Only folders that exist are returned.
  Future<List<BrowseItem>> shortcuts() async {
    final result = <BrowseItem>[];
    final seen = <String>{};

    Future<void> add(String name, String path) async {
      final key = os == HostOs.linux ? path : path.toLowerCase();
      if (seen.contains(key)) return;
      if (!await FileSystemEntity.isDirectory(path)) return;
      seen.add(key);
      result.add(await _item(name, path));
    }

    final home = homeDir;
    if (home != null) {
      await add('Home', home);
      for (final name in const ['Desktop', 'Documents', 'Downloads']) {
        await add(name, p.join(home, name));
      }
    }

    if (os == HostOs.windows) {
      for (final drive in await _windowsDrives()) {
        await add(drive.substring(0, 2), drive);
      }
    }
    for (final parent in volumeParents) {
      for (final volume in await _listVolumes(parent)) {
        await add(p.basename(volume), volume);
      }
    }
    return result;
  }

  Future<List<String>> _windowsDrives() async {
    final letters =
        _driveLetters ??
        List.generate(26, (i) => String.fromCharCode(0x41 + i));
    final drives = <String>[];
    for (final letter in letters) {
      final root = '$letter:\\';
      if (await Directory(root).exists()) drives.add(root);
    }
    return drives;
  }

  Future<List<String>> _listVolumes(String parent) async {
    final volumes = <String>[];
    try {
      await for (final e in Directory(parent).list()) {
        if (e is! Directory) continue;
        if (_isHidden(p.basename(e.path))) continue;
        // On macOS the boot volume appears as a symlink to `/`; skip it.
        try {
          final real = await e.resolveSymbolicLinks();
          if (real == '/' || real == p.rootPrefix(real)) continue;
        } on FileSystemException {
          // Unresolvable: still list it, access is checked later.
        }
        volumes.add(e.path);
      }
    } on FileSystemException {
      // Parent missing or unreadable: no volumes there.
    }
    volumes.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return volumes;
  }

  Future<BrowseItem> _item(String name, String path) async => BrowseItem(
    name: name,
    path: p.normalize(path),
    isDirectory: true,
    readable: await _canList(path),
  );

  /// How long one readability check may take. Hung network or autofs
  /// mounts must not stall the folder picker; they are reported readable and
  /// fail later, when actually opened.
  static const readableCheckTimeout = Duration(seconds: 2);

  static Future<bool> _canList(String path) async {
    try {
      // Listing (not stat) is what macOS privacy protection blocks.
      await Directory(path)
          .list()
          .take(1)
          .drain<void>()
          .timeout(readableCheckTimeout);
      return true;
    } on FileSystemException {
      return false;
    } on TimeoutException {
      return true;
    }
  }

  static bool _isHidden(String name) =>
      name.startsWith('.') ||
      name == r'$RECYCLE.BIN' ||
      name == 'System Volume Information';
}
