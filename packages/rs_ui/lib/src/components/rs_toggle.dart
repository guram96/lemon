import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// On/off switch with a label, as used in settings rows.
class RsToggle extends StatelessWidget {
  const RsToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final String? description;
  final bool value;

  /// `null` disables the toggle.
  final ValueChanged<bool>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).toggle(context, this);
}
