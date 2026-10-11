import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/connection/local_server.dart';
import 'package:rs_client/src/connection/local_server_io.dart'
    show bundledServerPath;

void main() {
  test('rs_server sits next to the client executable', () {
    final sep = Platform.pathSeparator;
    final client =
        '${sep}Applications${sep}retro_steam.app${sep}Contents${sep}MacOS${sep}retro_steam';
    expect(
      bundledServerPath(client),
      '${sep}Applications${sep}retro_steam.app${sep}Contents${sep}MacOS${sep}rs_server',
    );
  });

  test('the test process does not spawn a server', () async {
    // rs_server is not next to the test runner, so this must not spawn.
    expect(await openLocalServer().start(), isFalse);
  });
}
