/// Every route path of the client.
abstract final class AppRoutes {
  /// Startup splash while the server is probed.
  static const startup = '/';

  /// "Server not found": Retry + manual address.
  static const connect = '/connect';

  static const welcome = '/welcome';
  static const setup = '/setup';
  static const setupDone = '/setup/done';
  static const login = '/login';

  // Inside the main shell (top bar + button hints).
  static const home = '/home';
  static const library = '/library';
  static const gamePattern = '/game/:id';
  static String game(String id) => '/game/${Uri.encodeComponent(id)}';
}
