import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_theme/rs_theme.dart';

import '../auth/login_page.dart';
import '../connection/connect_page.dart';
import '../connection/connection_provider.dart';
import '../connection/startup_page.dart';
import '../downloads/downloads_page.dart';
import '../game/game_page.dart';
import '../home/home_page.dart';
import '../library/library_page.dart';
import '../onboarding/setup_done_page.dart';
import '../onboarding/setup_wizard_page.dart';
import '../onboarding/welcome_page.dart';
import '../session/session_provider.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'redirect.dart';

export 'app_routes.dart';

/// The app's router. Redirects follow [connectionProvider] and
/// [sessionProvider] (see [resolveRedirect]).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(
    connectionProvider.select((c) => c.status),
    (_, _) => refresh.notify(),
  );
  ref.listen(sessionProvider.select((u) => u != null), (_, _) {
    refresh.notify();
  });

  final router = GoRouter(
    initialLocation: AppRoutes.startup,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      status: ref.read(connectionProvider).status,
      loggedIn: ref.read(sessionProvider) != null,
      location: state.uri.path,
    ),
    routes: [
      _route(AppRoutes.startup, (_) => const StartupPage()),
      _route(AppRoutes.connect, (_) => const ConnectPage()),
      _route(AppRoutes.welcome, (_) => const WelcomePage()),
      _route(AppRoutes.setup, (_) => const SetupWizardPage()),
      _route(AppRoutes.setupDone, (_) => const SetupDonePage()),
      _route(AppRoutes.login, (_) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          _route(AppRoutes.home, (_) => const HomePage()),
          _route(AppRoutes.library, (_) => const LibraryPage()),
          _route(AppRoutes.downloads, (_) => const DownloadsPage()),
          _route(
            AppRoutes.gamePattern,
            (state) => GameDetailPage(gameId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Big Picture pages cross-fade.
GoRoute _route(String path, Widget Function(GoRouterState state) build) =>
    GoRoute(
      path: path,
      pageBuilder: (context, state) {
        final motion = context.rsTokens.motion;
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: build(state),
          transitionDuration: motion.page,
          reverseTransitionDuration: motion.page,
          transitionsBuilder: (_, animation, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: motion.curve),
            child: child,
          ),
        );
      },
    );

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
