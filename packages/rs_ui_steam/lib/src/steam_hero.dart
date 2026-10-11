import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_game_art.dart';
import 'steam_style.dart';

/// Big Picture game page header: wide art fading into the page, logo or
/// title at the bottom left.
class SteamHero extends StatelessWidget {
  const SteamHero(this.config, {super.key});

  final RsHero config;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final layout = context.rsLayout;
    final gutter = context.rsPageGutter;
    final screen = MediaQuery.sizeOf(context);
    final scale = t.breakpoints.scaleFor(layout);
    final height =
        c.height ??
        (screen.height * 0.55).clamp(
          t.sizes.heroHeight * 0.6,
          t.sizes.heroHeight * scale,
        );
    final titleStyle = switch (layout) {
      RsLayoutClass.compact => text.headlineLarge,
      RsLayoutClass.medium => text.displaySmall,
      RsLayoutClass.expanded => text.displayMedium,
      RsLayoutClass.large => text.displayLarge,
    };
    final shadows = [
      Shadow(color: t.art.shade.withValues(alpha: 0.5), blurRadius: 16),
    ];
    final titleText = Text(
      c.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: titleStyle?.copyWith(shadows: shadows),
    );
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The art fades out through an alpha mask, so it blends into
          // whatever page background is behind it.
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.45, 1],
              colors: [t.art.shade, t.art.shade.withValues(alpha: 0)],
            ).createShader(bounds),
            child: SteamGameArt(
              RsGameArt(
                title: c.title,
                systemId: c.systemId,
                systemName: c.systemName,
                image: c.image,
                layout: RsArtLayout.background,
              ),
            ),
          ),
          // Side scrim for title legibility.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0, 0.6],
                colors: [
                  t.background.withValues(alpha: 0.6),
                  t.background.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          Positioned(
            left: gutter,
            right: gutter,
            bottom: t.spacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (c.logo case final logo?)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: height * 0.35,
                      maxWidth: screen.width * 0.5,
                    ),
                    child: Image(
                      image: logo,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomLeft,
                      errorBuilder: (_, _, _) => titleText,
                    ),
                  )
                else
                  titleText,
                if (c.subtitle != null) ...[
                  SizedBox(height: t.spacing.sm),
                  Text(
                    c.subtitle!,
                    style: text.titleMedium?.copyWith(
                      color: t.textSecondary,
                      shadows: shadows,
                    ),
                  ),
                ],
                if (c.child != null) ...[
                  SizedBox(height: t.spacing.lg),
                  c.child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
