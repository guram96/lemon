import 'dart:io';

import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';

import '../db/auth_repos.dart' show ConflictException;
import '../db/database.dart' show DatabaseException;
import '../fs/fs_errors.dart';
import '../fs/path_guard.dart';
import '../storage/data_dir.dart' show StorageException;
import 'json.dart';

/// An error that maps directly to an HTTP [status] and an [ApiError] body.
///
/// Throw it from any handler or middleware; the error middleware turns it
/// into a JSON response.
class ApiFailure implements Exception {
  const ApiFailure(this.status, this.code, this.message, {this.headers});

  const ApiFailure.badRequest(String message)
    : this(400, ApiErrorCodes.badRequest, message);

  const ApiFailure.payloadTooLarge()
    : this(413, ApiErrorCodes.badRequest, 'The request body is too large.');

  const ApiFailure.unauthorized(String message)
    : this(401, ApiErrorCodes.unauthorized, message);

  const ApiFailure.forbidden(String message)
    : this(403, ApiErrorCodes.forbidden, message);

  const ApiFailure.notFound(String message)
    : this(404, ApiErrorCodes.notFound, message);

  const ApiFailure.conflict(String message)
    : this(409, ApiErrorCodes.conflict, message);

  const ApiFailure.pathInvalid(String message)
    : this(400, ApiErrorCodes.pathInvalid, message);

  /// The server has not been set up yet (409).
  const ApiFailure.setupRequired()
    : this(
        409,
        ApiErrorCodes.setupRequired,
        'The server is not set up yet. Finish setup on the server machine.',
      );

  const ApiFailure.alreadyConfigured()
    : this(
        409,
        ApiErrorCodes.alreadyConfigured,
        'The server is already set up.',
      );

  const ApiFailure.loopbackOnly()
    : this(
        403,
        ApiErrorCodes.loopbackOnly,
        'Only allowed from the server machine itself.',
      );

  final int status;
  final String code;
  final String message;
  final Map<String, String>? headers;

  Response toResponse() => jsonError(status, code, message, headers: headers);

  @override
  String toString() => 'ApiFailure($status $code: $message)';
}

/// Maps known exceptions from the filesystem, storage and database layers to
/// an [ApiFailure]. Returns `null` for anything unexpected (→ 500).
ApiFailure? apiFailureFor(Object error) => switch (error) {
  ApiFailure() => error,
  PathGuardException(:final reason) => ApiFailure.pathInvalid(
    'Invalid path (${reason.name}).',
  ),
  FsAccessException(:final kind, :final path) => switch (kind) {
    FsErrorKind.permissionDenied => ApiFailure.forbidden(
      'The operating system denied access to "$path". Grant the Retro Steam '
      'server access to this folder.',
    ),
    FsErrorKind.notFound => ApiFailure.pathInvalid(
      'The folder "$path" does not exist.',
    ),
    FsErrorKind.notADirectory => ApiFailure.pathInvalid(
      '"$path" is not a folder.',
    ),
    FsErrorKind.readOnlyFilesystem => ApiFailure.pathInvalid(
      '"$path" is on a read-only drive.',
    ),
    FsErrorKind.other => ApiFailure.pathInvalid('Cannot access "$path".'),
  },
  FileSystemException() =>
    classifyFsError(error) == FsErrorKind.permissionDenied
        ? ApiFailure.forbidden(
            'The operating system denied access to "${error.path}".',
          )
        : ApiFailure.pathInvalid(
            'Cannot use "${error.path}": ${error.osError?.message ?? error.message}.',
          ),
  StorageException(:final message) => ApiFailure.pathInvalid(message),
  ConflictException(:final message) => ApiFailure.conflict(message),
  DatabaseException(:final message) => ApiFailure.conflict(message),
  _ => null,
};
