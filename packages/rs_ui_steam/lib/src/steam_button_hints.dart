import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture footer: translucent bar with glyph + label pairs.
class SteamButtonHints extends StatelessWidget {
  const SteamButtonHints(this.config, {super.key});

  final RsButtonHints config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final gutter = context.rsPageGutter;
    Widget hint(RsButtonHint h) => _Hint(hint: h, style: config.style);
    return Container(
      decoration: BoxDecoration(
        color: t.barBackground,
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: t.sizes.hintBar,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                // Phones only have room for the right-hand hints.
                if (context.rsLayout != RsLayoutClass.compact)
                  for (final h in config.leading) hint(h),
                // Right-aligned hints scroll instead of overflowing on phones.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      children: [for (final h in config.hints) hint(h)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.hint, required this.style});

  final RsButtonHint hint;
  final RsGlyphStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return SteamTapTarget(
      onTap: hint.onPressed,
      semanticLabel: hint.label,
      builder: (context, state) => AnimatedContainer(
        duration: t.motion.fast,
        margin: EdgeInsets.only(left: t.spacing.md),
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.sm,
          vertical: t.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: state.highlighted ? t.track : t.track.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(t.radii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RsGlyph(button: hint.button, style: style),
            SizedBox(width: t.spacing.sm),
            Text(
              hint.label,
              style: SteamStyle.text(context).labelLarge
                  ?.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
