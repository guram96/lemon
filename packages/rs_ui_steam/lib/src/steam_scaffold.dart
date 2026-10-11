import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture page frame over the gradient backdrop.
class SteamScaffold extends StatelessWidget {
  const SteamScaffold(this.config, {super.key});

  final RsScaffold config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final topBar = config.topBar;
    final hints = config.hints;
    final body = SafeArea(
      top: topBar == null && !config.extendBodyBehindTopBar,
      bottom: hints == null,
      child: config.body,
    );
    return SteamSurface(
      child: DecoratedBox(
        decoration: SteamStyle.pageBackground(t),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
