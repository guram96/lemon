import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_game_art.dart';
import 'steam_style.dart';

/// Big Picture top bar: nav items left; clock, bell and avatar right, over
/// a fade from the page background so hero art can show through.
class SteamTopBar extends StatelessWidget {
  const SteamTopBar(this.config, {super.key});

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
            t.background.withValues(alpha: 0.92),
            t.background.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: t.sizes.topBar,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: [
                        for (var i = 0; i < config.items.length; i++)
                          _NavItem(
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
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
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
    final text = SteamStyle.text(context);
    return Padding(
      padding: EdgeInsets.only(right: t.spacing.xs),
      child: RsFocusable(
        onActivate: onPressed,
        semanticLabel: item.label,
        builder: (context, state) {
          final hi = state.highlighted;
          final fg = hi
              ? t.onFocusSurface
              : selected
              ? t.textPrimary
              : t.textMuted;
          return AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            height: t.sizes.tabHeight - t.spacing.xs,
            padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
            decoration: BoxDecoration(
              color: hi ? t.focusSurface : t.focusSurface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(t.radii.sm),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (iconOnly)
                  Icon(item.icon, color: fg, size: t.sizes.icon + 2)
                else
                  AnimatedDefaultTextStyle(
                    duration: t.motion.focus,
                    style: (text.titleMedium ?? const TextStyle()).copyWith(
                      color: fg,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                    child: Text(item.label),
                  ),
                Positioned(
                  bottom: t.spacing.xs / 2,
                  child: AnimatedContainer(
                    duration: t.motion.focus,
                    curve: t.motion.curve,
                    height: t.spacing.xs - 1,
                    width: selected && !hi ? t.spacing.lg : 0,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(t.radii.pill),
                    ),
                  ),
                ),
              ],
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
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final m = _now.minute.toString().padLeft(2, '0');
    final String label;
    if (use24h) {
      label = '${_now.hour.toString().padLeft(2, '0')}:$m';
    } else {
      final h = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
      label = '$h:$m ${_now.hour < 12 ? 'AM' : 'PM'}';
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
      child: Text(
        label,
        style: SteamStyle.text(context).titleMedium?.copyWith(
          color: t.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
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
    final d = t.sizes.avatar;
    return Padding(
      padding: EdgeInsets.only(right: t.spacing.sm),
      child: RsFocusable(
        onActivate: onPressed,
        semanticLabel: count > 0
            ? 'Notifications, $count unread'
            : 'Notifications',
        builder: (context, state) {
          final hi = state.highlighted;
          return SizedBox(
            width: d,
            height: d,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: t.motion.focus,
                  curve: t.motion.curve,
                  width: d,
                  height: d,
                  decoration: BoxDecoration(
                    color: hi
                        ? t.focusSurface
                        : t.focusSurface.withValues(alpha: 0),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    count > 0
                        ? Icons.notifications_rounded
                        : Icons.notifications_none_rounded,
                    size: t.sizes.icon + 2,
                    color: hi ? t.onFocusSurface : t.textSecondary,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: -t.spacing.xs / 2,
                    right: -t.spacing.xs,
                    child: Container(
                      constraints: BoxConstraints(minWidth: t.sizes.iconSm + 2),
                      padding: EdgeInsets.symmetric(horizontal: t.spacing.xs),
                      height: t.sizes.iconSm + 2,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(t.radii.pill),
                        border: Border.all(color: t.background, width: 2),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: SteamStyle.text(context).labelSmall?.copyWith(
                          color: t.onAccent,
                          letterSpacing: 0,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
    final d = t.sizes.avatar;
    final palette = SteamArtPalette.of(t.art, null, name);
    final initials = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.glow, palette.start],
        ),
      ),
      child: Text(
        steamInitials(name),
        style: SteamStyle.text(context).titleSmall
            ?.copyWith(color: t.art.onArt, height: 1),
      ),
    );
    return RsFocusable(
      onActivate: onPressed,
      semanticLabel: name.isEmpty ? 'Account' : name,
      builder: (context, state) {
        final hi = state.focused || state.hovered;
        return AnimatedScale(
          scale: hi ? t.motion.focusScale : 1,
          duration: t.motion.focus,
          curve: t.motion.curve,
          child: AnimatedContainer(
            duration: t.motion.focus,
            curve: t.motion.curve,
            width: d,
            height: d,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(t.radii.sm),
              border: Border.all(
                color: hi ? t.focusRing : t.divider,
                width: t.sizes.focusRingWidth,
              ),
              boxShadow: hi ? SteamStyle.focusGlow(t, strength: 0.7) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(t.radii.sm / 2),
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
}
