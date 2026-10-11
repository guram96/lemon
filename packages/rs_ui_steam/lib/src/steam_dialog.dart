import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture modal panel.
class SteamDialog extends StatelessWidget {
  const SteamDialog(this.config, {super.key});

  final RsDialog config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final compact = context.rsLayout == RsLayoutClass.compact;
    final pad = compact ? t.spacing.lg : t.spacing.xl;
    final actions = config.actions;
    return SteamSurface(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(context.rsPageGutter),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: config.maxWidth ?? t.sizes.dialogMaxWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: SteamStyle.panelGradient(t),
                borderRadius: BorderRadius.circular(t.radii.md),
                border: Border.all(color: t.divider),
                boxShadow: SteamStyle.floatShadow(t),
              ),
              child: Padding(
                padding: EdgeInsets.all(pad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (config.icon != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(t.spacing.sm + t.spacing.xs),
                          decoration: BoxDecoration(
                            color: t.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(t.radii.md),
                          ),
                          child: Icon(
                            config.icon,
                            color: t.accent,
                            size: t.sizes.iconLg,
                          ),
                        ),
                      ),
                      SizedBox(height: t.spacing.md),
                    ],
                    if (config.title != null) ...[
                      Text(config.title!, style: text.headlineSmall),
                      SizedBox(height: t.spacing.sm + t.spacing.xs),
                    ],
                    Flexible(
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (config.message != null)
                              Text(
                                config.message!,
                                style: text.bodyLarge?.copyWith(
                                  color: t.textSecondary,
                                ),
                              ),
                            if (config.message != null &&
                                config.content != null)
                              SizedBox(height: t.spacing.md),
                            ?config.content,
                          ],
                        ),
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      SizedBox(height: t.spacing.lg),
                      if (compact)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, a) in actions.indexed) ...[
                              if (i > 0) SizedBox(height: t.spacing.sm),
                              a,
                            ],
                          ],
                        )
                      else
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: t.spacing.sm + t.spacing.xs,
                          runSpacing: t.spacing.sm,
                          children: actions,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + gentle zoom over the scrim, Big Picture style.
Route<T> steamDialogRoute<T>(
  BuildContext context,
  WidgetBuilder builder, {
  required bool dismissible,
}) {
  final t = context.rsTokens;
  return RawDialogRoute<T>(
    barrierDismissible: dismissible,
    barrierLabel: 'Dismiss',
    barrierColor: t.scrim,
    transitionDuration: t.motion.page,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: t.motion.emphasizedCurve,
        reverseCurve: t.motion.exitCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}
