import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture text input: dark well at rest, lifted with a bright ring
/// while focused, red ring and message on error.
class SteamTextField extends StatefulWidget {
  const SteamTextField(this.config, {super.key});

  final RsTextField config;

  @override
  State<SteamTextField> createState() => _SteamTextFieldState();
}

class _SteamTextFieldState extends State<SteamTextField> {
  FocusNode? _ownNode;
  bool _focused = false;
  bool _hovered = false;
  bool _revealed = false;

  FocusNode get _node =>
      widget.config.focusNode ??
      (_ownNode ??= FocusNode(debugLabel: 'RsTextField'));

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(SteamTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.config.focusNode ?? _ownNode;
    if (old != _node) {
      old?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (_node.hasFocus != _focused) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final error = c.errorText;
    final hasError = error != null;
    final ringColor = hasError
        ? t.danger
        : _focused
        ? t.focusRing
        : t.focusRing.withValues(alpha: 0);
    final field = TextField(
      controller: c.controller,
      focusNode: _node,
      autofocus: c.autofocus,
      enabled: c.enabled,
      obscureText: c.obscure && !_revealed,
      enableSuggestions: !c.obscure,
      autocorrect: !c.obscure,
      onChanged: c.onChanged,
      onSubmitted: c.onSubmitted,
      keyboardType: c.keyboardType,
      textInputAction: c.textInputAction,
      autofillHints: c.autofillHints,
      maxLength: c.maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      cursorColor: t.accent,
      style: text.bodyLarge?.copyWith(color: t.textPrimary, height: 1.3),
      decoration: InputDecoration.collapsed(
        hintText: c.hint,
        hintStyle: text.bodyLarge?.copyWith(color: t.textMuted, height: 1.3),
      ).copyWith(counterText: ''),
    );

    return SteamSurface(
      child: Opacity(
        opacity: c.enabled ? 1 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.label != null) ...[
              AnimatedDefaultTextStyle(
                duration: t.motion.focus,
                style: (text.titleSmall ?? const TextStyle()).copyWith(
                  color: _focused ? t.textPrimary : t.textSecondary,
                ),
                child: Text(c.label!),
              ),
              SizedBox(height: t.spacing.sm),
            ],
            MouseRegion(
              cursor: SystemMouseCursors.text,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: AnimatedContainer(
                duration: t.motion.focus,
                curve: t.motion.curve,
                constraints: BoxConstraints(
                  minHeight: t.sizes.tabHeight + t.spacing.xs,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: t.spacing.md,
                  vertical: t.spacing.sm + t.spacing.xs / 2,
                ),
                decoration: BoxDecoration(
                  color: _focused
                      ? t.surfaceRaised
                      : _hovered
                      ? Color.lerp(t.surface, t.surfaceRaised, 0.5)
                      : t.surface,
                  borderRadius: BorderRadius.circular(t.radii.sm),
                  border: Border.all(
                    color: ringColor,
                    width: t.sizes.focusRingWidth,
                  ),
                  boxShadow: _focused && !hasError
                      ? SteamStyle.focusGlow(t, strength: 0.5)
                      : null,
                ),
                child: Row(
                  children: [
                    if (c.icon != null) ...[
                      Icon(
                        c.icon,
                        size: t.sizes.icon,
                        color: _focused ? t.textPrimary : t.textMuted,
                      ),
                      SizedBox(width: t.spacing.sm + t.spacing.xs),
                    ],
                    Expanded(child: field),
                    if (c.obscure)
                      SteamTapTarget(
                        onTap: () => setState(() => _revealed = !_revealed),
                        semanticLabel: _revealed
                            ? 'Hide password'
                            : 'Show password',
                        builder: (context, state) => Padding(
                          padding: EdgeInsets.only(left: t.spacing.sm),
                          child: Icon(
                            _revealed
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: t.sizes.icon,
                            color: state.hovered ? t.textPrimary : t.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: t.motion.focus,
              curve: t.motion.curve,
              alignment: Alignment.topLeft,
              child: error != null
                  ? Padding(
                      padding: EdgeInsets.only(top: t.spacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: t.sizes.iconSm,
                            color: t.danger,
                          ),
                          SizedBox(width: t.spacing.xs + 2),
                          Expanded(
                            child: Text(
                              error,
                              style: text.bodySmall?.copyWith(color: t.danger),
                            ),
                          ),
                        ],
                      ),
                    )
                  : c.helperText != null
                  ? Padding(
                      padding: EdgeInsets.only(top: t.spacing.sm),
                      child: Text(c.helperText!, style: text.bodySmall),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
