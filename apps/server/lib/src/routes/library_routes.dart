import 'dart:io';

import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../artwork/artwork_files.dart';
import '../db/game_repo.dart';
import '../db/root_repo.dart';
import '../fs/path_guard.dart';
import '../http/api_failure.dart';
import '../http/json.dart';
import '../http/middleware.dart';
import '../server_context.dart';
import '../services/mappers.dart';

/// Optional paging on `GET /library/games` (not yet in `ApiQueryParams`).
const offsetParam = 'offset';
const limitParam = 'limit';

/// Catalog, roots, scans and artwork.
void mountLibraryRoutes(Router router, ServerContext ctx) {
  final session = const Pipeline().addMiddleware(requireSession(ctx));
  final admin = const Pipeline().addMiddleware(
    requireSession(ctx, admin: true),
  );

  router.get(
    ApiRoutes.librarySystems,
    session.addHandler((request) {
      final systems =
          ctx.requireServer().games.systemCounts().map(Mappers.system).toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      return jsonOk([for (final s in systems) s.toJson()]);
    }),
  );

  router.get(
    ApiRoutes.libraryGames,
    session.addHandler((request) {
      final q = request.url.queryParameters;
      final sort = switch (q[ApiQueryParams.sort]) {
        null || '' || GameSort.title => GameOrder.title,
        GameSort.recent => GameOrder.recent,
        final other => throw ApiFailure.badRequest('Unknown sort "$other".'),
      };
      final server = ctx.requireServer();
      final result = server.games.list(
        systemId: q[ApiQueryParams.system],
        query: q[ApiQueryParams.query],
        sort: sort,
        offset: _intParam(q, offsetParam) ?? 0,
        limit: _intParam(q, limitParam),
      );
      final art = server.artwork.forGames(result.games.map((g) => g.id));
      final page = GamePage(
        games: [
          for (final g in result.games)
            Mappers.game(g, artwork: art[g.id] ?? const {}),
        ],
        total: result.total,
      );
      return jsonOk(page.toJson());
    }),
  );

  // Longer than `/library/games/<id>`, so registered first. shelf_router
  // uses the first matching route.
  router.get(
    '${ApiRoutes.libraryGames}/<id>/download/<index>',
    session.addHandler((request) => _serveGameFile(ctx, request)),
  );
  router.get(
    '${ApiRoutes.libraryGames}/<id>/download',
    session.addHandler((request) => _downloadManifest(ctx, request)),
  );

  final game = session.addHandler((request) {
    final id = request.params['id'] ?? '';
    final server = ctx.requireServer();
    final record = server.games.byId(id);
    if (record == null) throw const ApiFailure.notFound('No such game.');
    final art = server.artwork.forGames([id]);
    return jsonOk(Mappers.game(record, artwork: art[id] ?? const {}).toJson());
  });
  router.get(
    '${ApiRoutes.libraryGames}/<id>',
    (Request request, String id) => game(request),
  );

  router.get(
    ApiRoutes.libraryRoots,
    admin.addHandler((request) {
      final roots = ctx.requireServer().roots.all().map(Mappers.root);
      return jsonOk([for (final r in roots) r.toJson()]);
    }),
  );

  router.post(
    ApiRoutes.libraryScan,
    admin.addHandler((request) {
      final scans = ctx.requireServer().scans;
      if (!scans.start()) {
        throw const ApiFailure.conflict('A scan is already running.');
      }
      return jsonResponse(202, scans.status.toJson());
    }),
  );

  router.get(
    ApiRoutes.libraryScanStatus,
    session.addHandler(
      (request) => jsonOk(ctx.requireServer().scans.status.toJson()),
    ),
  );

  final artwork = session.addHandler((request) {
    final id = request.params['id'] ?? '';
    final server = ctx.requireServer();
    final record = server.artwork.byId(id);
    if (record == null) throw const ApiFailure.notFound('No such artwork.');
    final width = _widthParam(request.url.queryParameters);
    try {
      final bytes = server.artworkFiles.variant(record.relPath, width: width);
      return Response.ok(
        bytes,
        headers: {
          'content-type': server.artworkFiles.contentType(record.relPath),
          'cache-control': 'private, max-age=86400',
        },
      );
    } on ArtworkException {
      throw const ApiFailure.notFound('No such artwork.');
    }
  });
  router.get(
    '${ApiRoutes.artworkBase}/<id>',
    (Request request, String id) => artwork(request),
  );
}

/// `bytes=start-end` or `bytes=start-`. End is inclusive.
final _byteRange = RegExp(
  r'^bytes\s*=\s*(\d*)\s*-\s*(\d*)\s*$',
  caseSensitive: false,
);

class _ByteRange {
  const _ByteRange(this.start, this.end);

  final int start;
  final int end;
}

