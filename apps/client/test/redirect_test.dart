import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/connection/connection_provider.dart';
import 'package:rs_client/src/routing/app_routes.dart';
import 'package:rs_client/src/routing/redirect.dart';

void main() {
  String? r(ConnectionStatus s, String loc, {bool loggedIn = false}) =>
      resolveRedirect(status: s, loggedIn: loggedIn, location: loc);

  test('searching shows the startup page, or stays on /connect', () {
    expect(r(ConnectionStatus.searching, AppRoutes.home), AppRoutes.startup);
    expect(r(ConnectionStatus.searching, AppRoutes.startup), isNull);
    expect(r(ConnectionStatus.searching, AppRoutes.connect), isNull);
  });

  test('unreachable → /connect', () {
    expect(
      r(ConnectionStatus.unreachable, AppRoutes.startup),
      AppRoutes.connect,
    );
    expect(r(ConnectionStatus.unreachable, AppRoutes.connect), isNull);
  });

  test('unconfigured → /welcome, setup allowed', () {
    expect(
      r(ConnectionStatus.unconfigured, AppRoutes.startup),
      AppRoutes.welcome,
    );
    expect(r(ConnectionStatus.unconfigured, AppRoutes.home), AppRoutes.welcome);
    expect(
      r(ConnectionStatus.unconfigured, AppRoutes.setupDone),
      AppRoutes.welcome,
    );
    expect(r(ConnectionStatus.unconfigured, AppRoutes.welcome), isNull);
    expect(r(ConnectionStatus.unconfigured, AppRoutes.setup), isNull);
    // Setup just returned the session, connection not flipped yet.
    expect(
      r(ConnectionStatus.unconfigured, AppRoutes.setup, loggedIn: true),
      isNull,
    );
  });

  test('ready without session → /login', () {
    expect(r(ConnectionStatus.ready, AppRoutes.startup), AppRoutes.login);
    expect(r(ConnectionStatus.ready, AppRoutes.home), AppRoutes.login);
    expect(r(ConnectionStatus.ready, AppRoutes.game('g1')), AppRoutes.login);
    expect(r(ConnectionStatus.ready, AppRoutes.login), isNull);
  });

  test('ready with session → /home', () {
    for (final loc in [
      AppRoutes.startup,
      AppRoutes.connect,
      AppRoutes.welcome,
      AppRoutes.login,
    ]) {
      expect(r(ConnectionStatus.ready, loc, loggedIn: true), AppRoutes.home);
    }
    expect(r(ConnectionStatus.ready, AppRoutes.home, loggedIn: true), isNull);
    expect(
      r(ConnectionStatus.ready, AppRoutes.library, loggedIn: true),
      isNull,
    );
    expect(
      r(ConnectionStatus.ready, AppRoutes.game('g1'), loggedIn: true),
      isNull,
    );
  });

  test('finishing setup moves to /setup/done', () {
    expect(
      r(ConnectionStatus.ready, AppRoutes.setup, loggedIn: true),
      AppRoutes.setupDone,
    );
    expect(
      r(ConnectionStatus.ready, AppRoutes.setupDone, loggedIn: true),
      isNull,
    );
  });
}
