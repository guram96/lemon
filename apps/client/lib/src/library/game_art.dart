import 'package:flutter/widgets.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

/// Artwork of [game] as an image, trying [kinds] in order. `null` when the
/// game has none of them: components then draw generated art.
///
/// Sends the device and session tokens as headers (web builds can't, so
/// `GET /artwork` may move to signed URLs in M2).
ImageProvider? gameArtwork(
  RsApiClient api,
  Game game,
  List<ArtworkKind> kinds, {
  int? width,
}) {
  for (final kind in kinds) {
    final art = game.artwork[kind];
    if (art == null) continue;
    return NetworkImage(
      api.artworkUri(art.id, width: width).toString(),
      headers: {
        ApiHeaders.device: ?api.deviceToken,
        if (api.sessionToken case final token?)
          ApiHeaders.authorization: '${ApiHeaders.bearerPrefix}$token',
      },
    );
  }
  return null;
}

/// Artwork kinds to try for each place a game is drawn.
abstract final class ArtKinds {
  static const cover = [ArtworkKind.cover];
  static const wide = [ArtworkKind.capsule, ArtworkKind.hero];
  static const background = [ArtworkKind.hero, ArtworkKind.screenshot];
  static const logo = [ArtworkKind.logo];
}
