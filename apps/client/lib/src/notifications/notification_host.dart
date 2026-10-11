import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'notification_center.dart';

/// Draws the [NotificationCenter]'s toasts bottom-right, above [child] (the
/// router). Taps outside the toasts pass through.
class NotificationHost extends ConsumerWidget {
  const NotificationHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final center = ref.read(notificationCenterProvider.notifier);
    center.toastHold = context.rsTokens.motion.toastHold;
    final toasts = ref.watch(
      notificationCenterProvider.select((s) => s.toasts),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned.fill(
          child: RsToastStack(
            toasts: [
              for (final n in toasts)
                RsToast(
                  key: ValueKey(n.id),
                  title: n.title,
                  body: n.body,
                  icon: n.icon,
                  progress: n.progress,
                  indeterminate: n.indeterminate,
                  onDismiss: n.persistent ? null : () => center.dismiss(n.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
