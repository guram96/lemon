import 'dart:convert';

import 'package:rs_core/rs_core.dart';
import 'package:test/test.dart';

final _game = Game(
  id: 'g1',
  systemId: 'psx',
  title: 'Final Fantasy VII',
  rootId: 'r1',
  addedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
  files: const [
    GameFile(path: 'ff7/disc1.chd', sizeBytes: 100),
    GameFile(path: 'ff7/disc2.chd', sizeBytes: 50, sha1: 'abc'),
  ],
  artwork: const {
    ArtworkKind.cover: Artwork(
      id: 'a1',
      kind: ArtworkKind.cover,
      source: ArtworkSource.steamGridDb,
    ),
  },
  developer: 'Square',
  releaseYear: 1997,
);

const _user = User(id: 'u1', username: 'admin', role: UserRole.admin);

final _scanStatus = ScanStatus(
  phase: ScanPhase.hashing,
  processed: 3,
  total: 10,
  currentSystemId: 'snes',
  currentFile: 'snes/mario.sfc',
  added: 1,
  updated: 2,
  removed: 0,
  startedAt: DateTime.utc(2026, 5, 1, 12),
);

void main() {
  test('Game round-trips through JSON', () {
    expect(Game.fromJson(_deepJson(_game.toJson())), _game);
    expect(_game.sizeBytes, 150);
  });

  test('ServerInfo round-trips through JSON', () {
    const info = ServerInfo(
      serverId: 's1',
      name: 'Desk',
      version: '0.1.0',
      apiVersion: ApiRoutes.version,
      setupState: ServerSetupState.unconfigured,
      platform: 'macos',
    );
    final json = _deepJson(info.toJson());
    expect(json['platform'], 'macos');
    expect(ServerInfo.fromJson(json), info);
  });

  group('setup DTOs round-trip', () {
    test('BrowseRequest', () {
      _roundTrip(const BrowseRequest(), BrowseRequest.fromJson);
      _roundTrip(
        const BrowseRequest(path: '/Users/me'),
        BrowseRequest.fromJson,
      );
    });

    test('BrowseResult', () {
      _roundTrip(
        const BrowseResult(
          path: '/Users/me',
          parent: '/Users',
          entries: [
            BrowseEntry(
              name: 'roms',
              path: '/Users/me/roms',
              isDirectory: true,
              readable: true,
            ),
          ],
          shortcuts: [
            BrowseEntry(
              name: 'Home',
              path: '/Users/me',
              isDirectory: true,
              readable: false,
            ),
          ],
        ),
        BrowseResult.fromJson,
      );
    });

    test('PathCheckRequest', () {
      _roundTrip(
        const PathCheckRequest(path: '/data', kind: PathKind.dataDir),
        PathCheckRequest.fromJson,
      );
    });

    test('PathCheckResult', () {
      _roundTrip(
        const PathCheckResult(
          path: '/Volumes/HDD/roms',
          kind: PathKind.libraryRoot,
          exists: true,
          readable: true,
          writable: false,
          existingMarkerId: 'root-uuid',
          detectedSystems: [DetectedSystem(systemId: 'snes', fileCount: 12)],
          freeBytes: 1 << 40,
          warnings: ['read-only filesystem'],
        ),
        PathCheckResult.fromJson,
      );
    });

    test('SetupRequest', () {
      _roundTrip(
        const SetupRequest(
          adminUsername: 'admin',
          adminPassword: 'password123',
          dataDir: '/data',
          libraryRoots: ['/roms', '/Volumes/HDD/roms'],
          deviceName: 'Desk',
        ),
        SetupRequest.fromJson,
      );
    });
  });

  group('PathCheckResult.ok', () {
    PathCheckResult result(
      PathKind kind, {
      bool exists = true,
      bool readable = true,
      bool writable = true,
      bool denied = false,
    }) => PathCheckResult(
      path: '/p',
      kind: kind,
      exists: exists,
      readable: readable,
      writable: writable,
      permissionDenied: denied,
    );

    test('data dir needs writable', () {
      expect(result(PathKind.dataDir).ok, isTrue);
      expect(result(PathKind.dataDir, exists: false).ok, isTrue);
      expect(result(PathKind.dataDir, writable: false).ok, isFalse);
      expect(result(PathKind.dataDir, denied: true).ok, isFalse);
    });

    test('library root needs existing and readable', () {
      expect(result(PathKind.libraryRoot, writable: false).ok, isTrue);
      expect(result(PathKind.libraryRoot, exists: false).ok, isFalse);
      expect(result(PathKind.libraryRoot, readable: false).ok, isFalse);
    });
  });

  group('auth DTOs round-trip', () {
    test('DeviceJoinRequest / DeviceJoinResult', () {
      _roundTrip(
        const DeviceJoinRequest(deviceName: 'Desk', platform: 'macos'),
        DeviceJoinRequest.fromJson,
      );
      _roundTrip(
        const DeviceJoinResult(deviceId: 'd1', deviceToken: 't'),
        DeviceJoinResult.fromJson,
      );
    });

    test('LoginRequest', () {
      _roundTrip(
        const LoginRequest(username: 'admin', password: 'pw'),
        LoginRequest.fromJson,
      );
    });

    test('AuthResult', () {
      _roundTrip(
        const AuthResult(sessionToken: 's', user: _user),
        AuthResult.fromJson,
      );
      _roundTrip(
        const AuthResult(
          sessionToken: 's',
          user: _user,
          deviceId: 'd1',
          deviceToken: 'dt',
        ),
        AuthResult.fromJson,
      );
    });
  });

  group('library DTOs round-trip', () {
    test('SystemSummary', () {
      _roundTrip(
        const SystemSummary(systemId: 'snes', name: 'SNES', gameCount: 3),
        SystemSummary.fromJson,
      );
    });

    test('GamePage', () {
      _roundTrip(GamePage(games: [_game], total: 41), GamePage.fromJson);
    });

    test('LibraryRoot', () {
      _roundTrip(
        const LibraryRoot(
          id: 'r1',
          label: 'HDD',
          status: LibraryRootStatus.readOnly,
        ),
        LibraryRoot.fromJson,
      );
    });
  });

  group('ScanStatus', () {
    test('round-trips', () {
      _roundTrip(_scanStatus, ScanStatus.fromJson);
      _roundTrip(
        ScanStatus(
          phase: ScanPhase.failed,
          finishedAt: DateTime.utc(2026),
          error: 'disk gone',
        ),
        ScanStatus.fromJson,
      );
      _roundTrip(ScanStatus.idle, ScanStatus.fromJson);
    });

    test('isRunning', () {
      expect(_scanStatus.isRunning, isTrue);
      expect(ScanStatus.idle.isRunning, isFalse);
    });
  });

  group('ServerEvent', () {
    test('scanProgress uses type scan_progress', () {
      final event = ServerEvent.scanProgress(status: _scanStatus);
      final json = _deepJson(event.toJson());
      expect(json['type'], 'scan_progress');
      expect(ServerEvent.fromJson(json), event);
      expect(ServerEvent.fromJson(json), isA<ScanProgressEvent>());
    });

    test('libraryChanged uses type library_changed', () {
      const event = ServerEvent.libraryChanged(
        addedIds: ['a'],
        updatedIds: ['b', 'c'],
        removedIds: ['d'],
      );
      final json = _deepJson(event.toJson());
      expect(json['type'], 'library_changed');
      expect(ServerEvent.fromJson(json), event);
    });

    test('rootStatusChanged uses type root_status_changed', () {
      const event = ServerEvent.rootStatusChanged(
        root: LibraryRoot(
          id: 'r1',
          label: 'HDD',
          status: LibraryRootStatus.offline,
        ),
      );
      final json = _deepJson(event.toJson());
      expect(json['type'], 'root_status_changed');
      expect(ServerEvent.fromJson(json), event);
    });
  });

  test('ApiRoutes helpers', () {
    expect(ApiRoutes.libraryGame('g1'), '/api/v1/library/games/g1');
    expect(ApiRoutes.artwork('a 1'), '/api/v1/artwork/a%201');
    expect(ApiRoutes.libraryScanStatus, ApiRoutes.libraryScan);
  });
}

void _roundTrip<T extends Object>(
  T value,
  T Function(Map<String, Object?> json) fromJson,
) {
  final toJson = (value as dynamic).toJson as Map<String, Object?> Function();
  expect(fromJson(_deepJson(toJson())), value);
}

/// Encodes to a JSON string and back, exactly as the HTTP layer does.
Map<String, Object?> _deepJson(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;
