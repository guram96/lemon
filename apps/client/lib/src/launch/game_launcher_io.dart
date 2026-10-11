import 'dart:io';

import 'game_launcher.dart';

/// Starter backed by [dart:io]. No shell.
ProcessStarter openProcessStarter() => const IoProcessStarter();

/// Spawns a process with [Process.start] and returns its pid.
///
/// The process is detached, so this does not wait for it to exit and does
/// not attach the client's standard streams.
class IoProcessStarter implements ProcessStarter {
  const IoProcessStarter();

  @override
  Future<int> start(String executable, List<String> args) async {
    final process = await Process.start(
      executable,
      args,
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
    return process.pid;
  }
}
