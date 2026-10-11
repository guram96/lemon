import 'package:flutter/widgets.dart';

import '../component_set.dart';

enum RsButtonVariant {
  /// Default button.
  standard,

  /// Main call to action, for example Play or Install.
  primary,

  /// Destructive action, for example Uninstall or Delete.
  danger,
}

class RsButton extends StatelessWidget {
  const RsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = RsButtonVariant.standard,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final IconData? icon;
  final RsButtonVariant variant;
  final bool autofocus;
  final FocusNode? focusNode;

  bool get enabled => onPressed != null;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).button(context, this);
}
