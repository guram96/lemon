import 'dart:io';

import 'package:path/path.dart' as p;

/// Why a path was rejected by [PathGuard].
enum PathRejection {
  empty,
  nullByte,
  controlCharacter,
  absolute,
  driveLetter,
  parentTraversal,
  reservedName,
  invalidCharacter,
  trailingDotOrSpace,
  segmentTooLong,
  pathTooLong,
  symlinkEscape,
  outsideRoot,
}

class PathGuardException implements Exception {
  const PathGuardException(this.reason, this.input);

  final PathRejection reason;
  final String input;

  @override
  String toString() => 'PathGuardException(${reason.name}, "$input")';
}

/// Turns untrusted relative paths into safe absolute paths inside one root
/// (a library root or the data directory).
///
/// Relative paths are always validated against the **strictest** rules of
/// any supported OS (Windows reserved names and characters, trailing dots,
/// length limits), so a library stays portable when the drive moves between
/// machines. Both `/` and `\` are treated as separators.
///
/// ```dart
/// final guard = PathGuard(rootId: id, rootPath: '/Volumes/HDD/roms');
/// final abs = await guard.resolveSafe('snes/Super Mario World.sfc');
/// ```
class PathGuard {
  PathGuard({required this.rootId, required String rootPath})
    : rootPath = p.normalize(p.absolute(rootPath));

  final String rootId;

  /// Normalized absolute root path.
  final String rootPath;

  /// Max length of one path segment (NTFS, exFAT, APFS, ext4 all allow 255).
  static const maxSegmentLength = 255;

  /// Max length of a relative path. Leaves room under Windows' 32k long-path
  /// limit and keeps paths sane everywhere.
  static const maxRelativeLength = 4096;

  static final _reservedNames = RegExp(
    r'^(con|prn|aux|nul|com[0-9¹²³]|lpt[0-9¹²³]|conin\$|conout\$)$',
    caseSensitive: false,
  );
  static final _driveLetter = RegExp(r'^[a-zA-Z]:');
  static final _invalidChars = RegExp(r'[<>:"|?*]');
  static final _controlChars = RegExp(r'[\x01-\x1f\x7f]');

