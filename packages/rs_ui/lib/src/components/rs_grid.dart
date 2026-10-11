import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Responsive, scrollable grid of focusable items (the library). D-pad moves
/// between cells; the focused cell is kept scrolled into view.
class RsGrid extends StatelessWidget {
  const RsGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemAspectRatio = 2 / 3,
    this.minItemWidth,
    this.padding,
    this.controller,
    this.empty,
    this.header,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  /// Width / height of each cell.
  final double itemAspectRatio;

  /// Cells are at least this wide; defaults to the set's responsive capsule
  /// width.
  final double? minItemWidth;

  /// Defaults to the page gutter.
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  /// Shown when [itemCount] is 0.
  final Widget? empty;

  /// Scrolls with the grid, above the first row.
  final Widget? header;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).grid(context, this);
}
