import 'package:flutter/widgets.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

/// Big Picture button: flat dark fill at rest, bright highlight when focused.
/// Primary buttons use the green "Play" gradient.
class SteamButton extends StatelessWidget {
  const SteamButton(this.config, {super.key});

  final RsButton config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: config.onPressed,
      semanticLabel: config.label,
      builder: (context, state) {
        final (fill, fg) = _colors(t, state);
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (config.icon != null) ...[
              Icon(config.icon, size: 20, color: fg),
              SizedBox(width: t.spacing.sm),
            ],
            Text(
              config.label,
              style: TextStyle(
                color: fg,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        );
        return AnimatedScale(
          scale: state.pressed ? 0.97 : 1,
          duration: t.motion.focus,
          curve: t.motion.curve,
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.lg,
              vertical: t.spacing.sm + t.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: fill is Color ? fill : null,
              gradient: fill is Gradient ? fill : null,
              borderRadius: BorderRadius.circular(t.radii.sm),
              boxShadow: state.highlighted
                  ? [
                      BoxShadow(
                        color: t.focusRing.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ]
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
              ? [Color.lerp(t.play, const Color(0xFFFFFFFF), 0.2)!, t.play]
              : [t.play, Color.lerp(t.play, const Color(0xFF000000), 0.25)!],
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
