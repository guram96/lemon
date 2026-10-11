/// Shared domain models and API contract for the Retro Steam server and client.
///
/// This package is pure Dart and must never depend on Flutter or on either app.
library;

export 'src/api/api_error.dart';
export 'src/api/api_routes.dart';
export 'src/auth/device_join.dart';
export 'src/auth/login.dart';
export 'src/discovery/discovery.dart';
export 'src/discovery/pairing_payload.dart';
export 'src/events/server_event.dart';
export 'src/library/artwork.dart';
export 'src/library/game.dart';
export 'src/library/game_system.dart';
export 'src/library/library_queries.dart';
export 'src/library/library_root.dart';
export 'src/scan/scan_status.dart';
export 'src/server/server_info.dart';
export 'src/setup/browse.dart';
export 'src/setup/path_check.dart';
export 'src/setup/setup_request.dart';
export 'src/users/user.dart';
