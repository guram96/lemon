import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../platform/client_capabilities.dart';
import 'settings_focus.dart';
import 'settings_sections.dart';

/// Big Picture settings: a category column and the open category's rows.
///
/// The shell draws the top bar. This widget is only the body.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

enum _SettingsCategory {
  interface('Interface'),
  audio('Audio'),
  emulators('Emulators'),
  storage('Storage'),
  account('Account');

  const _SettingsCategory(this.label);

  final String label;
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _categoriesLink = SettingsColumnLink();
  final _paneLink = SettingsColumnLink();
  var _category = _SettingsCategory.interface;

  List<_SettingsCategory> _visible(bool canInstall) => [
    _SettingsCategory.interface,
    _SettingsCategory.audio,
    _SettingsCategory.emulators,
    if (canInstall) _SettingsCategory.storage,
    _SettingsCategory.account,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final canInstall = ref.watch(
      clientCapabilitiesProvider.select((caps) => caps.canInstallGames),
    );
    final categories = _visible(canInstall);
    if (!categories.contains(_category)) {
      _category = _SettingsCategory.interface;
    }
    final selectedIndex = categories.indexOf(_category);

    final categoryColumn = SettingsFocusColumn(
      link: _categoriesLink,
      length: categories.length,
      onHorizontal: (direction) {
        if (direction == TraversalDirection.right) {
          _paneLink.focusFirst?.call();
        }
      },
      itemBuilder: (context, index, node) {
        final category = categories[index];
        return _CategoryRow(
          label: category.label,
          selected: category == _category,
          focusNode: node,
          autofocus: index == 0,
          onPressed: () => setState(() => _category = category),
        );
      },
    );

    void moveToCategories(TraversalDirection direction) {
      if (direction == TraversalDirection.left) {
        _categoriesLink.focusIndex?.call(selectedIndex);
      }
    }

    final pane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _category.label,
          style: text.titleLarge?.copyWith(color: t.textPrimary),
        ),
        SizedBox(height: t.spacing.md),
        Expanded(child: _section(moveToCategories)),
      ],
    );

    // Stack when this body is narrower than the medium breakpoint, even if
    // the window reports a larger size.
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < t.breakpoints.medium;
        final gutter = narrow ? t.spacing.md : context.rsPageGutter;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            t.spacing.lg,
            gutter,
            t.spacing.md,
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: categoryColumn),
                    SizedBox(height: t.spacing.md),
                    Expanded(flex: 3, child: pane),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 280, child: categoryColumn),
                    SizedBox(width: t.spacing.xl),
                    Expanded(child: pane),
                  ],
                ),
        );
      },
    );
  }

  Widget _section(void Function(TraversalDirection direction) onHorizontal) {
    final link = _paneLink;
    return switch (_category) {
      _SettingsCategory.interface => InterfaceSettings(
        link: link,
        onHorizontal: onHorizontal,
      ),
      _SettingsCategory.audio => AudioSettings(
        link: link,
        onHorizontal: onHorizontal,
      ),
      _SettingsCategory.emulators => EmulatorSettings(
        link: link,
        onHorizontal: onHorizontal,
      ),
      _SettingsCategory.storage => StorageSettings(
        link: link,
        onHorizontal: onHorizontal,
      ),
      _SettingsCategory.account => AccountSettings(
        link: link,
        onHorizontal: onHorizontal,
      ),
    };
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.focusNode,
    required this.autofocus,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final FocusNode focusNode;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    return RsFocusable(
      focusNode: focusNode,
      autofocus: autofocus,
      onActivate: onPressed,
      semanticLabel: label,
      builder: (context, state) {
        final highlighted = state.highlighted;
        final color = highlighted
            ? t.onFocusSurface
            : selected
            ? t.accent
            : t.textPrimary;
        return AnimatedContainer(
          duration: t.motion.focus,
          curve: t.motion.curve,
          constraints: BoxConstraints(minHeight: t.sizes.rowMinHeight),
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.md,
            vertical: t.spacing.sm,
          ),
          decoration: BoxDecoration(
            color: highlighted
                ? t.focusSurface
                : t.background.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(t.radii.sm),
            border: Border(
              left: BorderSide(
                color: selected ? t.accent : t.accent.withValues(alpha: 0),
                width: t.spacing.xs,
              ),
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: text.titleMedium?.copyWith(
              color: color,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}
