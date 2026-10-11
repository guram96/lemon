import 'package:flutter/material.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import 'steam_component_set.dart';

/// Preview of every component in the Steam set, for the product owner and
/// for visual checks. Self-contained: provides its own theme (with a
/// dark / light switch), component set and input scope. Put it under any
/// `MaterialApp` (or `WidgetsApp` with `Localizations`).
class SteamGallery extends StatefulWidget {
  const SteamGallery({super.key, this.initialDark = true});

  final bool initialDark;

  @override
  State<SteamGallery> createState() => _SteamGalleryState();
}

typedef _Game = ({String title, String system, String systemName});

const _games = <_Game>[
  (title: 'Chrono Trigger', system: 'snes', systemName: 'Super Nintendo'),
  (title: 'Final Fantasy VII', system: 'psx', systemName: 'PlayStation'),
  (
    title: 'Sonic the Hedgehog 2',
    system: 'megadrive',
    systemName: 'Mega Drive',
  ),
  (title: 'Super Mario 64', system: 'n64', systemName: 'Nintendo 64'),
  (title: 'Metroid Fusion', system: 'gba', systemName: 'Game Boy Advance'),
  (
    title: 'Castlevania: Symphony of the Night',
    system: 'psx',
    systemName: 'PlayStation',
  ),
  (title: 'Pokémon Crystal', system: 'gbc', systemName: 'Game Boy Color'),
  (title: 'Shenmue', system: 'dreamcast', systemName: 'Dreamcast'),
  (
    title: 'The Legend of Zelda: A Link to the Past',
    system: 'snes',
    systemName: 'Super Nintendo',
  ),
  (
    title: 'Street Fighter III: 3rd Strike',
    system: 'arcade',
    systemName: 'Arcade',
  ),
  (title: 'Tetris', system: 'gb', systemName: 'Game Boy'),
  (title: 'Super Metroid', system: 'snes', systemName: 'Super Nintendo'),
];

class _SteamGalleryState extends State<SteamGallery> {
  late bool _dark = widget.initialDark;
  int _nav = 2;
  int _tab = 0;
  bool _toggle = true;
  bool _rowSwitch = false;
  int _notifications = 3;
  int _toastCounter = 0;
  final _toasts = <RsToast>[];
  final _user = TextEditingController(text: 'admin');
  final _password = TextEditingController();

  static const _tabs = [
    RsTab(label: 'All', count: 12),
    RsTab(label: 'SNES', count: 3),
    RsTab(label: 'PlayStation', count: 2),
    RsTab(label: 'Game Boy', count: 1),
    RsTab(label: 'Arcade', count: 1),
  ];

