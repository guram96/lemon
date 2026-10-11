import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// A library root changed and should be scanned again.
class RootLibraryChange {
  const RootLibraryChange(this.rootId);

  final String rootId;
}

/// Watches online library roots and emits one [RootLibraryChange] per root
/// after changes have been quiet for [quiet].
///
/// Hidden names, `.retrosteam`, and EmulationStation media folders are
/// ignored. The event does not list files; the scanner diffs the root.
class LibraryWatcher {
  LibraryWatcher({this.quiet = const Duration(seconds: 2)});

  static const ignoredFolders = {
    'media',
    'images',
    'videos',
    'manuals',
    'downloaded_media',
  };

  final Duration quiet;

  final _changes = StreamController<RootLibraryChange>.broadcast();
  final _subs = <String, StreamSubscription<FileSystemEvent>>{};
  final _timers = <String, Timer>{};
  final _paths = <String, String>{};

  Stream<RootLibraryChange> get changes => _changes.stream;

  /// Replaces any existing watch for [rootId].
  void watch({required String rootId, required String path}) {
    unwatch(rootId);
    _paths[rootId] = path;
    _subs[rootId] = Directory(path)
        .watch(recursive: true)
        .listen((event) => _onEvent(rootId, event.path), onError: (_, _) {});
  }

  void unwatch(String rootId) {
    _timers.remove(rootId)?.cancel();
    final sub = _subs.remove(rootId);
    _paths.remove(rootId);
    if (sub != null) unawaited(sub.cancel());
  }

  Future<void> close() async {
    final subs = _subs.values.toList();
    _subs.clear();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _paths.clear();
    for (final sub in subs) {
      await sub.cancel();
    }
    await _changes.close();
  }

  void _onEvent(String rootId, String path) {
    final root = _paths[rootId];
    if (root == null || _ignored(root, path)) return;
    _timers[rootId]?.cancel();
    _timers[rootId] = Timer(quiet, () {
      _timers.remove(rootId);
      if (!_changes.isClosed) _changes.add(RootLibraryChange(rootId));
    });
  }

  bool _ignored(String root, String path) {
    final relative = p.relative(path, from: root);
    if (relative == '.' || relative.isEmpty) return true;
    if (p.isAbsolute(relative) || relative.startsWith('..')) return true;
    for (final part in p.split(relative)) {
      if (part.startsWith('.')) return true;
      if (ignoredFolders.contains(part.toLowerCase())) return true;
    }
    return false;
  }
}
