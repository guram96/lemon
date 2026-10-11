import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Big Picture notification card: icon, title, body, optional progress.
/// Place toasts in an [RsToastStack]; give each one a stable [key].
class RsToast extends StatelessWidget {
  const RsToast({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.image,
    this.progress,
    this.indeterminate = false,
    this.onPressed,
    this.onDismiss,
  });

  final String title;
  final String? body;
  final IconData? icon;

  /// Square artwork instead of [icon], for example the game's capsule.
  final ImageProvider? image;

  /// 0..1 shows a progress bar.
  final double? progress;

  /// Shows an indeterminate bar when [progress] is null.
  final bool indeterminate;

  /// Tap / click action. Toasts never take d-pad focus.
  final VoidCallback? onPressed;

  /// Shows a close button.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).toast(context, this);
}

/// Bottom-right column of [RsToast]s. Toasts added to [toasts] slide in,
/// removed ones slide out; identity is each toast's `key`. Fill the screen
/// with it (for example in an `Overlay` or `Stack`); taps outside the toasts
/// pass through.
class RsToastStack extends StatelessWidget {
  const RsToastStack({super.key, required this.toasts});

  /// Newest last (shown at the bottom). Every toast needs a unique key.
  final List<RsToast> toasts;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).toastStack(context, this);
}
