import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';

import 'events_provider.dart';

/// A counter that goes up when the library changed on the server. Library
/// providers `ref.watch` it to refetch.
///
/// Bumps on `libraryChanged` events, coalesced: the first event starts a
/// [LibraryRevisionNotifier.window] timer and everything until it fires is
/// one bump (so the home screen still fills in live during a long scan). Also
/// bumps when the event socket reconnects, since missed events are not
/// replayed.
final libraryRevisionProvider = NotifierProvider<LibraryRevisionNotifier, int>(
  LibraryRevisionNotifier.new,
);

class LibraryRevisionNotifier extends Notifier<int> {
  static const window = Duration(milliseconds: 300);

  Timer? _pending;

  @override
  int build() {
    var firstConnect = true;
    final events = ref.watch(eventsProvider).listen((event) {
      if (event is LibraryChangedEvent) _schedule();
    });
    final reconnects = ref.watch(eventsConnectedProvider).listen((_) {
      // The first connect follows a login / startup, where screens fetch
      // anyway.
      if (firstConnect) {
        firstConnect = false;
        return;
      }
      _schedule();
    });
    ref.onDispose(() {
      events.cancel();
      reconnects.cancel();
      _pending?.cancel();
      _pending = null;
    });
    return stateOrNull ?? 0;
  }

  /// Forces a refetch, for example after an admin action.
  void bump() => state++;

  void _schedule() {
    _pending ??= Timer(window, () {
      _pending = null;
      if (ref.mounted) state++;
    });
  }
}