  /// Validates [relative] and returns its canonical form: `/`-separated,
  /// no `.` segments, no leading or trailing separator.
  ///
  /// Throws [PathGuardException] if the path is unsafe.
  static String normalizeRelative(String relative) {
    if (relative.isEmpty) {
      throw PathGuardException(PathRejection.empty, relative);
    }
    if (relative.contains('\u0000')) {
      throw PathGuardException(PathRejection.nullByte, relative);
    }
    if (_controlChars.hasMatch(relative)) {
      throw PathGuardException(PathRejection.controlCharacter, relative);
    }
    if (relative.startsWith('/') || relative.startsWith(r'\')) {
      throw PathGuardException(PathRejection.absolute, relative);
    }
    if (_driveLetter.hasMatch(relative)) {
      throw PathGuardException(PathRejection.driveLetter, relative);
    }
    if (relative.length > maxRelativeLength) {
      throw PathGuardException(PathRejection.pathTooLong, relative);
    }
    final segments = <String>[];
    for (final segment in relative.split(RegExp(r'[/\\]'))) {
      if (segment.isEmpty || segment == '.') continue;
      validateSegment(segment, input: relative);
      segments.add(segment);
    }
    if (segments.isEmpty) {
      throw PathGuardException(PathRejection.empty, relative);
    }
    return segments.join('/');
  }

  /// Validates a single file or folder name, for example an upload's name.
  static void validateSegment(String segment, {String? input}) {
    final source = input ?? segment;
    if (segment.isEmpty) throw PathGuardException(PathRejection.empty, source);
    if (segment == '..') {
      throw PathGuardException(PathRejection.parentTraversal, source);
    }
    if (segment.contains('/') || segment.contains(r'\')) {
      throw PathGuardException(PathRejection.invalidCharacter, source);
    }
    if (segment.contains('\u0000')) {
      throw PathGuardException(PathRejection.nullByte, source);
    }
    if (_controlChars.hasMatch(segment)) {
      throw PathGuardException(PathRejection.controlCharacter, source);
    }
    if (_invalidChars.hasMatch(segment)) {
      throw PathGuardException(PathRejection.invalidCharacter, source);
    }
    if (segment.endsWith('.') || segment.endsWith(' ')) {
      throw PathGuardException(PathRejection.trailingDotOrSpace, source);
    }
    if (segment.length > maxSegmentLength) {
      throw PathGuardException(PathRejection.segmentTooLong, source);
    }
    // Windows treats `CON.txt` and `con .tar.gz` like the device `CON`.
    final stem = segment.split('.').first.trimRight();
    if (_reservedNames.hasMatch(stem)) {
      throw PathGuardException(PathRejection.reservedName, source);
    }
  }

  /// Validates [relative] and joins it onto [rootPath], without touching
  /// the filesystem. Use [resolveSafe] before reading or writing, so symlinks
  /// that escape the root are caught too.
  String resolve(String relative) {
    final canonical = normalizeRelative(relative);
    final joined = p.normalize(p.joinAll([rootPath, ...canonical.split('/')]));
    if (!_isWithin(rootPath, joined)) {
      throw PathGuardException(PathRejection.outsideRoot, relative);
    }
    return joined;
  }

  /// Like [resolve], and also resolves symlinks: the real path of the target
  /// (or, if it doesn't exist yet, of its deepest existing ancestor) must stay
  /// inside the real root path.
  Future<String> resolveSafe(String relative) async {
    final joined = resolve(relative);
    final realRoot = await _realPath(rootPath);
    var probe = joined;
    while (true) {
      final type = await FileSystemEntity.type(probe, followLinks: false);
      if (type != FileSystemEntityType.notFound) break;
      final parent = p.dirname(probe);
      if (parent == probe) break;
      probe = parent;
    }
    final realProbe = await _realPath(probe);
    if (!_isWithin(realRoot, realProbe) && realRoot != realProbe) {
      throw PathGuardException(PathRejection.symlinkEscape, relative);
    }
    return joined;
  }

  /// Converts an absolute path inside the root to the canonical relative
  /// form stored in the database (`/`-separated). Throws if it is outside.
  String relativize(String absolute) {
    final normalized = p.normalize(p.absolute(absolute));
    if (!_isWithin(rootPath, normalized)) {
      throw PathGuardException(PathRejection.outsideRoot, absolute);
    }
    final rel = p.relative(normalized, from: rootPath);
    return normalizeRelative(p.split(rel).join('/'));
  }

  /// Validates an absolute path typed or picked by the admin (setup, settings)
  /// and returns it normalized. `~` expands to the home directory.
  ///
  /// Only syntax is checked here: absolute, no NUL or control characters.
  static String normalizeAbsolute(String input, {String? homeDir}) {
    var path = input.trim();
    if (path.isEmpty) throw PathGuardException(PathRejection.empty, input);
    if (path.contains('\u0000')) {
      throw PathGuardException(PathRejection.nullByte, input);
    }
    if (_controlChars.hasMatch(path)) {
      throw PathGuardException(PathRejection.controlCharacter, input);
    }
    final home = homeDir ?? userHomeDir();
    if (home != null && (path == '~' || path.startsWith('~/'))) {
      path = p.join(home, path.substring(path == '~' ? 1 : 2));
    }
    if (!p.isAbsolute(path)) {
      throw PathGuardException(PathRejection.outsideRoot, input);
    }
    final normalized = p.normalize(path);
    // Keep Windows drive roots as `C:\`, not `C:`.
    if (Platform.isWindows && RegExp(r'^[a-zA-Z]:$').hasMatch(normalized)) {
      return '$normalized\\';
    }
    return normalized;
  }

  static bool get _caseInsensitive => Platform.isMacOS || Platform.isWindows;

  static bool _isWithin(String parent, String child) {
    if (_caseInsensitive) {
      return p.isWithin(parent.toLowerCase(), child.toLowerCase());
    }
    return p.isWithin(parent, child);
  }

  static Future<String> _realPath(String path) async {
    try {
      return p.normalize(await Directory(path).resolveSymbolicLinks());
    } on FileSystemException {
      return p.normalize(path);
    }
  }
}

/// The current user's home directory, or `null` if unknown.
String? userHomeDir() {
  final env = Platform.environment;
  final home = Platform.isWindows ? env['USERPROFILE'] : env['HOME'];
  return home == null || home.isEmpty ? null : home;
}
