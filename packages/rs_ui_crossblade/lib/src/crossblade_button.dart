import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_style.dart';

/// Glossy console pill. Glass at rest; focus lights it up in jewel green
/// with a breathing glow. Primary buttons are always lit in "Play" green.
class CrossbladeButton extends StatelessWidget {
  const CrossbladeButton(this.config, {super.key});

  final RsButton config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: config.onPressed,
      semanticLabel: config.label,
      builder: (context, state) {
        final hi = state.highlighted;
        final (fill, fg, lit) = _style(t, hi);
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (config.icon != null) ...[
              Icon(config.icon, size: t.sizes.icon, color: fg),
              SizedBox(width: t.spacing.sm),
            ],
            Flexible(
              child: Text(
                config.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
        return AnimatedScale(
          scale: state.pressed
              ? t.motion.pressScale
              : hi
              ? 1.04
              : 1,
          duration: t.motion.focus,
          curve: Curves.easeOutBack,
          child: CrossbladePulse(
            active: hi,
            builder: (context, pulse) => AnimatedContainer(
              duration: t.motion.focus,
              curve: t.motion.curve,
              constraints: BoxConstraints(minHeight: t.sizes.tabHeight),
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.lg + t.spacing.xs,
                vertical: t.spacing.sm + t.spacing.xs,
              ),
              decoration: BoxDecoration(
                gradient: fill,
                borderRadius: BorderRadius.circular(t.radii.pill),
                border: Border.all(
                  color: hi
                      ? t.focusRing
                      : lit
                      ? t.focusRing.withValues(alpha: 0.35)
                      : t.divider,
                  width: hi ? t.sizes.focusRingWidth : 1,
                ),
                boxShadow: hi
                    ? CrossbladeStyle.glow(t, strength: 0.75, pulse: pulse)
                    : lit
                    ? CrossbladeStyle.depth(t, scale: 0.5)
                    : null,
              ),
              child: Opacity(opacity: state.enabled ? 1 : 0.4, child: content),
            ),
          ),
        );
      },
    );
  }

  /// Fill, foreground color, and whether the button is lit at rest.
  (Gradient, Color, bool) _style(RsTokens t, bool hi) =>
      switch (config.variant) {
        RsButtonVariant.primary => (
          CrossbladeStyle.gloss(
            hi ? Color.lerp(t.play, t.focusSurface, 0.5)! : t.play,
            shine: hi ? 0.45 : 0.32,
          ),
          t.onPlay,
          true,
        ),
        RsButtonVariant.danger =>
          hi
              ? (CrossbladeStyle.gloss(t.danger), t.onPlay, true)
              : (CrossbladeStyle.glass(t), t.textSecondary, false),
        RsButtonVariant.standard =>
          hi
              ? (CrossbladeStyle.gloss(t.focusSurface), t.onFocusSurface, true)
              : (CrossbladeStyle.glass(t), t.textSecondary, false),
      };
}
