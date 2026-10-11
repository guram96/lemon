import 'emulator_probe_stub.dart'
    if (dart.library.io) 'emulator_probe_io.dart'
    as emulator_probe_io;

/// Synchronous filesystem view used by emulator detection.
///
/// Tests inject a fake. The app uses [openEmulatorProbe].
abstract interface class EmulatorProbe {
  /// Directory substituted for a leading `~` in manifest paths.
  String get home;

  /// True when [path] exists as a file or a directory.
  bool exists(String path);

  /// File names in [directory], not subdirectories.
  ///
  /// Empty when [directory] is missing or cannot be read.
  List<String> listFiles(String directory);

  /// Absolute path of [name] on `PATH`, or null when it is not there.
  String? findOnPath(String name);
}

/// Probe for this process. On the web, using it throws [UnsupportedError].
EmulatorProbe openEmulatorProbe() => emulator_probe_io.openEmulatorProbe();
