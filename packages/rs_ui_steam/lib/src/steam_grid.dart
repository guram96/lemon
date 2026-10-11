import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture library grid: as many columns as fit at the capsule width,
/// with room around cells for the focus scale and glow.
class SteamGrid extends StatelessWidget {
  const SteamGrid(this.config, {super.key});

  final RsGrid config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final gutter = context.rsPageGutter;
    final aspect = config.itemAspectRatio;
    final minWidth =
        config.minItemWidth ?? SteamStyle.capsuleWidth(context, aspect);
    final hGap = t.spacing.md + t.spacing.xs;
    final vGap = t.spacing.lg;

    return LayoutBuilder(
      builder: (context, box) {
        final padding =
            config.padding?.resolve(Directionality.of(context)) ??
            EdgeInsets.fromLTRB(gutter, t.spacing.lg, gutter, t.spacing.xxl);
        final available = box.maxWidth - padding.horizontal;
        final columns = math.max(
          1,
          ((available + hGap) / (minWidth + hGap)).floor(),
        );
        final cellWidth = (available - hGap * (columns - 1)) / columns;
        final cellHeight = cellWidth / aspect;
        return CustomScrollView(
          controller: config.controller,
          // Keep a couple of rows built beyond the viewport so d-pad down
          // always has a target.
          scrollCacheExtent: ScrollCacheExtent.pixels((cellHeight + vGap) * 2),
          slivers: [
            if (config.header case final header?)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                    top: t.spacing.md,
                  ),
                  child: header,
                ),
              ),
            if (config.itemCount == 0)
              SliverFillRemaining(
                hasScrollBody: false,
                child: config.empty ?? const SizedBox.shrink(),
              )
            else
              SliverPadding(
                padding: padding,
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: vGap,
                    crossAxisSpacing: hGap,
                    childAspectRatio: aspect,
                  ),
                  itemCount: config.itemCount,
                  itemBuilder: config.itemBuilder,
                ),
              ),
          ],
        );
      },
    );
  }
}
