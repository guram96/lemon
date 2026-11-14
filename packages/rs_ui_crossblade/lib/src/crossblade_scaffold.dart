import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_backdrop.dart';
import 'crossblade_style.dart';

/// Crossblade page frame over the animated XMB backdrop. The hint bar sits
/// on a glass strip with a glowing top edge.
class CrossbladeScaffold extends StatelessWidget {
  const CrossbladeScaffold(this.config, {super.key});

  final RsScaffold config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final topBar = config.topBar;
    final hints = config.hints == null
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.barBackground.withValues(alpha: 0), t.barBackground],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CrossbladeEdge(color: t.accent),
                config.hints!,
              ],
            ),
          );
    final body = SafeArea(
      top: topBar == null && !config.extendBodyBehindTopBar,
      bottom: hints == null,
      child: config.body,
    );
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: CrossbladeStyle.text(context).bodyMedium ?? const TextStyle(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: CrossbladeBackdrop()),
            if (config.background case final background?)
              Positioned.fill(child: background),
            if (config.extendBodyBehindTopBar) ...[
              Column(
                children: [
                  Expanded(child: body),
                  ?hints,
                ],
              ),
              if (topBar != null)
                Positioned(top: 0, left: 0, right: 0, child: topBar),
            ] else
              Column(
                children: [
                  ?topBar,
                  Expanded(child: body),
                  ?hints,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A hairline that glows in the middle and fades out at both ends.
class CrossbladeEdge extends StatelessWidget {
  const CrossbladeEdge({super.key, required this.color, this.height = 1.5});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.9),
          color.withValues(alpha: 0),
        ],
      ),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
      ],
    ),
  );
}
