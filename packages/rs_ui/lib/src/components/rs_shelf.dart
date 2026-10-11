import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Titled horizontal row of focusable items (usually [RsGameCard]s), like
/// the shelves on the Big Picture home page.
///
/// Keeps the focused item scrolled into view and remembers the last focused
/// item, so focus returns to it when the user comes back from another shelf.
class RsShelf extends StatelessWidget {
  const RsShelf({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.subtitle,
    this.trailing,
    this.itemWidth,
    this.itemAspectRatio = 2 / 3,
    this.emptyText,
    this.controller,
  });

  final String title;

  /// Muted text after the title, for example a game count.
  final String? subtitle;

  /// Right side of the header, for example a "See all" button.
  final Widget? trailing;

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Width of each item. Defaults to the set's responsive capsule width
  /// (wide capsules when [itemAspectRatio] > 1).
  final double? itemWidth;

  /// Width / height of each item; sets the row height.
  final double itemAspectRatio;

  /// Shown instead of the row when [itemCount] is 0. `null` shows nothing.
  final String? emptyText;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).shelf(context, this);
}
