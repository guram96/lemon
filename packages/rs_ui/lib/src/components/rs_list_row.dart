import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Settings-style row: leading icon, title, subtitle, and a trailing value,
/// switch, chevron or custom widget. Always focusable (also when
/// [onPressed] is null, so the d-pad can reach and scroll to it).
class RsListRow extends StatelessWidget {
  const RsListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.value,
    this.switchValue,
    this.chevron = false,
    this.trailing,
    this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChanged,
  });

  final String title;
  final String? subtitle;

  /// Leading icon; ignored when [leading] is set.
  final IconData? icon;
  final Widget? leading;

  /// Trailing text, for example "1.2 TB free".
  final String? value;

  /// Shows a trailing switch in this state. Flip it in [onPressed].
  final bool? switchValue;

  /// Shows a trailing chevron (navigates somewhere).
  final bool chevron;

  /// Custom trailing widget, after [value].
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).listRow(context, this);
}
