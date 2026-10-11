import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

import '../support/fakes.dart';

/// [RsApiClient] whose setup routes answer from memory.
class SetupApi extends FakeApiClient {
  SetupApi() : super(info: serverInfo(state: ServerSetupState.unconfigured));

  static const home = '/Users/test';

  PathCheckResult Function(String path, PathKind kind)? script;
  SetupRequest? lastSetup;
  Object? setupError;
  int setupCalls = 0;

  @override
  Future<BrowseResult> browse(String? path) async {
    final listed = path ?? home;
    final atHome = path == null || path == home;
    return BrowseResult(
      path: listed,
      parent: atHome ? null : home,
      shortcuts: const [
        BrowseEntry(
          name: 'Home',
          path: home,
          isDirectory: true,
          readable: true,
        ),
      ],
      entries: atHome
          ? const [
              BrowseEntry(
                name: 'roms',
                path: '$home/roms',
                isDirectory: true,
                readable: true,
              ),
            ]
          : const [],
    );
  }

  @override
  Future<PathCheckResult> checkPath(String path, PathKind kind) async {
    if (script case final script?) return script(path, kind);
    final normalized = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    if (kind == PathKind.dataDir) {
      return PathCheckResult(
        path: normalized,
        kind: kind,
        exists: false,
        readable: true,
        writable: true,
        freeBytes: 50 * 1000 * 1000 * 1000,
      );
    }
    return PathCheckResult(
      path: normalized,
      kind: kind,
      exists: true,
      readable: true,
      writable: true,
      detectedSystems: const [
        DetectedSystem(systemId: 'snes', fileCount: 12),
        DetectedSystem(systemId: 'nes', fileCount: 4),
      ],
    );
  }

  @override
  Future<AuthResult> setup(SetupRequest request) async {
    setupCalls++;
    lastSetup = request;
    if (setupError case final error?) throw error;
    return const AuthResult(
      sessionToken: 'session',
      user: adminUser,
      deviceId: 'device',
      deviceToken: 'device-token',
    );
  }
}
