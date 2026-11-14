import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_style.dart';

/// Settings row. At rest it's a faint glass line; focus turns it into a lit
/// green blade with a white edge on the left.
class CrossbladeListRow extends StatelessWidget {
  const CrossbladeListRow(this.config, {super.key});

  final RsListRow config;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    return RsFocusable(
      autofocus: c.autofocus,
      focusNode: c.focusNode,
      onActivate: c.onPressed,
      onFocusChanged: c.onFocusChanged,
      semanticLabel: c.title,
      builder: (context, state) {
        final active = state.enabled;
        final bright = active && (state.focused || state.hovered);
        final soft = !active && state.focused;
        final fg = bright ? t.onFocusSurface : t.textPrimary;
        final muted = bright
            ? t.onFocusSurface.withValues(alpha: 0.72)
            : t.textMuted;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            constraints: BoxConstraints(minHeight: t.sizes.rowMinHeight),
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.md + 2,
              vertical: t.spacing.sm + t.spacing.xs,
            ),
            decoration: BoxDecoration(
              gradient: bright
                  ? CrossbladeStyle.gloss(t.focusSurface, shine: 0.28)
                  : soft
                  ? CrossbladeStyle.glass(t)
                  : null,
              color: bright || soft ? null : t.surface.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(t.radii.md),
              border: Border(
                left: BorderSide(
                  color: bright ? t.focusRing : t.divider.withValues(alpha: 0),
                  width: t.spacing.xs,
                ),
              ),
              boxShadow: bright
                  ? CrossbladeStyle.glow(t, strength: 0.45)
                  : null,
            ),
            child: Row(
              children: [
                if (c.leading != null) ...[
                  c.leading!,
                  SizedBox(width: t.spacing.md),
                ] else if (c.icon != null) ...[
                  Icon(
                    c.icon,
                    size: t.sizes.iconLg - 4,
                    color: bright ? fg : t.accent,
                  ),
                  SizedBox(width: t.spacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        c.title,
                        style: text.titleMedium?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (c.subtitle != null) ...[
                        SizedBox(height: t.spacing.xs / 2),
                        Text(
                          c.subtitle!,
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (c.value != null) ...[
                  SizedBox(width: t.spacing.md),
                  Text(
                    c.value!,
                    style: text.bodyMedium?.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (c.trailing != null) ...[
                  SizedBox(width: t.spacing.md),
                  IconTheme.merge(
                    data: IconThemeData(color: muted),
                    child: c.trailing!,
                  ),
                ],
                if (c.switchValue != null) ...[
                  SizedBox(width: t.spacing.md),
                  CrossbladeSwitch(value: c.switchValue!, onLit: bright),
                ],
                if (c.chevron) ...[
                  SizedBox(width: t.spacing.sm),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: t.sizes.icon + 4,
                    color: muted,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Pill track with a glossy orb knob that lights green when on.
class CrossbladeSwitch extends StatelessWidget {
  const CrossbladeSwitch({super.key, required this.value, this.onLit = false});

  final bool value;

  /// Whether the switch sits on a lit (green) row.
  final bool onLit;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final h = t.sizes.icon + 6;
    final w = h * 1.9;
    final knob = h - 6;
    final on = onLit ? t.onFocusSurface : t.focusSurface;
    return Semantics(
      toggled: value,
      child: AnimatedContainer(
        duration: t.motion.focus,
        curve: t.motion.curve,
        width: w,
        height: h,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(t.radii.pill),
          color: value ? on.withValues(alpha: 0.28) : t.track,
          border: Border.all(
            color: value ? on.withValues(alpha: 0.7) : t.divider,
          ),
        ),
        child: AnimatedAlign(
          duration: t.motion.focus,
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knob,
            height: knob,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: value
                    ? [Color.lerp(on, Colors.white, 0.6)!, on]
                    : [t.textSecondary, t.textMuted],
              ),
              boxShadow: value
                  ? [BoxShadow(color: on.withValues(alpha: 0.7), blurRadius: 8)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
