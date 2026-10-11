import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Shape of game artwork.
enum RsArtLayout {
  /// Vertical library capsule, 2:3.
  cover,

  /// Horizontal header capsule, about 2.14:1.
  wide,

  /// Full-bleed page background / hero: no title or system label.
  background;

  /// Width / height for this layout (`null` for [background]: fills its box).
  double? get aspectRatio => switch (this) {
    RsArtLayout.cover => 2 / 3,
    RsArtLayout.wide => 460 / 215,
    RsArtLayout.background => null,
  };
}

/// Game artwork: [image] when it loads, otherwise generated art (a
/// deterministic gradient from [systemId] and [title], with the title and
/// system name). Non-interactive; use [RsGameCard] for a focusable capsule.
class RsGameArt extends StatelessWidget {
  const RsGameArt({
    super.key,
    required this.title,
    this.systemId,
    this.systemName,
    this.image,
    this.layout = RsArtLayout.cover,
  });

  final String title;

  /// EmulationStation system ID (`snes`, `psx`, …); picks the color family.
  final String? systemId;

  /// Display name, for example "Super Nintendo".
  final String? systemName;
  final ImageProvider? image;
  final RsArtLayout layout;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).gameArt(context, this);
}

/// Focusable game capsule: scales up with a glow when focused. Fills the
/// width it is given, at the [layout]'s aspect ratio.
class RsGameCard extends StatelessWidget {
  const RsGameCard({
    super.key,
    required this.title,
    required this.onPressed,
    this.systemId,
    this.systemName,
    this.image,
    this.layout = RsArtLayout.cover,
    this.installed = false,
    this.showSystemBadge = false,
    this.progress,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChanged,
  });

  final String title;
  final String? systemId;
  final String? systemName;

  /// Artwork; generated art is shown while it loads and if it fails.
  final ImageProvider? image;

  /// [RsArtLayout.cover] or [RsArtLayout.wide].
  final RsArtLayout layout;
  final VoidCallback? onPressed;

  /// Shows the "installed on this device" badge.
  final bool installed;

  /// Shows a system chip over real artwork (useful in mixed-system rows
  /// such as "Recent"). Generated art always names the system.
  final bool showSystemBadge;

  /// Download progress 0..1; `null` hides the bar.
  final double? progress;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Lets screens react to focus, for example to update a background.
  final ValueChanged<bool>? onFocusChanged;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).gameCard(context, this);
}
