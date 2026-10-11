import '../connection/connection_provider.dart';
import 'app_routes.dart';

/// Router guard. Pure, so it is easy to test.
///
/// - searching → `/` (or stays on `/connect` while retrying)
/// - unreachable → `/connect`
/// - unconfigured → `/welcome` (`/setup` allowed)
/// - ready, logged out → `/login`
/// - ready, logged in → `/home` from any pre-login page; `/setup` (just
///   finished) → `/setup/done`
String? resolveRedirect({
  required ConnectionStatus status,
  required bool loggedIn,
  required String location,
}) {
  String? to(String target) => location == target ? null : target;

  switch (status) {
    case ConnectionStatus.searching:
      return location == AppRoutes.connect ? null : to(AppRoutes.startup);
    case ConnectionStatus.unreachable:
      return to(AppRoutes.connect);
    case ConnectionStatus.unconfigured:
      return location == AppRoutes.welcome || location == AppRoutes.setup
          ? null
          : AppRoutes.welcome;
    case ConnectionStatus.ready:
      if (!loggedIn) return to(AppRoutes.login);
      if (location == AppRoutes.setup) return AppRoutes.setupDone;
      const preLogin = {
        AppRoutes.startup,
        AppRoutes.connect,
        AppRoutes.welcome,
        AppRoutes.login,
      };
      return preLogin.contains(location) ? AppRoutes.home : null;
  }
}
