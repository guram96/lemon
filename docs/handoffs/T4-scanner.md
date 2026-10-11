# T4 scanner — handoff for T5

Import `package:rs_server/src/scanner/scanner.dart`.

```dart
const Scanner({ScannerOptions options = const ScannerOptions()});
ScanJob scan({required String rootId, required String rootPath,
              ScanIndex? previous, Iterable<GameSystem>? systems});

class ScanJob {
  Stream<ScanProgress> get progress; // broadcast, throttled (250 ms), closes at end
  Stream<ScannedGame> get games;     // each game as soon as all files are hashed
  Future<ScanResult> get result;     // throws ScanCancelledException / ScanException
  void cancel();
  List<ScanWarning> get warnings;
}
enum ScannerPhase { discovering, hashing, done, cancelled, failed } // map to rs_core ScanPhase
class ScanProgress { phase, processed, total, processedBytes, totalBytes, gamesFound,
  warningCount, currentSystemId, currentFile, fraction, isFinal }
class ScanResult { rootId, Set<String> systemIds, List<ScannedGame> games, warnings,
  filesHashed, filesReused, bytesHashed, elapsed }
class ScannedGame { rootId, systemId, primaryRelPath, title, region, List<ScannedFile> files
  (primary first), discCount, isDirectory, GameKey key, totalSize }
class ScannedFile { relPath, size, modified (UTC), crc32, md5, sha1, partialHash }
class ScanIndex { ScanIndex(Iterable<ScannedFile>); ScanIndex.empty(); }
```

Wiring:
- Build `ScanIndex` from that root's `game_files` rows.
- Upsert `job.games` into `GameRepo` in batches as they arrive → `libraryChanged` events.
- At the end, remove catalog games not in `result.games`, **only for systems in
  `result.systemIds`**. On cancel, never remove anything.
- Symlinks are skipped (warning), not followed.
