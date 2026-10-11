import 'dart:io';

/// Why a filesystem operation failed, independent of the host OS.
enum FsErrorKind {
  /// The path (or a parent) does not exist.
  notFound,

  /// The OS refused access: POSIX `EACCES`/`EPERM` (including macOS privacy
  /// protection, TCC: "Operation not permitted") or Windows
  /// `ERROR_ACCESS_DENIED`.
  permissionDenied,

  /// The filesystem is mounted read-only (POSIX `EROFS`, Windows
  /// `ERROR_WRITE_PROTECT`). For example NTFS on macOS.
  readOnlyFilesystem,

  /// The path exists but is not a directory.
  notADirectory,

  /// Anything else.
  other,
}

// POSIX errno values. They are the same on macOS and Linux for these codes.
const _enoent = 2;
const _eperm = 1;
const _eacces = 13;
const _enotdir = 20;
const _erofs = 30;

// Windows error codes.
const _winFileNotFound = 2;
const _winPathNotFound = 3;
const _winAccessDenied = 5;
const _winWriteProtect = 19;
const _winDirectory = 267; // ERROR_DIRECTORY: the directory name is invalid.

/// Classifies a [FileSystemException] (or any error) into an [FsErrorKind].
FsErrorKind classifyFsError(Object error) {
  if (error is! FileSystemException) return FsErrorKind.other;
  final os = error.osError;
  if (os == null) return FsErrorKind.other;
  final code = os.errorCode;
  if (Platform.isWindows) {
    return switch (code) {
      _winFileNotFound || _winPathNotFound => FsErrorKind.notFound,
      _winAccessDenied => FsErrorKind.permissionDenied,
      _winWriteProtect => FsErrorKind.readOnlyFilesystem,
      _winDirectory => FsErrorKind.notADirectory,
      _ => FsErrorKind.other,
    };
  }
  return switch (code) {
    _enoent => FsErrorKind.notFound,
    _eperm || _eacces => FsErrorKind.permissionDenied,
    _erofs => FsErrorKind.readOnlyFilesystem,
    _enotdir => FsErrorKind.notADirectory,
    _ => _classifyByMessage(os.message),
  };
}

FsErrorKind _classifyByMessage(String message) {
  final m = message.toLowerCase();
  if (m.contains('operation not permitted') ||
      m.contains('permission denied')) {
    return FsErrorKind.permissionDenied;
  }
  if (m.contains('read-only file system')) {
    return FsErrorKind.readOnlyFilesystem;
  }
  return FsErrorKind.other;
}

/// A filesystem failure with an OS-independent [kind].
class FsAccessException implements Exception {
  const FsAccessException(this.kind, this.path, [this.message]);

  final FsErrorKind kind;
  final String path;
  final String? message;

  @override
  String toString() =>
      'FsAccessException(${kind.name}, $path${message == null ? '' : ': $message'})';
}

/// Result of [probeWritable].
class WriteProbeResult {
  const WriteProbeResult({
    required this.writable,
    this.readOnlyFilesystem = false,
    this.permissionDenied = false,
  });

  final bool writable;
  final bool readOnlyFilesystem;
  final bool permissionDenied;
}

/// Checks whether [dirPath] (an existing directory) is writable by actually
/// creating and deleting a temp file.
///
/// The test file goes into `<dir>/.retrosteam/` when that folder exists (so a
/// managed root is never littered), otherwise into `<dir>` itself. Permission
/// bits alone are unreliable: read-only mounts, ACLs and macOS privacy
/// protection only show up when a write is attempted.
Future<WriteProbeResult> probeWritable(String dirPath) async {
  final marker = Directory('$dirPath${Platform.pathSeparator}.retrosteam');
  String target;
  try {
    target = await marker.exists() ? marker.path : dirPath;
  } on FileSystemException {
    target = dirPath;
  }
  final name =
      '.rs-write-test-${DateTime.now().microsecondsSinceEpoch}-$pid.tmp';
  final file = File('$target${Platform.pathSeparator}$name');
  try {
    await file.writeAsBytes(const [0], flush: true);
    await file.delete();
    return const WriteProbeResult(writable: true);
  } on FileSystemException catch (e) {
    // Best effort cleanup if the write succeeded but the delete failed.
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (_) {}
    final kind = classifyFsError(e);
    return WriteProbeResult(
      writable: false,
      readOnlyFilesystem: kind == FsErrorKind.readOnlyFilesystem,
      permissionDenied: kind == FsErrorKind.permissionDenied,
    );
  }
}
