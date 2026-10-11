import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture settings row: label and description on the left, pill switch
/// on the right; the whole row highlights when focused.
class SteamToggle extends StatelessWidget {
  const SteamToggle(this.config, {super.key});

  final RsToggle config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final onChanged = config.onChanged;
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: onChanged == null ? null : () => onChanged(!config.value),
      semanticLabel: config.label,
      builder: (context, state) {
        final hi = state.highlighted;
        final fg = hi ? t.onFocusSurface : t.textPrimary;
        return AnimatedContainer(
          duration: t.motion.focus,
          curve: t.motion.curve,
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.md,
            vertical: t.spacing.md,
          ),
          decoration: BoxDecoration(
            color: hi ? t.focusSurface : t.focusSurface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(t.radii.sm),
          ),
          child: Opacity(
            opacity: state.enabled ? 1 : 0.4,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.label,
                        style: text.titleMedium?.copyWith(color: fg),
                      ),
                      if (config.description != null) ...[
                        SizedBox(height: t.spacing.xs),
                        Text(
                          config.description!,
                          style: text.bodySmall?.copyWith(
                            color: hi
                                ? t.onFocusSurface.withValues(alpha: 0.7)
                                : t.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: t.spacing.md),
                SteamSwitch(value: config.value),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The pill switch drawn by toggles and list rows.
class SteamSwitch extends StatelessWidget {
  const SteamSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final height = t.sizes.icon + t.spacing.xs;
    final knob = height - t.spacing.xs - 2;
    return AnimatedContainer(
      duration: t.motion.focus,
      curve: t.motion.curve,
      width: height * 1.85,
      height: height,
      padding: EdgeInsets.all((height - knob) / 2),
      decoration: BoxDecoration(
        color: value ? t.accent : t.track,
        borderRadius: BorderRadius.circular(t.radii.pill),
        border: Border.all(color: t.divider),
      ),
      child: AnimatedAlign(
        duration: t.motion.focus,
        curve: t.motion.curve,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: knob,
          height: knob,
          decoration: BoxDecoration(
            color: value ? t.onAccent : t.textMuted,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: t.shadow, blurRadius: t.spacing.xs)],
          ),
        ),
      ),
    );
  }
}
