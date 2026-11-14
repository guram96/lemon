import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_style.dart';

/// XMB-style shelf: a glowing blade marker, an italic uppercase title and a
/// count pill, then a full-bleed row with room for the pop and glow.
class CrossbladeShelf extends StatelessWidget {
  const CrossbladeShelf(this.config, {super.key});

  final RsShelf config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    final gutter = context.rsPageGutter;
    final aspect = config.itemAspectRatio;
    final scale = t.breakpoints.scaleFor(context.rsLayout);
    final width =
        config.itemWidth ??
        (aspect > 1 ? t.sizes.wideCapsuleWidth : t.sizes.capsuleWidth) * scale;
    final height = width / aspect;
    final bleed =
        height * (t.motion.focusScale - 1) / 2 + t.sizes.focusGlowBlur / 2;

    final header = Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: t.spacing.md,
            height: t.spacing.md + 4,
            decoration: ShapeDecoration(
              shape: const BladeBorder(slant: 5, radius: 2),
              gradient: CrossbladeStyle.gloss(t.focusSurface),
              shadows: [
                BoxShadow(
                  color: t.focusGlow,
                  blurRadius: t.spacing.sm + t.spacing.xs,
                ),
              ],
            ),
          ),
          SizedBox(width: t.spacing.sm + t.spacing.xs),
          Flexible(
            child: Text(
              config.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.4,
                shadows: [
                  Shadow(
                    color: t.art.shade.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          if (config.subtitle != null) ...[
            SizedBox(width: t.spacing.sm + t.spacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.sm + 2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(t.radii.pill),
                gradient: CrossbladeStyle.glass(t),
                border: Border.all(color: t.divider),
              ),
              child: Text(
                config.subtitle!,
                style: text.labelSmall?.copyWith(color: t.textSecondary),
              ),
            ),
          ],
          SizedBox(width: t.spacing.md),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [t.divider, t.divider.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
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
            separatorBuilder: (_, _) => SizedBox(width: t.spacing.md + 2),
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
      children: [header, row],
    );
  }
}
