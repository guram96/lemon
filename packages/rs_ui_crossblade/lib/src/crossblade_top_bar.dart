import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'crossblade_style.dart';

/// Crossblade top bar: the green jewel and wordmark, then the nav as
/// slanted Xbox 360 blades. Right side: an XMB-style date and clock, the
/// bell and the avatar ring.
class CrossbladeTopBar extends StatelessWidget {
  const CrossbladeTopBar(this.config, {super.key});

  final RsTopBar config;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final compact = context.rsLayout == RsLayoutClass.compact;
    final gutter = context.rsPageGutter;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            t.background,
            t.background.withValues(alpha: 0.88),
            t.background.withValues(alpha: 0),
          ],
          stops: const [0, 0.72, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: t.sizes.topBar,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: LayoutBuilder(
              builder: (context, box) => Row(
                children: [
                  // The jewel needs room; narrow bars keep just the nav.
                  if (box.maxWidth >= 640) ...[
                    _Brand(wordmark: box.maxWidth >= 900),
                    SizedBox(width: t.spacing.lg),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      padding: EdgeInsets.symmetric(vertical: t.spacing.sm),
                      child: Row(
                        children: [
                          for (var i = 0; i < config.items.length; i++)
                            _Blade(
                              item: config.items[i],
                              selected: i == config.selectedIndex,
                              iconOnly: compact && config.items[i].icon != null,
                              onPressed: () => config.onSelected(i),
                            ),
                        ],
                      ),
                    ),
                  ),
                  ...config.trailing,
                  if (config.showClock && !compact) const _Clock(),
                  if (config.onNotifications != null)
                    _Bell(
                      count: config.notificationCount,
                      onPressed: config.onNotifications!,
                    ),
                  if (config.userName != null || config.avatar != null)
                    _Avatar(
                      name: config.userName ?? '',
                      image: config.avatar,
                      onPressed: config.onAvatar,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.wordmark});

  /// Whether to show "RETRO STEAM" next to the jewel.
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    final orb = CrossbladePulse(
      active: true,
      period: const Duration(milliseconds: 2600),
      builder: (context, pulse) =>
          CrossbladeOrb(size: t.sizes.avatar, glow: 0.6 + pulse * 0.4),
    );
    if (!wordmark) return ExcludeSemantics(child: orb);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          orb,
          SizedBox(width: t.spacing.sm + t.spacing.xs),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RETRO',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 3,
                  height: 1,
                  color: t.textPrimary,
                ),
              ),
              Text(
                'STEAM',
                style: text.labelSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  letterSpacing: 5.4,
                  height: 1.2,
                  color: t.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Blade extends StatelessWidget {
  const _Blade({
    required this.item,
    required this.selected,
    required this.iconOnly,
    required this.onPressed,
  });

  final RsNavItem item;
  final bool selected;
  final bool iconOnly;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    final slant = t.sizes.tabHeight * 0.32;
    return Padding(
      padding: EdgeInsets.only(right: t.spacing.xs + 2),
      child: RsFocusable(
        onActivate: onPressed,
        semanticLabel: item.label,
        builder: (context, state) {
          final hi = state.highlighted;
          final fg = selected
              ? t.onFocusSurface
              : hi
              ? t.textPrimary
              : t.textMuted;
          final shape = BladeBorder(
            slant: slant,
            radius: t.radii.sm,
            side: BorderSide(
              color: hi
                  ? t.focusRing
                  : selected
                  ? t.focusRing.withValues(alpha: 0.6)
                  : t.divider,
              width: hi ? t.sizes.focusRingWidth : 1,
            ),
          );
          return AnimatedScale(
            scale: state.pressed
                ? t.motion.pressScale
                : hi
                ? 1.05
                : 1,
            duration: t.motion.focus,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: t.motion.focus,
              curve: t.motion.curve,
              height: t.sizes.tabHeight - t.spacing.xs,
              padding: EdgeInsets.symmetric(
                horizontal: t.spacing.lg + slant / 2,
              ),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: shape,
                gradient: selected
                    ? CrossbladeStyle.gloss(t.focusSurface)
                    : hi
                    ? CrossbladeStyle.gloss(t.surfaceRaised, shine: 0.18)
                    : CrossbladeStyle.glass(t),
                shadows: hi || selected
                    ? CrossbladeStyle.glow(t, strength: hi ? 0.8 : 0.45)
                    : const [],
              ),
              child: iconOnly
                  ? Icon(item.icon, color: fg, size: t.sizes.icon + 2)
                  : Text(
                      item.label,
                      style: text.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.6,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    final now = DateTime.now();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: 1));
    _timer = Timer(next.difference(now), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final m = _now.minute.toString().padLeft(2, '0');
    final String time;
    String? suffix;
    if (use24h) {
      time = '${_now.hour.toString().padLeft(2, '0')}:$m';
    } else {
      final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
      time = '$h:$m';
      suffix = _now.hour < 12 ? 'AM' : 'PM';
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${_now.day} ${_months[_now.month - 1]}',
            style: text.labelSmall?.copyWith(color: t.textMuted, height: 1),
          ),
          SizedBox(height: t.spacing.xs / 2),
          Text.rich(
            TextSpan(
              text: time,
              children: [
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: text.labelSmall?.copyWith(color: t.accent),
                  ),
              ],
            ),
            style: text.titleLarge?.copyWith(
              color: t.textPrimary,
              fontWeight: FontWeight.w300,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round glass button used by the bell.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.onPressed,
    required this.semanticLabel,
    required this.builder,
  });

  final VoidCallback? onPressed;
  final String semanticLabel;
  final Widget Function(BuildContext context, bool highlighted) builder;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final d = t.sizes.avatar + 4;
    return RsFocusable(
      onActivate: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        final hi = state.highlighted;
        return AnimatedScale(
          scale: hi ? 1.1 : 1,
          duration: t.motion.focus,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            width: d,
            height: d,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hi
                  ? CrossbladeStyle.gloss(t.focusSurface)
                  : CrossbladeStyle.glass(t),
              border: Border.all(
                color: hi ? t.focusRing : t.divider,
                width: hi ? t.sizes.focusRingWidth : 1,
              ),
              boxShadow: hi ? CrossbladeStyle.glow(t, strength: 0.7) : null,
            ),
            child: builder(context, hi),
          ),
        );
      },
    );
  }
}

