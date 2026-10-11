import 'package:flutter/widgets.dart';

import '../component_set.dart';
import 'rs_glyph.dart';

/// One glyph + label pair, for example Ⓐ Select.
@immutable
class RsButtonHint {
  const RsButtonHint({
    required this.button,
    required this.label,
    this.onPressed,
  });

  final RsControllerButton button;
  final String label;

  /// Makes the hint tappable (touch / mouse). Hints never take d-pad focus:
  /// they describe buttons, they are not targets.
  final VoidCallback? onPressed;
}

/// Big Picture bottom bar of button hints.
class RsButtonHints extends StatelessWidget {
  const RsButtonHints({
    super.key,
    required this.hints,
    this.leading = const [],
    this.style,
  });

  /// Right-aligned hints (Ⓐ Select, Ⓑ Back, …).
  final List<RsButtonHint> hints;

  /// Left-aligned hints (≡ Menu, …).
  final List<RsButtonHint> leading;

  /// Defaults to the nearest [RsGlyphStyleScope] (Xbox).
  final RsGlyphStyle? style;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).buttonHints(context, this);
}
