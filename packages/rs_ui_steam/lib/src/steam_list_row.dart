import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';
import 'steam_toggle.dart';

/// Big Picture settings row. Focus fills it with the light highlight and
/// flips its content to dark; inactive rows get a softer highlight.
class SteamListRow extends StatelessWidget {
  const SteamListRow(this.config, {super.key});

  final RsListRow config;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
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
            ? t.onFocusSurface.withValues(alpha: 0.7)
            : t.textMuted;
        return AnimatedContainer(
          duration: t.motion.focus,
          curve: t.motion.curve,
          constraints: BoxConstraints(minHeight: t.sizes.rowMinHeight),
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.md,
            vertical: t.spacing.sm + t.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: bright
                ? t.focusSurface
                : soft
                ? t.surfaceRaised
                : t.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(t.radii.sm),
            border: Border(
              bottom: BorderSide(
                color: bright || soft
                    ? t.divider.withValues(alpha: 0)
                    : t.divider,
              ),
            ),
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
                  color: bright ? fg : t.textSecondary,
                ),
                SizedBox(width: t.spacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.title, style: text.titleMedium?.copyWith(color: fg)),
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
                Text(c.value!, style: text.bodyMedium?.copyWith(color: muted)),
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
                SteamSwitch(value: c.switchValue!),
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
        );
      },
    );
  }
}