class _Bell extends StatelessWidget {
  const _Bell({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    return Padding(
      padding: EdgeInsets.only(right: t.spacing.sm + t.spacing.xs),
      child: _RoundButton(
        onPressed: onPressed,
        semanticLabel: count > 0
            ? 'Notifications, $count unread'
            : 'Notifications',
        builder: (context, hi) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              count > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              size: t.sizes.icon + 2,
              color: hi ? t.onFocusSurface : t.textSecondary,
            ),
            if (count > 0)
              Positioned(
                top: -t.spacing.xs,
                right: -t.spacing.xs,
                child: Container(
                  constraints: BoxConstraints(minWidth: t.sizes.iconSm + 4),
                  padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
                  height: t.sizes.iconSm + 4,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: CrossbladeStyle.gloss(t.danger),
                    borderRadius: BorderRadius.circular(t.radii.pill),
                    boxShadow: [
                      BoxShadow(
                        color: t.danger.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: text.labelSmall?.copyWith(
                      color: t.onPlay,
                      letterSpacing: 0,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.image,
    required this.onPressed,
  });

  final String name;
  final ImageProvider? image;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = CrossbladeStyle.text(context);
    final d = t.sizes.avatar + 4;
    final initials = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: CrossbladeStyle.gloss(const Color(0xFF2F6BFF)),
      ),
      child: Text(
        _initials(name),
        style: text.titleSmall?.copyWith(
          color: t.art.onArt,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          height: 1,
        ),
      ),
    );
    return RsFocusable(
      onActivate: onPressed,
      semanticLabel: name.isEmpty ? 'Account' : name,
      builder: (context, state) {
        final hi = state.focused || state.hovered;
        return AnimatedScale(
          scale: hi ? 1.1 : 1,
          duration: t.motion.focus,
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            width: d,
            height: d,
            padding: EdgeInsets.all(t.sizes.focusRingWidth),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  t.focusSurface,
                  const Color(0xFF2F6BFF),
                  t.focusSurface,
                ],
              ),
              boxShadow: hi ? CrossbladeStyle.glow(t, strength: 0.8) : null,
            ),
            child: ClipOval(
              child: image == null
                  ? initials
                  : Image(
                      image: image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => initials,
                    ),
            ),
          ),
        );
      },
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }
}
