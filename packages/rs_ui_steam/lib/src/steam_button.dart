import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture button: flat dark fill at rest, bright highlight when focused.
/// Primary buttons use the green "Play" gradient.
class SteamButton extends StatelessWidget {
  const SteamButton(this.config, {super.key});

  final RsButton config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: config.onPressed,
      semanticLabel: config.label,
      builder: (context, state) {
        final (fill, fg) = _colors(t, state);
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (config.icon != null) ...[
              Icon(config.icon, size: t.sizes.icon, color: fg),
              SizedBox(width: t.spacing.sm),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: t.motion.focus,
                curve: t.motion.curve,
                style: (text.labelLarge ?? const TextStyle()).copyWith(
                  color: fg,
                ),
                child: Text(
                  config.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        );
        return AnimatedScale(
          scale: state.pressed ? t.motion.pressScale : 1,
          duration: t.motion.fast,
          curve: t.motion.curve,
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            constraints: BoxConstraints(minHeight: t.sizes.tabHeight),
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.lg,
              vertical: t.spacing.sm + t.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: fill is Color ? fill : null,
              gradient: fill is Gradient ? fill : null,
              borderRadius: BorderRadius.circular(t.radii.sm),
              boxShadow: state.highlighted
                  ? SteamStyle.focusGlow(t, strength: 0.6)
                  : null,
            ),
            child: Opacity(opacity: state.enabled ? 1 : 0.4, child: content),
          ),
        );
      },
    );
  }

  /// Returns the fill (a [Color] or [Gradient]) and the foreground color.
  (Object, Color) _colors(RsTokens t, RsFocusState state) {
    final hi = state.highlighted;
    return switch (config.variant) {
      RsButtonVariant.primary => (
        LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: hi
              ? [Color.lerp(t.play, t.onPlay, 0.25)!, t.play]
              : [t.play, Color.lerp(t.play, t.art.shade, 0.25)!],
        ),
        t.onPlay,
      ),
      RsButtonVariant.danger =>
        hi ? (t.danger, t.onPlay) : (t.surface, t.textSecondary),
      RsButtonVariant.standard =>
        hi ? (t.focusSurface, t.onFocusSurface) : (t.surface, t.textSecondary),
    };
  }
}
