import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';

import '../connection/connection_provider.dart';
import '../session/session_provider.dart';
import 'events_provider.dart';

/// Current or last library scan. [ScanStatus.idle] while logged out.
///
/// Seeded from `GET /library/scan` (again after every event reconnect), then
/// kept up to date by `scanProgress` events.
final scanStatusProvider = NotifierProvider<ScanStatusNotifier, ScanStatus>(
  ScanStatusNotifier.new,
);

class ScanStatusNotifier extends Notifier<ScanStatus> {
  int _generation = 0;

  @override
  ScanStatus build() {
    final generation = ++_generation;
    final ready = ref.watch(
      connectionProvider.select((c) => c.status == ConnectionStatus.ready),
    );
    final userId = ref.watch(sessionProvider.select((u) => u?.id));
    if (!ready || userId == null) return ScanStatus.idle;

    var eventSeen = 0;
    final events = ref.watch(eventsProvider).listen((event) {
      if (event is ScanProgressEvent) {
        eventSeen++;
        state = event.status;
      }
    });
    final reconnects = ref
        .watch(eventsConnectedProvider)
        .listen((_) => _refresh(generation, () => eventSeen));
    ref.onDispose(() {
      events.cancel();
      reconnects.cancel();
    });

    scheduleMicrotask(() => _refresh(generation, () => eventSeen));
    return ScanStatus.idle;
  }

  /// Fetches the status; an event that arrived meanwhile wins.
  Future<void> _refresh(int generation, int Function() eventsSeen) async {
    final before = eventsSeen();
    try {
      final status = await ref.read(apiClientProvider).scanStatus();
      if (generation != _generation || !ref.mounted) return;
      if (eventsSeen() != before) return;
      state = status;
    } on Object catch (e) {
      if (generation == _generation && ref.mounted) {
        ref.read(sessionProvider.notifier).handleApiError(e);
      }
    }
  }
}
