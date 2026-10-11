import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture home shelf: header aligned to the page gutter, then a
/// full-bleed horizontal row with room for the focus scale and glow.
class SteamShelf extends StatelessWidget {
  const SteamShelf(this.config, {super.key});

  final RsShelf config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final gutter = context.rsPageGutter;
    final aspect = config.itemAspectRatio;
    final width = config.itemWidth ?? SteamStyle.capsuleWidth(context, aspect);
    final height = width / aspect;
    final bleed = SteamStyle.focusBleed(t, height);

    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              config.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge,
            ),
          ),
          if (config.subtitle != null) ...[
            SizedBox(width: t.spacing.sm + t.spacing.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                config.subtitle!,
                style: text.bodyMedium?.copyWith(color: t.textMuted),
              ),
            ),
          ],
          const Spacer(),
          ?config.trailing,
        ],
      ),
    );

    final Widget row;
    if (config.itemCount == 0) {
      final empty = config.emptyText;
      row = empty == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.fromLTRB(
                gutter,
                t.spacing.md,
                gutter,
                t.spacing.md,
              ),
              child: Text(
                empty,
                style: text.bodyMedium?.copyWith(color: t.textMuted),
              ),
            );
    } else {
      row = SizedBox(
        height: height + bleed * 2,
        child: RsFocusMemory(
          child: ListView.separated(
            controller: config.controller,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: gutter, vertical: bleed),
            scrollCacheExtent: ScrollCacheExtent.pixels(width * 3),
            itemCount: config.itemCount,
            separatorBuilder: (_, _) => SizedBox(width: t.spacing.md),
            itemBuilder: (context, i) => RsFocusMemoryItem(
              id: i,
              child: SizedBox(
                width: width,
                height: height,
                child: config.itemBuilder(context, i),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      // The row's bleed padding doubles as the gap under the header.
      children: [header, row],
    );
  }
}
