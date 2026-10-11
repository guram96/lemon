import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_progress.dart';
import 'steam_style.dart';

/// Big Picture notification card.
class SteamToast extends StatelessWidget {
  const SteamToast(this.config, {super.key});

  final RsToast config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    final media = t.sizes.iconLg + t.spacing.md;
    final Widget leading;
    if (config.image case final image?) {
      leading = ClipRRect(
        borderRadius: BorderRadius.circular(t.radii.sm),
        child: Image(
          image: image,
          width: media,
          height: media,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SizedBox.square(dimension: media),
        ),
      );
    } else {
      leading = Container(
        width: media,
        height: media,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.accent, Color.lerp(t.accent, t.art.shade, 0.35)!],
          ),
          borderRadius: BorderRadius.circular(t.radii.sm),
        ),
        child: Icon(
          config.icon ?? Icons.notifications_rounded,
          color: t.onAccent,
          size: t.sizes.icon + 2,
        ),
      );
    }
    final showBar = config.progress != null || config.indeterminate;
    final width = MediaQuery.sizeOf(context).width - context.rsPageGutter * 2;
    return SteamTapTarget(
      onTap: config.onPressed,
      semanticLabel: config.title,
      builder: (context, state) => AnimatedContainer(
        duration: t.motion.fast,
        width: width.clamp(0, t.sizes.toastWidth),
        padding: EdgeInsets.all(t.spacing.sm + t.spacing.xs),
        decoration: BoxDecoration(
          gradient: SteamStyle.panelGradient(t),
          borderRadius: BorderRadius.circular(t.radii.md),
          border: Border.all(
            color: state.hovered && config.onPressed != null
                ? t.focusRing.withValues(alpha: 0.4)
                : t.divider,
          ),
          boxShadow: SteamStyle.floatShadow(t),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            SizedBox(width: t.spacing.sm + t.spacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (config.body != null) ...[
                    SizedBox(height: t.spacing.xs / 2),
                    Text(
                      config.body!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                  if (showBar) ...[
                    SizedBox(height: t.spacing.sm),
                    SteamBar(
                      value: config.progress,
                      height: t.sizes.progressHeight * 0.7,
                    ),
                  ],
                ],
              ),
            ),
            if (config.onDismiss != null)
              SteamTapTarget(
                onTap: config.onDismiss,
                semanticLabel: 'Dismiss',
                builder: (context, s) => Padding(
                  padding: EdgeInsets.only(left: t.spacing.sm),
                  child: Icon(
                    Icons.close_rounded,
                    size: t.sizes.iconSm + 2,
                    color: s.hovered ? t.textPrimary : t.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-right toast column. New toasts slide in from the right; removed
/// ones fade out and collapse.
class SteamToastStack extends StatefulWidget {
  const SteamToastStack(this.config, {super.key});

  final RsToastStack config;

  @override
  State<SteamToastStack> createState() => _SteamToastStackState();
}

class _Entry {
  _Entry(this.key, this.toast, this.controller);

  final Key key;
  RsToast toast;
  final AnimationController controller;
  bool leaving = false;
}

class _SteamToastStackState extends State<SteamToastStack>
    with TickerProviderStateMixin {
  final _entries = <_Entry>[];
  bool _initialized = false;

  Key _keyOf(RsToast toast, int index) => toast.key ?? ValueKey(index);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _sync(animateIn: true);
    }
  }

  @override
  void didUpdateWidget(SteamToastStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(animateIn: true);
  }

  void _sync({required bool animateIn}) {
    final t = context.rsTokens;
    final incoming = <Key, RsToast>{
      for (final (i, toast) in widget.config.toasts.indexed)
        _keyOf(toast, i): toast,
    };
    // Leave: entries no longer present.
    for (final e in _entries) {
      if (!incoming.containsKey(e.key) && !e.leaving) {
        e.leaving = true;
        e.controller.reverse().whenComplete(() {
          if (!mounted) return;
          setState(() {
            _entries.remove(e);
            e.controller.dispose();
          });
        });
      }
    }
    // Update / enter, keeping the incoming order.
    var insertAt = 0;
    for (final MapEntry(:key, value: toast) in incoming.entries) {
      final existing = _entries.where((e) => e.key == key).firstOrNull;
      if (existing != null) {
        existing.toast = toast;
        if (existing.leaving) {
          existing.leaving = false;
          existing.controller.forward();
        }
        insertAt = _entries.indexOf(existing) + 1;
      } else {
        final controller = AnimationController(
          vsync: this,
          duration: t.motion.page,
          reverseDuration: t.motion.page,
        );
        _entries.insert(
          insertAt.clamp(0, _entries.length),
          _Entry(key, toast, controller),
        );
        insertAt++;
        if (animateIn) {
          controller.forward();
        } else {
          controller.value = 1;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final gutter = context.rsPageGutter;
    return SteamSurface(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              gutter,
              gutter,
              gutter,
              t.sizes.hintBar + t.spacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final e in _entries)
                  KeyedSubtree(
                    key: ObjectKey(e),
                    child: _Animated(entry: e, tokens: t),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Animated extends StatelessWidget {
  const _Animated({required this.entry, required this.tokens});

  final _Entry entry;
  final RsTokens tokens;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: entry.controller,
      curve: tokens.motion.emphasizedCurve,
      reverseCurve: tokens.motion.exitCurve,
    );
    return SizeTransition(
      sizeFactor: curved,
      alignment: Alignment.bottomRight,
      fixedCrossAxisSizeFactor: 1,
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.6, 0),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: EdgeInsets.only(
              top: tokens.spacing.sm + tokens.spacing.xs,
            ),
            child: entry.toast,
          ),
        ),
      ),
    );
  }
}
