import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture library capsule: grows and gets a bright ring and glow when focused.
class SteamTile extends StatelessWidget {
  const SteamTile(this.config, {super.key});

  final RsTile config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final radius = BorderRadius.circular(t.radii.sm);
    return RsFocusable(
      autofocus: config.autofocus,
      focusNode: config.focusNode,
      onActivate: config.onPressed,
      onFocusChanged: config.onFocusChanged,
      semanticLabel: config.title,
      builder: (context, state) => AnimatedScale(
        scale: state.highlighted ? t.motion.focusScale : 1,
        duration: t.motion.focus,
        curve: t.motion.curve,
        child: AspectRatio(
          aspectRatio: config.aspectRatio,
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: radius,
              border: Border.all(
                color: state.highlighted
                    ? t.focusRing
                    : t.focusRing.withValues(alpha: 0),
                width: t.sizes.focusRingWidth,
              ),
              boxShadow: state.highlighted
                  ? SteamStyle.focusGlow(t)
                  : SteamStyle.restShadow(t),
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: _Artwork(config: config, tokens: t),
            ),
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.config, required this.tokens});

  final RsTile config;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fallback = _TitleFallback(title: config.title, tokens: tokens);
    final image = config.image;
    if (image == null) return fallback;
    return Image(
      image: image,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (_, child, frame, sync) =>
          sync || frame != null ? child : fallback,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}

class _TitleFallback extends StatelessWidget {
  const _TitleFallback({required this.title, required this.tokens});

  final String? title;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => Container(
    color: tokens.surfaceRaised,
    padding: EdgeInsets.all(tokens.spacing.sm),
    alignment: Alignment.center,
    child: Text(
      title ?? '',
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: SteamStyle.text(context).titleSmall
          ?.copyWith(color: tokens.textSecondary),
    ),
  );
}
