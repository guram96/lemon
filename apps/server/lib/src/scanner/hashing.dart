/// Single-pass CRC32 + MD5 + SHA1 file hashing and a bounded isolate pool.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Files larger than this are hashed partially by default (4 GiB).
const defaultPartialHashThreshold = 4 * 1024 * 1024 * 1024;

/// Bytes hashed from the start and from the end of a large file (64 MiB).
const defaultPartialHashChunk = 64 * 1024 * 1024;

const _bufferSize = 1024 * 1024;

/// Hashes of one file.
class FileHashes {
  const FileHashes({
    required this.crc32,
    required this.md5,
    required this.sha1,
    required this.size,
    required this.partial,
  });

  final String crc32;
  final String md5;
  final String sha1;

  /// Size of the file when it was hashed.
  final int size;

  /// See [hashFileSync].
  final bool partial;
}

/// Hashing failed for one file (unreadable, vanished, …).
class HashFailure implements Exception {
  const HashFailure(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => 'HashFailure($path): $message';
}

/// The pool was killed while a job was pending.
class HashPoolClosed implements Exception {
  const HashPoolClosed();
}

/// Incremental CRC-32 (IEEE 802.3, the one used by zip and No-Intro DATs).
class Crc32 {
  static final Uint32List _table = _buildTable();

  static Uint32List _buildTable() {
    final t = Uint32List(256);
    for (var n = 0; n < 256; n++) {
      var c = n;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
      t[n] = c;
    }
    return t;
  }

  int _crc = 0xFFFFFFFF;

  void add(Uint8List data) {
    var c = _crc;
    final t = _table;
    for (var i = 0; i < data.length; i++) {
      c = t[(c ^ data[i]) & 0xFF] ^ (c >> 8);
    }
    _crc = c;
  }

  int get value => (_crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;

  String get hex => value.toRadixString(16).padLeft(8, '0');
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}

/// Hashes [path] with CRC32, MD5 and SHA1 in one streaming pass.
///
/// Files larger than [partialThreshold] are hashed partially: the first
/// [partialChunk] bytes, then the last [partialChunk] bytes, then the file
/// size as 8 bytes little-endian; the result is flagged `partial`.
///
/// Synchronous on purpose: it runs inside a worker isolate.
FileHashes hashFileSync(
  String path, {
  int partialThreshold = defaultPartialHashThreshold,
  int partialChunk = defaultPartialHashChunk,
}) {
  final crc = Crc32();
  final md5Out = _DigestSink();
  final sha1Out = _DigestSink();
  final md5In = md5.startChunkedConversion(md5Out);
  final sha1In = sha1.startChunkedConversion(sha1Out);

  void feed(Uint8List data) {
    crc.add(data);
    md5In.add(data);
    sha1In.add(data);
  }

  final raf = File(path).openSync();
  int size;
  bool partial;
  try {
    size = raf.lengthSync();
    partial = size > partialThreshold;
    final buffer = Uint8List(_bufferSize);

    void readRange(int start, int length) {
      raf.setPositionSync(start);
      var remaining = length;
      while (remaining > 0) {
        final want = remaining < buffer.length ? remaining : buffer.length;
        final n = raf.readIntoSync(buffer, 0, want);
        if (n <= 0) break;
        feed(Uint8List.sublistView(buffer, 0, n));
        remaining -= n;
      }
    }

    if (!partial) {
      readRange(0, size);
    } else {
      readRange(0, partialChunk);
      readRange(size - partialChunk, partialChunk);
      final sizeBytes = ByteData(8)..setUint64(0, size, Endian.little);
      feed(sizeBytes.buffer.asUint8List());
    }
  } finally {
    raf.closeSync();
  }
  md5In.close();
  sha1In.close();
  return FileHashes(
    crc32: crc.hex,
    md5: md5Out.value.toString(),
    sha1: sha1Out.value.toString(),
    size: size,
    partial: partial,
  );
}

class _Job {
  _Job(this.path, this.threshold, this.chunk);

