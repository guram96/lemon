/// Web builds have no install folder. The download queue is not used there.
Future<bool> writeDownloadFile({
  required String folder,
  required String path,
  required List<int> bytes,
  required bool append,
}) async => throw UnsupportedError('Downloads are not available on the web.');