/// The game and its library root, or a 404 / 409 for the download routes.
({GameRecord game, RootRecord root}) _downloadTarget(
  ServerContext ctx,
  String id,
) {
  final server = ctx.requireServer();
  final game = server.games.byId(id);
  if (game == null) throw const ApiFailure.notFound('No such game.');
  final root = server.rootRepo.byId(game.rootId);
  if (root == null || root.status == LibraryRootStatus.offline) {
    throw const ApiFailure.conflict(
      'The library root for this game is offline.',
    );
  }
  return (game: game, root: root);
}

Future<Response> _downloadManifest(ServerContext ctx, Request request) async {
  final located = _downloadTarget(ctx, request.params['id'] ?? '');
  final dto = Mappers.game(located.game);
  final manifest = DownloadManifest(
    gameId: dto.id,
    systemId: dto.systemId,
    files: [
      for (var i = 0; i < dto.files.length; i++)
        DownloadFile(
          index: i,
          path: dto.files[i].path,
          sizeBytes: dto.files[i].sizeBytes,
          sha1: dto.files[i].sha1,
        ),
    ],
  );
  return jsonOk(manifest.toJson());
}

/// Streams catalog file `index`. The path comes from the catalog record
/// (`<systemId>/<GameFile.path>`), resolved through [PathGuard] against the
/// game's library root. The request path is never joined onto the disk.
Future<Response> _serveGameFile(ServerContext ctx, Request request) async {
  final located = _downloadTarget(ctx, request.params['id'] ?? '');
  final index = int.tryParse(request.params['index'] ?? '');
  final files = located.game.files;
  if (index == null || index < 0 || index >= files.length) {
    throw const ApiFailure.notFound('No such file.');
  }
  final absolute = await PathGuard(
    rootId: located.root.id,
    rootPath: located.root.lastPath,
  ).resolveSafe(files[index].relPath);
  final kind = await FileSystemEntity.type(absolute, followLinks: true);
  if (kind != FileSystemEntityType.file) {
    throw const ApiFailure.notFound('No such file.');
  }
  final file = File(absolute);
  final total = await file.length();
  final range = _singleByteRange(request.headers['range'], total);
  return _byteResponse(file, total, range);
}

/// `null` when the request has no Range header (serve the whole file).
_ByteRange? _singleByteRange(String? header, int total) {
  if (header == null || header.trim().isEmpty) return null;
  final value = header.trim();
  final match = _byteRange.firstMatch(value);
  if (value.contains(',') || match == null) {
    throw _unsatisfiable(total);
  }
  final startText = match.group(1)!;
  final endText = match.group(2)!;
  // `bytes=-N` is a suffix range. Only `start-end` and `start-` are accepted.
  if (startText.isEmpty) throw _unsatisfiable(total);
  final start = int.parse(startText);
  if (start >= total) throw _unsatisfiable(total);
  final int end;
  if (endText.isEmpty) {
    end = total - 1;
  } else {
    final requested = int.parse(endText);
    if (requested < start) throw _unsatisfiable(total);
    end = requested >= total ? total - 1 : requested;
  }
  return _ByteRange(start, end);
}

ApiFailure _unsatisfiable(int total) => ApiFailure(
  416,
  ApiErrorCodes.badRequest,
  'The requested byte range cannot be satisfied.',
  headers: {'accept-ranges': 'bytes', 'content-range': 'bytes */$total'},
);

Response _byteResponse(File file, int total, _ByteRange? range) {
  final headers = <String, String>{
    'content-type': 'application/octet-stream',
    'accept-ranges': 'bytes',
  };
  if (range == null) {
    headers['content-length'] = '$total';
    return Response.ok(file.openRead(), headers: headers);
  }
  final length = range.end - range.start + 1;
  headers['content-length'] = '$length';
  headers['content-range'] = 'bytes ${range.start}-${range.end}/$total';
  // Range end is inclusive; File.openRead's end is exclusive.
  return Response(
    206,
    body: file.openRead(range.start, range.end + 1),
    headers: headers,
  );
}

/// `w` is optional. A present value must be 1–2048.
int? _widthParam(Map<String, String> q) {
  final raw = q[ApiQueryParams.width];
  if (raw == null || raw.isEmpty) return null;
  final value = int.tryParse(raw);
  if (value == null || value < 1 || value > ArtworkFiles.maxServeWidth) {
    throw const ApiFailure.badRequest(
      '"${ApiQueryParams.width}" must be from 1 to ${ArtworkFiles.maxServeWidth}.',
    );
  }
  return value;
}

int? _intParam(Map<String, String> q, String name) {
  final raw = q[name];
  if (raw == null || raw.isEmpty) return null;
  final value = int.tryParse(raw);
  if (value == null || value < 0) {
    throw ApiFailure.badRequest('"$name" must be a non-negative integer.');
  }
  return value;
}
