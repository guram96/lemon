import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Full-page first-run frame, like the Steam Deck setup (OOBE): step
/// indicator, title, subtitle, content, and a footer with actions.
/// Responsive down to phone width (content scrolls, footer buttons stack).
class RsWizardFrame extends StatelessWidget {
  const RsWizardFrame({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.primaryAction,
    this.secondaryAction,
    this.extraActions = const [],
    this.scrollable = true,
  });

  /// Step names, for example `['Account', 'Data', 'Library', 'Review']`.
  /// Empty hides the indicator (welcome / done pages).
  final List<String> steps;

  /// Zero-based index into [steps].
  final int currentStep;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  /// Right side of the footer, usually a primary [RsButton] ("Continue").
  final Widget? primaryAction;

  /// Left side of the footer, usually "Back".
  final Widget? secondaryAction;

  /// Placed before [primaryAction].
  final List<Widget> extraActions;

  /// Wraps [child] in a scroll view. Turn off when the child scrolls itself.
  final bool scrollable;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).wizardFrame(context, this);
}
