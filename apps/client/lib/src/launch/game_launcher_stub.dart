import 'game_launcher.dart';

/// Web stand-in. Starting a process needs `dart:io`.
ProcessStarter openProcessStarter() => const _UnavailableProcessStarter();

class _UnavailableProcessStarter implements ProcessStarter {
  const _UnavailableProcessStarter();

  @override
  Future<int> start(String executable, List<String> args) => _unsupported();
}

Never _unsupported() => throw UnsupportedError(
  'ProcessStarter is unavailable where dart:io is missing',
);
