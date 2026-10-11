import 'package:flutter/widgets.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

/// Big Picture settings row: label and description on the left, pill switch
/// on the right; the whole row highlights when focused.
class SteamToggle extends StatelessWidget {
  const SteamToggle(this.config, {super.key});

  final RsToggle config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final onChanged = config.onChanged;
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: onChanged == null ? null : () => onChanged(!config.value),
      semanticLabel: config.label,
      builder: (context, state) => AnimatedContainer(
        duration: t.motion.focus,
        curve: t.motion.curve,
        padding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.md,
        ),
        decoration: BoxDecoration(
          color: state.highlighted ? t.surfaceRaised : const Color(0x00000000),
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
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (config.description != null) ...[
                      SizedBox(height: t.spacing.xs),
                      Text(
                        config.description!,
                        style: TextStyle(color: t.textMuted, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: t.spacing.md),
              _Switch(value: config.value, tokens: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.tokens});

  final bool value;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    const width = 44.0, height = 24.0, knob = 18.0;
    return AnimatedContainer(
      duration: t.motion.focus,
      curve: t.motion.curve,
      width: width,
      height: height,
      padding: const EdgeInsets.all((height - knob) / 2),
      decoration: BoxDecoration(
        color: value ? t.accent : t.surfaceRaised,
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
            color: t.textPrimary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