  final String path;
  final int threshold;
  final int chunk;
  final completer = Completer<FileHashes>();
}

class _Worker {
  _Worker(this.isolate, this.port, this.inbox);

  final Isolate isolate;
  final ReceivePort port;
  final SendPort inbox;
  _Job? job;
}

/// A fixed-size pool of hashing isolates. Jobs queue when all are busy.
class HashPool {
  HashPool._(this._workers);

  final List<_Worker> _workers;
  final Queue<_Job> _queue = Queue();
  bool _closed = false;

  int get size => _workers.length;

  /// Spawns [size] worker isolates (at least 1).
  static Future<HashPool> spawn(int size) async {
    final workers = <_Worker>[];
    final pool = HashPool._(workers);
    for (var i = 0; i < (size < 1 ? 1 : size); i++) {
      final port = ReceivePort();
      final handshake = Completer<SendPort>();
      late _Worker worker;
      port.listen((Object? message) {
        if (message is SendPort) {
          handshake.complete(message);
          return;
        }
        pool._onResult(worker, message);
      });
      final isolate = await Isolate.spawn(
        _workerMain,
        port.sendPort,
        debugName: 'rs-scanner-hash-$i',
      );
      worker = _Worker(isolate, port, await handshake.future);
      workers.add(worker);
    }
    return pool;
  }

  /// Hashes [path] on a worker. Throws [HashFailure] if the file cannot be
  /// read and [HashPoolClosed] if the pool is killed first.
  Future<FileHashes> hash(
    String path, {
    int partialThreshold = defaultPartialHashThreshold,
    int partialChunk = defaultPartialHashChunk,
  }) {
    if (_closed) return Future.error(const HashPoolClosed());
    final job = _Job(path, partialThreshold, partialChunk);
    _queue.add(job);
    _dispatch();
    return job.completer.future;
  }

  void _dispatch() {
    for (final w in _workers) {
      if (_queue.isEmpty) return;
      if (w.job != null) continue;
      final job = _queue.removeFirst();
      w.job = job;
      w.inbox.send(<Object>[job.path, job.threshold, job.chunk]);
    }
  }

  void _onResult(_Worker worker, Object? message) {
    final job = worker.job;
    worker.job = null;
    if (job != null && message is List<Object?>) {
      final error = message[0] as String?;
      if (error != null) {
        job.completer.completeError(HashFailure(job.path, error));
      } else {
        job.completer.complete(
          FileHashes(
            crc32: message[1]! as String,
            md5: message[2]! as String,
            sha1: message[3]! as String,
            size: message[4]! as int,
            partial: message[5]! as bool,
          ),
        );
      }
    }
    if (!_closed) _dispatch();
  }

  /// Kills all workers immediately (even mid-file). Pending and running jobs
  /// fail with [HashPoolClosed]. Safe to call more than once.
  void kill() {
    if (_closed) return;
    _closed = true;
    for (final w in _workers) {
      w.isolate.kill(priority: Isolate.immediate);
      w.port.close();
      final job = w.job;
      w.job = null;
      if (job != null && !job.completer.isCompleted) {
        job.completer.completeError(const HashPoolClosed());
      }
    }
    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();
      job.completer.completeError(const HashPoolClosed());
    }
  }
}

void _workerMain(SendPort out) {
  final inbox = ReceivePort();
  out.send(inbox.sendPort);
  inbox.listen((Object? message) {
    final m = message! as List<Object?>;
    final path = m[0]! as String;
    try {
      final h = hashFileSync(
        path,
        partialThreshold: m[1]! as int,
        partialChunk: m[2]! as int,
      );
      out.send(<Object?>[null, h.crc32, h.md5, h.sha1, h.size, h.partial]);
    } on FileSystemException catch (e) {
      final os = e.osError?.message;
      out.send(<Object?>[os == null ? e.message : '${e.message}: $os']);
    } on Object catch (e) {
      out.send(<Object?>[e.toString()]);
    }
  });
}
