import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_style.dart';

/// Crossblade capsule: a glossy jewel case. Focus pops it forward with an
/// overshoot, rings it in neon green and sweeps a shine across it.
class CrossbladeGameCard extends StatelessWidget {
  const CrossbladeGameCard(this.config, {super.key, required this.art});

  final RsGameCard config;

  /// Draws the artwork (delegated to the base set's generator).
  final Widget Function(BuildContext context, RsGameArt art) art;

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
          duration: t.motion.page,
          curve: Curves.easeOutBack,
          child: AspectRatio(
            aspectRatio: layout.aspectRatio!,
            child: CrossbladePulse(
              active: hi,
              builder: (context, pulse) => AnimatedContainer(
                duration: t.motion.focus,
                curve: t.motion.curve,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: radius,
                  boxShadow: hi
                      ? CrossbladeStyle.glow(t, pulse: pulse)
                      : CrossbladeStyle.depth(t),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: hi ? t.focusRing : t.divider,
                    width: hi ? t.sizes.focusRingWidth : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: _body(context, t, hi),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(BuildContext context, RsTokens t, bool hi) {
    final layout = config.layout == RsArtLayout.background
        ? RsArtLayout.cover
        : config.layout;
    final hasImage = config.image != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        art(
          context,
          RsGameArt(
            title: config.title,
            systemId: config.systemId,
            systemName: config.systemName,
            image: config.image,
            layout: layout,
          ),
        ),
        // Jewel-case gloss: a hard reflection over the top half.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.42, 0.42, 1],
                colors: [
                  t.art.onArt.withValues(alpha: hi ? 0.2 : 0.1),
                  t.art.onArt.withValues(alpha: hi ? 0.05 : 0.02),
                  t.art.onArt.withValues(alpha: 0),
                  t.art.onArt.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        if (hi) _ShineSweep(key: const ValueKey('shine'), tokens: t),
        if (config.showSystemBadge &&
            hasImage &&
            (config.systemName ?? config.systemId) != null)
          Positioned(
            top: t.spacing.sm,
            left: t.spacing.sm,
            child: _SystemBlade(
              label: (config.systemId ?? config.systemName)!.toUpperCase(),
            ),
          ),
        if (config.installed)
          Positioned(
            right: t.spacing.sm,
            top: t.spacing.sm,
            child: Semantics(
              label: 'Installed',
              child: Container(
                padding: EdgeInsets.all(t.spacing.xs / 2 + 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CrossbladeStyle.gloss(t.success),
                  border: Border.all(color: t.art.onArt.withValues(alpha: 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: t.success.withValues(alpha: 0.7),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: t.sizes.iconSm,
                  color: t.onPlay,
                ),
              ),
            ),
          ),
        if (config.progress case final p?)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: t.sizes.progressHeight / 1.5,
              color: t.art.shade.withValues(alpha: 0.6),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: p.clamp(0, 1),
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: t.accent,
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withValues(alpha: 0.8),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A diagonal band of light that crosses the card once when it gains focus.
class _ShineSweep extends StatelessWidget {
  const _ShineSweep({super.key, required this.tokens});

  final RsTokens tokens;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.2, end: 1.6),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, x, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(x - 0.6, -1),
            end: Alignment(x + 0.6, 1),
            stops: const [0.35, 0.5, 0.65],
            colors: [
              tokens.art.onArt.withValues(alpha: 0),
              tokens.art.onArt.withValues(alpha: 0.32),
              tokens.art.onArt.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SystemBlade extends StatelessWidget {
  const _SystemBlade({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm + 2,
        vertical: t.spacing.xs / 2 + 1,
      ),
      decoration: ShapeDecoration(
        shape: const BladeBorder(slant: 6, radius: 2),
        gradient: CrossbladeStyle.gloss(t.focusSurface),
        shadows: [BoxShadow(color: t.shade(0.5), blurRadius: 6)],
      ),
      child: Text(
        label,
        style: CrossbladeStyle.text(context).labelSmall?.copyWith(
          color: t.onFocusSurface,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

extension on RsTokens {
  Color shade(double alpha) => art.shade.withValues(alpha: alpha);
}
