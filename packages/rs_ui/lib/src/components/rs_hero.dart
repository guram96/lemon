import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Game page header: wide background art (or generated art), a fade into
/// the page, and the logo or title over it.
class RsHero extends StatelessWidget {
  const RsHero({
    super.key,
    required this.title,
    this.systemId,
    this.systemName,
    this.image,
    this.logo,
    this.subtitle,
    this.height,
    this.child,
  });

  final String title;
  final String? systemId;
  final String? systemName;

  /// Wide hero art; generated art when null or failing.
  final ImageProvider? image;

  /// Transparent logo drawn instead of the title text.
  final ImageProvider? logo;

  /// Under the title, for example "Super Nintendo · 1995".
  final String? subtitle;

  /// Defaults to a responsive height.
  final double? height;

  /// Under the title (for example the Play button row).
  final Widget? child;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).hero(context, this);
}
