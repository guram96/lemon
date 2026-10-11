import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// A focusable artwork tile: game capsules, shelf items, system tiles.
class RsTile extends StatelessWidget {
  const RsTile({
    super.key,
    required this.image,
    required this.onPressed,
    this.title,
    this.aspectRatio = 2 / 3,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChanged,
  });

  /// Artwork. A set may show [title] instead while it loads or if it fails.
  final ImageProvider? image;
  final String? title;
  final VoidCallback? onPressed;

  /// Width / height. Defaults to Steam's vertical library capsule (2:3).
  final double aspectRatio;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Lets screens react to focus, for example to update a background hero.
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).tile(context, this);
}
