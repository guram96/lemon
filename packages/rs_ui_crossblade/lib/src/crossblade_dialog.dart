import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_scaffold.dart';
import 'crossblade_style.dart';

/// Crossblade modal: a glass slab with a glowing top edge and a jewel icon.
class CrossbladeDialog extends StatelessWidget {
  const CrossbladeDialog(this.config, {super.key});

  final RsDialog config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    final compact = context.rsLayout == RsLayoutClass.compact;
    final pad = compact ? t.spacing.lg : t.spacing.xl;
    final actions = config.actions;
    final radius = BorderRadius.circular(t.radii.lg);
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: text.bodyMedium ?? const TextStyle(),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(context.rsPageGutter),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: config.maxWidth ?? t.sizes.dialogMaxWidth,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(t.surfaceRaised, t.focusSurface, 0.08)!,
                      t.surfaceRaised,
                      Color.lerp(t.surfaceRaised, t.background, 0.4)!,
                    ],
                  ),
                  borderRadius: radius,
                  border: Border.all(color: t.divider),
                  boxShadow: [
                    ...CrossbladeStyle.depth(t, scale: 2),
                    BoxShadow(
                      color: t.focusGlow.withValues(alpha: 0.18),
                      blurRadius: t.spacing.xxl,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CrossbladeEdge(color: t.focusSurface, height: 2),
                      Flexible(
                        child: Padding(
                          padding: EdgeInsets.all(pad),
                          child: _content(context, t, text, compact, actions),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    RsTokens t,
    TextTheme text,
    bool compact,
    List<Widget> actions,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (config.icon != null || config.title != null)
        Row(
          children: [
            if (config.icon != null) ...[
              Container(
                width: t.sizes.iconLg + t.spacing.md,
                height: t.sizes.iconLg + t.spacing.md,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CrossbladeStyle.gloss(t.focusSurface),
                  boxShadow: CrossbladeStyle.glow(t, strength: 0.5),
                ),
                child: Icon(
                  config.icon,
                  color: t.onFocusSurface,
                  size: t.sizes.iconLg - 4,
                ),
              ),
              SizedBox(width: t.spacing.md),
            ],
            if (config.title != null)
              Expanded(child: Text(config.title!, style: text.headlineSmall)),
          ],
        ),
      if (config.icon != null || config.title != null)
        SizedBox(height: t.spacing.md),
      Flexible(
        child: SingleChildScrollView(
          clipBehavior: Clip.none,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (config.message != null)
                Text(
                  config.message!,
                  style: text.bodyLarge?.copyWith(color: t.textSecondary),
                ),
              if (config.message != null && config.content != null)
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
  );
}

/// Pops the dialog in from slightly small with an overshoot, over the scrim.
Route<T> crossbladeDialogRoute<T>(
  BuildContext context,
  WidgetBuilder builder, {
  required bool dismissible,
}) {
  final t = context.rsTokens;
  return RawDialogRoute<T>(
    barrierDismissible: dismissible,
    barrierLabel: 'Dismiss',
    barrierColor: t.scrim,
    transitionDuration: t.motion.slow,
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
        reverseCurve: t.motion.exitCurve,
      );
      final pop = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: t.motion.exitCurve,
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(pop),
          child: child,
        ),
      );
    },
  );
}