  @override
  void dispose() {
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  void _addToast({bool progress = false}) {
    final id = _toastCounter++;
    late final RsToast toast;
    void remove() => setState(() => _toasts.remove(toast));
    toast = progress
        ? RsToast(
            key: ValueKey(id),
            icon: Icons.sync_rounded,
            title: 'Scanning library…',
            body: '312 / 1 204 files · snes',
            progress: 0.26,
            onDismiss: remove,
          )
        : RsToast(
            key: ValueKey(id),
            icon: Icons.videogame_asset_rounded,
            title: '42 games added',
            body: 'Your library is ready to play.',
            onPressed: remove,
            onDismiss: remove,
          );
    setState(() => _toasts.add(toast));
  }

  Future<void> _openDialog(BuildContext context) => showRsDialog<void>(
    context: context,
    builder: (context) => RsDialog(
      icon: Icons.delete_outline_rounded,
      title: 'Uninstall Chrono Trigger?',
      message:
          'The game files will be removed from this device. '
          'You can install it again from the library.',
      actions: [
        RsButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
        RsButton(
          label: 'Uninstall',
          variant: RsButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    const settings = RsThemeSettings();
    return Theme(
      data: _dark
          ? RsThemeBuilder.dark(settings)
          : RsThemeBuilder.light(settings),
      child: RsComponents(
        set: const SteamComponentSet(),
        child: RsInputScope(child: Builder(builder: _buildPage)),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final gutter = context.rsPageGutter;

    Widget section(String title, Widget child, {bool padded = true}) => Padding(
      padding: EdgeInsets.only(top: t.spacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Text(
              title.toUpperCase(),
              style: text.labelMedium?.copyWith(color: t.textMuted),
            ),
          ),
          SizedBox(height: t.spacing.md),
          if (padded)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: child,
            )
          else
            child,
        ],
      ),
    );

    Widget card(_Game g, int i, {RsArtLayout layout = RsArtLayout.cover}) =>
        RsGameCard(
          title: g.title,
          systemId: g.system,
          systemName: g.systemName,
          layout: layout,
          installed: i % 4 == 1,
          showSystemBadge: layout == RsArtLayout.cover,
          progress: i == 2 ? 0.64 : null,
          onPressed: () {},
        );

    final filtered = switch (_tab) {
      1 => _games.where((g) => g.system == 'snes').toList(),
      2 => _games.where((g) => g.system == 'psx').toList(),
      3 => _games.where((g) => g.system.startsWith('gb')).toList(),
      4 => _games.where((g) => g.system == 'arcade').toList(),
      _ => _games,
    };

    final body = ListView(
      padding: EdgeInsets.only(bottom: t.spacing.xxl),
      children: [
        RsHero(
          title: 'Chrono Trigger',
          systemId: 'snes',
          systemName: 'Super Nintendo',
          subtitle: 'Super Nintendo · 1995 · Square',
          child: Wrap(
            spacing: t.spacing.sm + t.spacing.xs,
            runSpacing: t.spacing.sm,
            children: [
              RsButton(
                label: 'Install',
                icon: Icons.download_rounded,
                variant: RsButtonVariant.primary,
                autofocus: true,
                onPressed: () => _addToast(progress: true),
              ),
              RsButton(
                label: 'Options',
                icon: Icons.tune_rounded,
                onPressed: () {},
              ),
            ],
          ),
        ),
        section(
          'Shelf · cover capsules',
          RsShelf(
            title: 'Recently added',
            subtitle: '${_games.length} games',
            itemCount: _games.length,
            itemBuilder: (_, i) => card(_games[i], i),
          ),
          padded: false,
        ),
        section(
          'Shelf · wide capsules',
          RsShelf(
            title: 'Super Nintendo',
            itemAspectRatio: RsArtLayout.wide.aspectRatio!,
            itemCount: _games.length,
            itemBuilder: (_, i) => card(_games[i], i, layout: RsArtLayout.wide),
          ),
          padded: false,
        ),
        section(
          'Tabs + grid (LB / RB)',
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RsTabs(
                tabs: _tabs,
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              SizedBox(
                height: 560,
                child: RsGrid(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => card(filtered[i], i),
                ),
              ),
            ],
          ),
          padded: false,
        ),
        section(
          'Buttons',
          Wrap(
            spacing: t.spacing.sm + t.spacing.xs,
            runSpacing: t.spacing.sm,
            children: [
              RsButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                variant: RsButtonVariant.primary,
                onPressed: () {},
              ),
              RsButton(label: 'Settings', onPressed: () {}),
              RsButton(
                label: 'Show dialog',
                icon: Icons.open_in_new_rounded,
                onPressed: () => _openDialog(context),
              ),
              RsButton(
                label: 'Uninstall',
                variant: RsButtonVariant.danger,
                onPressed: () {},
              ),
              const RsButton(label: 'Disabled', onPressed: null),
            ],
          ),
        ),
        section(
          'Text fields',
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RsTextField(
                  controller: _user,
                  label: 'Username',
                  icon: Icons.person_outline_rounded,
                ),
                SizedBox(height: t.spacing.lg),
                RsTextField(
                  controller: _password,
                  label: 'Password',
                  hint: 'At least 8 characters',
                  obscure: true,
                  icon: Icons.lock_outline_rounded,
                  helperText: 'Stored hashed on the server.',
                ),
                SizedBox(height: t.spacing.lg),
                const RsTextField(
                  label: 'Server address',
                  hint: '192.168.1.20:47320',
                  errorText: 'Could not reach this address.',
                ),
              ],
            ),
          ),
        ),
        section(
          'List rows · toggles',
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RsListRow(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  subtitle: 'Switch the gallery theme',
                  switchValue: _dark,
                  onPressed: () => setState(() => _dark = !_dark),
                ),
                RsListRow(
                  icon: Icons.folder_outlined,
                  title: 'Data folder',
                  value: '/Volumes/SSD/RetroSteam',
                  chevron: true,
                  onPressed: () {},
                ),
                RsListRow(
                  icon: Icons.wifi_rounded,
                  title: 'Auto-connect',
                  switchValue: _rowSwitch,
                  onPressed: () => setState(() => _rowSwitch = !_rowSwitch),
                ),
                const RsListRow(
                  icon: Icons.storage_rounded,
                  title: 'Free space',
                  subtitle: 'Read-only information row',
                  value: '1.2 TB',
                ),
                RsToggle(
                  label: 'Notifications',
                  description: 'Show a toast when a scan finishes',
                  value: _toggle,
                  onChanged: (v) => setState(() => _toggle = v),
                ),
              ],
            ),
          ),
        ),
        section(
          'Progress · spinner · toasts',
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const RsProgressBar(
                  value: 0.42,
                  label: 'Scanning psx',
                  trailing: '312 / 1 204',
                ),
                SizedBox(height: t.spacing.lg),
                const RsProgressBar(label: 'Preparing…'),
                SizedBox(height: t.spacing.lg),
                const RsSpinner(label: 'Connecting to server…'),
                SizedBox(height: t.spacing.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: RsToast(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Setup complete',
                    body: 'Inline sample of a toast card.',
                    onDismiss: () {},
                  ),
                ),
                SizedBox(height: t.spacing.lg),
                Wrap(
                  spacing: t.spacing.sm + t.spacing.xs,
                  runSpacing: t.spacing.sm,
                  children: [
                    RsButton(label: 'Show toast', onPressed: _addToast),
                    RsButton(
                      label: 'Show progress toast',
                      onPressed: () => _addToast(progress: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        section(
          'Controller glyphs',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final style in RsGlyphStyle.values)
                Padding(
                  padding: EdgeInsets.only(bottom: t.spacing.sm),
                  child: Wrap(
                    spacing: t.spacing.sm,
                    runSpacing: t.spacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(style.name, style: text.bodySmall),
                      ),
                      for (final b in RsControllerButton.values)
                        RsGlyph(button: b, style: style),
                    ],
                  ),
                ),
            ],
          ),
        ),
        section(
          'Wizard frame (first run)',
          SizedBox(
            height: 640,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(t.radii.md),
              child: RsWizardFrame(
                steps: const ['Account', 'Data folder', 'Library', 'Review'],
                currentStep: 1,
                icon: Icons.folder_open_rounded,
                title: 'Where should Retro Steam keep its data?',
                subtitle:
                    'The database, artwork and caches go here. An SSD is '
                    'best. ROMs can stay on another drive.',
                primaryAction: RsButton(
                  label: 'Continue',
                  variant: RsButtonVariant.primary,
                  onPressed: () {},
                ),
                secondaryAction: RsButton(label: 'Back', onPressed: () {}),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RsListRow(
                      icon: Icons.folder_outlined,
                      title: '/Volumes/SSD/RetroSteam',
                      subtitle: 'Writable · 1.2 TB free',
                      chevron: true,
                      onPressed: () {},
                    ),
                    SizedBox(height: t.spacing.md),
                    const RsProgressBar(value: 0.25),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(
          child: RsScaffold(
            topBar: RsTopBar(
              items: const [
                RsNavItem(label: 'Home', icon: Icons.home_rounded),
                RsNavItem(label: 'Library', icon: Icons.grid_view_rounded),
                RsNavItem(label: 'Components', icon: Icons.widgets_rounded),
              ],
              selectedIndex: _nav,
              onSelected: (i) => setState(() => _nav = i),
              notificationCount: _notifications,
              onNotifications: () => setState(() => _notifications = 0),
              userName: 'Gabe Newell',
              onAvatar: () {},
            ),
            hints: RsButtonHints(
              leading: const [
                RsButtonHint(button: RsControllerButton.start, label: 'Menu'),
              ],
              hints: [
                const RsButtonHint(
                  button: RsControllerButton.a,
                  label: 'Select',
                ),
                RsButtonHint(
                  button: RsControllerButton.b,
                  label: 'Back',
                  onPressed: () {},
                ),
                RsButtonHint(
                  button: RsControllerButton.y,
                  label: _dark ? 'Light mode' : 'Dark mode',
                  onPressed: () => setState(() => _dark = !_dark),
                ),
              ],
            ),
            body: body,
          ),
        ),
        Positioned.fill(child: RsToastStack(toasts: List.of(_toasts))),
      ],
    );
  }
}
