import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/connection/server_address.dart';
import 'package:rs_client/src/events/library_revision_provider.dart';
import 'package:rs_client/src/events/scan_status_provider.dart';
import 'package:rs_client/src/notifications/notification_center.dart';
import 'package:rs_client/src/storage/credential_store.dart';
import 'package:rs_core/rs_core.dart';

import 'support/fakes.dart';

void main() {
  late FakeApiClient api;
  late ProviderContainer container;

  setUp(() async {
    api = FakeApiClient(info: serverInfo());
    container = makeContainer(
      api,
      InMemoryCredentialStore(
        StoredCredentials(
          serverUri: defaultLocalServerUri,
          serverId: 'server-1',
          deviceToken: 'dev',
          sessionToken: 'sess',
          user: adminUser,
        ),
      ),
    );
    addTearDown(container.dispose);
    await connect(container);
  });

  ScanStatus running(int processed, {String system = 'snes'}) => ScanStatus(
    phase: ScanPhase.hashing,
    processed: processed,
    total: 10,
    currentSystemId: system,
  );

  Future<void> emit(ServerEvent event) async {
    api.eventsController.add(event);
    await settle();
  }

  test('scanStatusProvider is seeded from GET /library/scan', () async {
    api.scan = running(4);
    container.listen(scanStatusProvider, (_, _) {});
    await settle();
    expect(container.read(scanStatusProvider), running(4));
    expect(api.scanCalls, greaterThanOrEqualTo(1));

    await emit(ServerEvent.scanProgress(status: running(6)));
    expect(container.read(scanStatusProvider), running(6));
  });

  test('libraryRevisionProvider coalesces libraryChanged events', () async {
    container.listen(libraryRevisionProvider, (_, _) {});
    await settle();
    expect(container.read(libraryRevisionProvider), 0);

    for (var i = 0; i < 3; i++) {
      await emit(ServerEvent.libraryChanged(addedIds: ['g$i']));
    }
    expect(container.read(libraryRevisionProvider), 0);
    await Future<void>.delayed(
      LibraryRevisionNotifier.window + const Duration(milliseconds: 50),
    );
    expect(container.read(libraryRevisionProvider), 1);

    await emit(const ServerEvent.libraryChanged(addedIds: ['g0']));
    await Future<void>.delayed(
      LibraryRevisionNotifier.window + const Duration(milliseconds: 50),
    );
    expect(container.read(libraryRevisionProvider), 2);
  });

  group('notification center', () {
    setUp(() async {
      container.listen(notificationCenterProvider, (_, _) {});
      container.read(notificationCenterProvider.notifier).toastHold =
          const Duration(milliseconds: 80);
      await settle();
    });

    List<AppNotification> toasts() =>
        container.read(notificationCenterProvider).toasts;

    test('scan progress → one updating toast → summary → gone', () async {
      await emit(
        const ServerEvent.scanProgress(
          status: ScanStatus(phase: ScanPhase.discovering),
        ),
      );
      expect(toasts(), hasLength(1));
      expect(toasts().single.indeterminate, isTrue);
      expect(toasts().single.persistent, isTrue);

      await emit(ServerEvent.scanProgress(status: running(3)));
      await emit(ServerEvent.scanProgress(status: running(5, system: 'psx')));
      expect(toasts(), hasLength(1));
      final progress = toasts().single;
      expect(progress.id, NotificationCenter.scanToastId);
      expect(progress.progress, 0.5);
      expect(progress.body, '5 / 10 files · PlayStation');

      await emit(
        const ServerEvent.scanProgress(
          status: ScanStatus(
            phase: ScanPhase.done,
            processed: 10,
            total: 10,
            added: 7,
          ),
        ),
      );
      expect(toasts(), hasLength(1));
      final summary = toasts().single;
      expect(summary.id, NotificationCenter.scanToastId);
      expect(summary.persistent, isFalse);
      expect(summary.title, 'Library updated');
      expect(summary.body, '7 games added');
      expect(container.read(notificationCenterProvider).unreadCount, 1);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(toasts(), isEmpty);
      expect(container.read(notificationCenterProvider).history, [summary]);

      container.read(notificationCenterProvider.notifier).markAllRead();
      expect(container.read(notificationCenterProvider).unreadCount, 0);
    });

    test('failed scan → error toast', () async {
      await emit(ServerEvent.scanProgress(status: running(1)));
      await emit(
        const ServerEvent.scanProgress(
          status: ScanStatus(phase: ScanPhase.failed, error: 'Disk gone'),
        ),
      );
      expect(toasts().single.title, 'Library scan failed');
      expect(toasts().single.body, 'Disk gone');
    });

    test('an old finished scan at startup shows nothing', () async {
      await emit(
        const ServerEvent.scanProgress(
          status: ScanStatus(phase: ScanPhase.done, added: 3),
        ),
      );
      expect(toasts(), isEmpty);
    });
  });
}
