import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../notifications/notification_host.dart';
import '../routing/router.dart';
import 'component_set_provider.dart';
import 'theme_settings_provider.dart';

/// Root widget. `MaterialApp` is used only as plumbing (theme, localizations,
/// overlays, routing); the visible UI comes from the active [RsComponentSet].
class RetroSteamApp extends ConsumerWidget {
  const RetroSteamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final look = ref.watch(lookProvider);
    final componentSet = look.set;
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Retro Steam',
      debugShowCheckedModeBanner: false,
      theme: look.light(settings),
      darkTheme: look.dark(settings),
      themeMode: settings.mode,
      routerConfig: router,
      builder: (context, child) => RsComponents(
        set: componentSet,
        child: RsInputScope(
          child: Actions(
            actions: {
              RsBackIntent: CallbackAction<RsBackIntent>(
                onInvoke: (_) {
                  if (router.canPop()) {
                    router.pop();
                  } else if (router.state.uri.path == AppRoutes.settings) {
                    router.go(AppRoutes.home);
                  }
                  return null;
                },
              ),
            },
            child: _Background(
              child: NotificationHost(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big Picture's full-screen gradient backdrop behind every page.
class _Background extends StatelessWidget {
  const _Background({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [t.background, t.backgroundGradientEnd],
        ),
      ),
      child: child,
    );
  }
}
