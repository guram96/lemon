import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';

import '../connection/connection_provider.dart';
import '../session/session_provider.dart';

/// One live `/events` subscription, open while a user is logged in on a
/// ready server.
class _EventsHub {
  _EventsHub();

  final events = StreamController<ServerEvent>.broadcast();
  final connected = StreamController<void>.broadcast();
  StreamSubscription<ServerEvent>? _subscription;

  void dispose() {
    _subscription?.cancel();
    events.close();
    connected.close();
  }
}

final _eventsHubProvider = Provider<_EventsHub>((ref) {
  final hub = _EventsHub();
  ref.onDispose(hub.dispose);

  final ready = ref.watch(
    connectionProvider.select((c) => c.status == ConnectionStatus.ready),
  );
  final userId = ref.watch(sessionProvider.select((u) => u?.id));
  if (!ready || userId == null) return hub;

  final client = ref.watch(apiClientProvider);
  hub._subscription = client
      .events(onConnected: () => hub.connected.add(null))
      .listen(
        hub.events.add,
        onError: (Object error) {
          // 4401: bad / revoked tokens or logout elsewhere.
          if (error is ApiException && error.statusCode == 401) {
            scheduleMicrotask(
              () => ref.read(sessionProvider.notifier).handleUnauthorized(),
            );
          }
        },
      );
  return hub;
});

/// Server push events (broadcast). Empty while logged out; replaced when the
/// session or server changes, so `ref.watch` it and subscribe in `build`:
///
/// ```dart
/// final sub = ref.watch(eventsProvider).listen(...);
/// ref.onDispose(sub.cancel);
/// ```
///
/// The server does not replay missed events: also listen to
/// [eventsConnectedProvider] and refetch there.
final eventsProvider = Provider<Stream<ServerEvent>>(
  (ref) => ref.watch(_eventsHubProvider).events.stream,
);

/// Fires every time the event socket (re)connects. Missed events are not
/// replayed, so state derived from events should be refetched here.
final eventsConnectedProvider = Provider<Stream<void>>(
  (ref) => ref.watch(_eventsHubProvider).connected.stream,
);
