import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_style.dart';

/// Big Picture library tabs: LB … tabs … RB, the selected tab bright with
/// an accent underline, the focused tab filled with the light highlight.
class SteamTabs extends StatefulWidget {
  const SteamTabs(this.config, {super.key});

  final RsTabs config;

  @override
  State<SteamTabs> createState() => _SteamTabsState();
}

class _SteamTabsState extends State<SteamTabs> {
  final _keys = <int, GlobalKey>{};

  GlobalKey _key(int i) => _keys.putIfAbsent(i, GlobalKey.new);

  @override
  void didUpdateWidget(SteamTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.selectedIndex != widget.config.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[widget.config.selectedIndex]?.currentContext;
        if (ctx == null || !mounted) return;
        final t = context.rsTokens;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: t.motion.page,
          curve: t.motion.curve,
        );
      });
    }
  }

  void _select(int i) {
    final c = widget.config;
    if (c.tabs.isEmpty) return;
    final next = i.clamp(0, c.tabs.length - 1);
    if (next != c.selectedIndex) c.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final t = context.rsTokens;
    final gutter = context.rsPageGutter;
    Widget bumper(RsControllerButton b, int dir) => SteamTapTarget(
      onTap: () => _select(c.selectedIndex + dir),
      semanticLabel: dir < 0 ? 'Previous tab' : 'Next tab',
      builder: (context, state) => AnimatedOpacity(
        duration: t.motion.fast,
        opacity: state.hovered ? 1 : 0.75,
        child: RsGlyph(button: b),
      ),
    );
    return SizedBox(
      height: t.sizes.tabHeight + t.spacing.sm,
      child: Row(
        children: [
          SizedBox(width: gutter),
          if (c.showBumperHints) ...[
            bumper(RsControllerButton.lb, -1),
            SizedBox(width: t.spacing.sm),
          ],
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < c.tabs.length; i++)
                  _Tab(
                    key: _key(i),
                    tab: c.tabs[i],
                    selected: i == c.selectedIndex,
                    onPressed: () => _select(i),
                  ),
              ],
            ),
          ),
          if (c.showBumperHints) ...[
            SizedBox(width: t.spacing.sm),
            bumper(RsControllerButton.rb, 1),
          ],
          SizedBox(width: gutter),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.tab,
    required this.selected,
    required this.onPressed,
  });

  final RsTab tab;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = SteamStyle.text(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.xs / 2,
        vertical: t.spacing.xs,
      ),
      child: RsFocusable(
        onActivate: onPressed,
        semanticLabel: tab.label,
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
            padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
            decoration: BoxDecoration(
              color: hi
                  ? t.focusSurface
                  : selected
                  ? t.surface
                  : t.surface.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(t.radii.sm),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(tab.icon, size: t.sizes.iconSm + 2, color: fg),
                      SizedBox(width: t.spacing.sm),
                    ],
                    Text(
                      tab.label.toUpperCase(),
                      style: text.labelMedium?.copyWith(color: fg),
                    ),
                    if (tab.count != null) ...[
                      SizedBox(width: t.spacing.sm),
                      Text(
                        '${tab.count}',
                        style: text.labelMedium?.copyWith(
                          color: fg.withValues(alpha: 0.6),
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    duration: t.motion.focus,
                    opacity: selected && !hi ? 1 : 0,
                    child: Container(
                      height: t.spacing.xs / 2 + 1,
                      decoration: BoxDecoration(
                        color: t.accent,
                        borderRadius: BorderRadius.circular(t.radii.pill),
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
