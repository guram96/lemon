import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../artwork/artwork_files.dart';
import '../db/game_repo.dart';
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
