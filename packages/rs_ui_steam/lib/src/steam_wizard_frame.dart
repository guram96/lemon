import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Steam Deck first-run (OOBE) frame: segmented step indicator, large title,
/// content column, and a footer bar with the actions.
class SteamWizardFrame extends StatelessWidget {
  const SteamWizardFrame(this.config, {super.key});

  final RsWizardFrame config;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final layout = context.rsLayout;
    final compact = layout == RsLayoutClass.compact;
    final gutter = context.rsPageGutter;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.icon != null) ...[
          Container(
            padding: EdgeInsets.all(t.spacing.sm + t.spacing.xs),
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(t.radii.md),
            ),
            child: Icon(c.icon, color: t.accent, size: t.sizes.iconLg),
          ),
          SizedBox(height: t.spacing.lg),
        ],
        Text(c.title, style: compact ? text.headlineMedium : text.displaySmall),
        if (c.subtitle != null) ...[
          SizedBox(height: t.spacing.sm + t.spacing.xs),
          Text(
            c.subtitle!,
            style: text.bodyLarge?.copyWith(color: t.textMuted),
          ),
        ],
        SizedBox(height: compact ? t.spacing.lg : t.spacing.xl),
      ],
    );

    final content = _StepEntrance(
      step: c.currentStep,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: c.scrollable ? MainAxisSize.min : MainAxisSize.max,
        children: [
          heading,
          if (c.scrollable) c.child else Expanded(child: c.child),
        ],
      ),
    );

    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.sizes.wizardMaxWidth),
        child: c.scrollable
            ? SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  t.spacing.lg,
                  gutter,
                  t.spacing.xl,
                ),
                child: content,
              )
            : Padding(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  t.spacing.lg,
                  gutter,
                  t.spacing.lg,
                ),
                child: content,
              ),
      ),
    );

    return SteamSurface(
      child: DecoratedBox(
        decoration: SteamStyle.pageBackground(t),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1.2),
              radius: 1.2,
              colors: [
                t.accent.withValues(alpha: 0.18),
                t.accent.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, t.spacing.lg, gutter, 0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: t.sizes.wizardMaxWidth - gutter * 2,
                      ),
                      child: c.steps.isEmpty
                          ? const SizedBox.shrink()
                          : _Steps(
                              steps: c.steps,
                              current: c.currentStep,
                              showLabels: !compact,
                            ),
                    ),
                  ),
                ),
              ),
              Expanded(child: body),
              _Footer(config: c, compact: compact),
            ],
          ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({
    required this.steps,
    required this.current,
    required this.showLabels,
  });

  final List<String> steps;
  final int current;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final index = current.clamp(0, steps.length - 1);
    return Semantics(
      label: 'Step ${index + 1} of ${steps.length}: ${steps[index]}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) SizedBox(width: t.spacing.xs + 2),
                  Expanded(
                    child: AnimatedContainer(
                      duration: t.motion.page,
                      curve: t.motion.curve,
                      height: t.spacing.xs,
                      decoration: BoxDecoration(
                        color: i < index
                            ? t.accent
                            : i == index
                            ? t.textPrimary
                            : t.track,
                        borderRadius: BorderRadius.circular(t.radii.pill),
                        boxShadow: i == index
                            ? SteamStyle.focusGlow(t, strength: 0.5)
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: t.spacing.sm),
            if (showLabels)
              Row(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    if (i > 0) SizedBox(width: t.spacing.xs + 2),
                    Expanded(
                      child: AnimatedDefaultTextStyle(
                        duration: t.motion.page,
                        style: (text.labelSmall ?? const TextStyle()).copyWith(
                          color: i == index
                              ? t.textPrimary
                              : i < index
                              ? t.textSecondary
                              : t.textMuted,
                        ),
                        child: Text(
                          '${i + 1}  ${steps[i].toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            else
              Text(
                'STEP ${index + 1} OF ${steps.length} · '
                '${steps[index].toUpperCase()}',
                style: text.labelSmall?.copyWith(color: t.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.config, required this.compact});

  final RsWizardFrame config;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = config;
    final t = context.rsTokens;
    final gutter = context.rsPageGutter;
    if (c.primaryAction == null &&
        c.secondaryAction == null &&
        c.extraActions.isEmpty) {
      return const SizedBox.shrink();
    }
    final gap = SizedBox(
      width: t.spacing.sm + t.spacing.xs,
      height: t.spacing.sm,
    );
    return Container(
      decoration: BoxDecoration(
        color: t.barBackground,
        border: Border(top: BorderSide(color: t.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: gutter,
            vertical: t.spacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: t.sizes.wizardMaxWidth - gutter * 2,
              ),
              child: compact
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ?c.primaryAction,
                        for (final a in c.extraActions) ...[gap, a],
                        if (c.secondaryAction != null) ...[
                          gap,
                          c.secondaryAction!,
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        ?c.secondaryAction,
                        const Spacer(),
                        for (final a in c.extraActions) ...[a, gap],
                        ?c.primaryAction,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts the content in when the step changes, without
/// rebuilding the child (so form state and focus nodes survive).
class _StepEntrance extends StatefulWidget {
  const _StepEntrance({required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  State<_StepEntrance> createState() => _StepEntranceState();
}

class _StepEntranceState extends State<_StepEntrance>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = context.rsTokens;
    _controller ??= AnimationController(
      vsync: this,
      duration: t.motion.page,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(_StepEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) _controller!.forward(from: 0);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final curved = CurvedAnimation(
      parent: _controller!,
      curve: t.motion.emphasizedCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
