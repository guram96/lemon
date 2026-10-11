import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_ui/rs_ui.dart';

import '../notifications/notification_center.dart';
import '../platform/client_capabilities.dart';
import '../session/session_provider.dart';
import 'app_routes.dart';

/// Main shell for `/home`, `/library`, `/downloads` and `/game/:id`.
///
/// The top bar is Home, Library, and Downloads when this device can install
/// games. Downloads is left out otherwise (the web client). Pages inside the
/// shell return only their body, not an `RsScaffold`. `/home` and `/game/:id`
/// extend behind the top bar; pad that content by `context.rsTokens.sizes.topBar`.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static bool extendsBehindTopBar(String location) =>
      location == AppRoutes.home || location.startsWith('/game/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final unread = ref.watch(
      notificationCenterProvider.select((s) => s.unreadCount),
    );
    final canInstall = ref.watch(
      clientCapabilitiesProvider.select((caps) => caps.canInstallGames),
    );
    final items = <RsNavItem>[
      const RsNavItem(label: 'Home'),
      const RsNavItem(label: 'Library'),
      if (canInstall) const RsNavItem(label: 'Downloads'),
    ];

    return RsScaffold(
      extendBodyBehindTopBar: extendsBehindTopBar(location),
      topBar: RsTopBar(
        items: items,
        selectedIndex: _selectedIndex(location, canInstall: canInstall),
        onSelected: (index) => context.go(switch (index) {
          1 => AppRoutes.library,
          2 => AppRoutes.downloads,
          _ => AppRoutes.home,
        }),
        notificationCount: unread,
        // TODO(M2+): notifications panel; for now opening clears the badge.
        onNotifications: () =>
            ref.read(notificationCenterProvider.notifier).markAllRead(),
        userName: user?.username,
        onAvatar: () => _showAccountDialog(context, ref),
      ),
      hints: RsButtonHints(
        hints: [
          const RsButtonHint(button: RsControllerButton.a, label: 'Select'),
          RsButtonHint(
            button: RsControllerButton.b,
            label: 'Back',
            onPressed: () {
              final router = GoRouter.of(context);
              if (router.canPop()) router.pop();
            },
          ),
        ],
      ),
      body: child,
    );
  }

  /// Home is 0, Library is 1, Downloads is 2. Game pages stay on Home.
  static int _selectedIndex(String location, {required bool canInstall}) {
    if (location.startsWith(AppRoutes.library)) return 1;
    if (canInstall && location.startsWith(AppRoutes.downloads)) return 2;
    return 0;
  }

  Future<void> _showAccountDialog(BuildContext context, WidgetRef ref) =>
      showRsDialog<void>(
        context: context,
        builder: (dialogContext) {
          final user = ref.read(sessionProvider);
          return RsDialog(
            title: user?.username ?? 'Account',
            message: 'Signed in on this device.',
            actions: [
              RsButton(
                label: 'Sign out',
                variant: RsButtonVariant.danger,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(sessionProvider.notifier).logout();
                },
              ),
              RsButton(
                label: 'Cancel',
                autofocus: true,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          );
        },
      );
}
