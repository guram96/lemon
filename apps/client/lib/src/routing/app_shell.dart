import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rs_ui/rs_ui.dart';

import '../notifications/notification_center.dart';
import '../session/session_provider.dart';
import 'app_routes.dart';

/// Main shell for `/home`, `/library` and `/game/:id`: Big Picture top bar
/// (Home, Library, bell, user) and button hints around the page.
///
/// Pages inside the shell return only their body, not an `RsScaffold`.
/// `/home` and `/game/:id` extend behind the top bar (background art / hero
/// run full-bleed); pad content by `context.rsTokens.sizes.topBar`.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _items = [RsNavItem(label: 'Home'), RsNavItem(label: 'Library')];

  static bool extendsBehindTopBar(String location) =>
      location == AppRoutes.home || location.startsWith('/game/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final unread = ref.watch(
      notificationCenterProvider.select((s) => s.unreadCount),
    );
    final selected = location.startsWith(AppRoutes.library) ? 1 : 0;

    return RsScaffold(
      extendBodyBehindTopBar: extendsBehindTopBar(location),
      topBar: RsTopBar(
        items: _items,
        selectedIndex: selected,
        onSelected: (i) =>
            context.go(i == 1 ? AppRoutes.library : AppRoutes.home),
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
