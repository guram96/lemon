import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_game_art.dart';
import 'steam_style.dart';

/// Big Picture capsule: flat art at rest; when focused it scales up, gets a
/// thin bright ring, a soft glow and a light sheen across the art.
class SteamGameCard extends StatelessWidget {
  const SteamGameCard(this.config, {super.key});

  final RsGameCard config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final radius = BorderRadius.circular(t.radii.md);
    final layout = config.layout == RsArtLayout.background
        ? RsArtLayout.cover
        : config.layout;
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: config.onPressed,
      onFocusChanged: config.onFocusChanged,
      semanticLabel: config.title,
      builder: (context, state) {
        final hi = state.highlighted;
        return AnimatedScale(
          scale: state.pressed
              ? t.motion.pressScale
              : hi
              ? t.motion.focusScale
              : 1,
          duration: t.motion.focus,
          curve: t.motion.curve,
          child: AspectRatio(
            aspectRatio: layout.aspectRatio!,
            child: AnimatedContainer(
              duration: t.motion.focus,
              curve: t.motion.curve,
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: radius,
                boxShadow: hi
                    ? SteamStyle.focusGlow(t)
                    : SteamStyle.restShadow(t),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: hi ? t.focusRing : t.focusRing.withValues(alpha: 0),
                  width: t.sizes.focusRingWidth,
                ),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SteamGameArt(
                      RsGameArt(
                        title: config.title,
                        systemId: config.systemId,
                        systemName: config.systemName,
                        image: config.image,
                        layout: layout,
                      ),
                    ),
                    _Sheen(visible: hi, tokens: t),
                    // Generated art already names the system.
                    if (config.showSystemBadge &&
                        config.image != null &&
                        (config.systemName ?? config.systemId) != null)
                      Positioned(
                        top: t.spacing.sm,
                        right: t.spacing.sm,
                        child: _Chip(
                          label: (config.systemId ?? config.systemName)!
                              .toUpperCase(),
                          tokens: t,
                        ),
                      ),
                    if (config.installed)
                      Positioned(
                        right: t.spacing.sm,
                        bottom:
                            t.spacing.sm +
                            (config.progress != null
                                ? t.sizes.progressHeight
                                : 0),
                        child: _InstalledBadge(tokens: t),
                      ),
                    if (config.progress case final p?)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _Progress(value: p, tokens: t),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Sheen extends StatelessWidget {
  const _Sheen({required this.visible, required this.tokens});

  final bool visible;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: tokens.motion.focus,
      curve: tokens.motion.curve,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, 0.45, 1],
            colors: [
              tokens.art.onArt.withValues(alpha: 0.16),
              tokens.art.onArt.withValues(alpha: 0),
              tokens.art.onArt.withValues(alpha: 0.04),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.tokens});

  final String label;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: tokens.spacing.xs + 2,
      vertical: tokens.spacing.xs / 2,
    ),
    decoration: BoxDecoration(
      color: tokens.art.shade.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(tokens.radii.sm),
    ),
    child: Text(
      label,
      style: SteamStyle.text(context).labelSmall
          ?.copyWith(color: tokens.art.onArt),
    ),
  );
}

class _InstalledBadge extends StatelessWidget {
  const _InstalledBadge({required this.tokens});

  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Installed',
    child: Container(
      padding: EdgeInsets.all(tokens.spacing.xs / 2 + 1),
      decoration: BoxDecoration(
        color: tokens.success,
        shape: BoxShape.circle,
        boxShadow: SteamStyle.restShadow(tokens),
      ),
      child: Icon(
        Icons.check_rounded,
        size: tokens.sizes.iconSm,
        color: tokens.onPlay,
      ),
    ),
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.tokens});

  final double value;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
    height: tokens.sizes.progressHeight / 1.5,
    color: tokens.art.shade.withValues(alpha: 0.6),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: value.clamp(0, 1),
      heightFactor: 1,
      child: ColoredBox(color: tokens.accent),
    ),
  );
}
