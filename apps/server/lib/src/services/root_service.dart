import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';

import '../db/root_repo.dart';
import '../storage/library_roots.dart';
import 'event_hub.dart';
import 'mappers.dart';

final _log = Logger('roots');

/// Keeps the catalog's library roots in sync with what is mounted.
class RootService {
  RootService(
    this._repo,
    this._events, {
    required this.searchDirs,
    this._roots = const LibraryRoots(),
  });

  final RootRepo _repo;
  final EventHub _events;
  final LibraryRoots _roots;

  /// Where to look for a root whose drive was mounted under a new path
  /// (for example `/Volumes`).
  final List<String> searchDirs;

  List<RootRecord> all() => _repo.all();

  /// Locates every root by its marker id, stores its new status and path, and
  /// publishes `rootStatusChanged` for every status change.
  Future<List<RootRecord>> refresh() async {
    for (final root in _repo.all()) {
      final RootLocation location;
      try {
        location = await _roots.locate(
          root.id,
          root.lastPath,
          label: root.label,
          searchDirs: searchDirs,
        );
      } on Object catch (e) {
        _log.warning('Could not check library root "${root.label}": $e');
        continue;
      }
      final moved = location.path != null && location.path != root.lastPath;
      if (location.status == root.status && !moved) continue;
      _repo.updateStatus(root.id, location.status, lastPath: location.path);
      if (moved) {
        _log.info('Library root "${root.label}" found at ${location.path}');
      }
      if (location.status != root.status) {
        _log.info(
          'Library root "${root.label}" is now ${location.status.name}',
        );
        final updated = _repo.byId(root.id);
        if (updated != null) {
          _events.publish(
            ServerEvent.rootStatusChanged(root: Mappers.root(updated)),
          );
        }
      }
    }
    return _repo.all();
  }
}
