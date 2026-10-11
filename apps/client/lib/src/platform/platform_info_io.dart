import 'dart:io';

String platformId() => Platform.operatingSystem;

String deviceName() {
  try {
    final name = Platform.localHostname;
    if (name.isNotEmpty) return name;
  } on Object {
    // Fall through to a generic name.
  }
  return 'Retro Steam (${Platform.operatingSystem})';
}
