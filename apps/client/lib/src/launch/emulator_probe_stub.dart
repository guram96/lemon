import 'emulator_probe.dart';

/// Web stand-in. Detection needs a filesystem.
EmulatorProbe openEmulatorProbe() => const _UnavailableEmulatorProbe();

class _UnavailableEmulatorProbe implements EmulatorProbe {
  const _UnavailableEmulatorProbe();

  @override
  String get home => _unsupported();

  @override
  bool exists(String path) => _unsupported();

  @override
  List<String> listFiles(String directory) => _unsupported();

  @override
  String? findOnPath(String name) => _unsupported();
}

Never _unsupported() => throw UnsupportedError(
  'EmulatorProbe is unavailable where dart:io is missing',
);
