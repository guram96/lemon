import 'package:flutter/material.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

/// Opens a folder picker over the **server's** filesystem
/// (`POST /setup/browse`). Completes with the chosen absolute path, or
/// `null` when cancelled.
Future<String?> showFolderBrowser({
  required BuildContext context,
  required RsApiClient api,
  required String title,
  String? initialPath,
  String selectLabel = 'Select this folder',
}) => showRsDialog<String>(
  context: context,
  builder: (_) => FolderBrowserDialog(
    api: api,
    title: title,
    initialPath: initialPath,
    selectLabel: selectLabel,
  ),
);

class FolderBrowserDialog extends StatefulWidget {
  const FolderBrowserDialog({
    super.key,
    required this.api,
    required this.title,
    this.initialPath,
    this.selectLabel = 'Select this folder',
  });

  final RsApiClient api;
  final String title;
  final String? initialPath;
  final String selectLabel;

  @override
  State<FolderBrowserDialog> createState() => _FolderBrowserDialogState();
}

class _FolderBrowserDialogState extends State<FolderBrowserDialog> {
  final _firstRow = FocusNode(debugLabel: 'FolderBrowser.firstRow');
  final _select = FocusNode(debugLabel: 'FolderBrowser.select');
  BrowseResult? _listing;
  bool _loading = true;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(widget.initialPath, fallbackToHome: true, moveFocus: false);
  }

  @override
  void dispose() {
    _firstRow.dispose();
    _select.dispose();
    super.dispose();
  }

  Future<void> _load(
    String? path, {
    bool fallbackToHome = false,
    bool moveFocus = true,
  }) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await widget.api.browse(path);
      if (!mounted || request != _request) return;
      setState(() {
        _listing = listing;
        _loading = false;
      });
      if (moveFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          (_firstRow.context != null ? _firstRow : _select).requestFocus();
        });
      }
    } on Object catch (e) {
      if (!mounted || request != _request) return;
      if (fallbackToHome && path != null) {
        return _load(null, moveFocus: moveFocus);
      }
      setState(() {
        _loading = false;
        _error = _describe(e);
      });
    }
  }

  static String _describe(Object e) {
    if (e is! ApiException) return 'Could not open this folder.';
    if (e.isUnreachable) return 'Lost the connection to the server.';
    return e.error.message;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    final listing = _listing;

    final rows = <Widget>[
      if (listing?.parent case final parent?)
        RsListRow(
          key: ValueKey('up:$parent'),
          focusNode: _firstRow,
          icon: Icons.arrow_upward_rounded,
          title: 'Up one level',
          subtitle: parent,
          onPressed: () => _load(parent),
        ),
      for (final (i, e) in (listing?.entries ?? const <BrowseEntry>[]).indexed)
        RsListRow(
          key: ValueKey('dir:${e.path}'),
          focusNode: i == 0 && listing?.parent == null ? _firstRow : null,
          icon: e.readable ? Icons.folder_rounded : Icons.folder_off_outlined,
          title: e.name,
          subtitle: e.readable ? null : 'No access',
          chevron: true,
          onPressed: () => _load(e.path),
        ),
    ];

    return RsDialog(
      title: widget.title,
      icon: Icons.folder_open_rounded,
      maxWidth: t.sizes.wizardMaxWidth,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (listing != null && listing.shortcuts.isNotEmpty) ...[
            Wrap(
              spacing: t.spacing.sm,
              runSpacing: t.spacing.sm,
              children: [
                for (final s in listing.shortcuts)
                  RsButton(
                    key: ValueKey('shortcut:${s.path}'),
                    label: s.name,
                    icon: _shortcutIcon(s.name),
                    onPressed: () => _load(s.path),
                  ),
              ],
            ),
            SizedBox(height: t.spacing.md),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: t.spacing.md,
              vertical: t.spacing.sm + t.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(t.radii.md),
              border: Border.all(color: t.divider),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder_open_rounded,
                  size: t.sizes.icon,
                  color: t.accent,
                ),
                SizedBox(width: t.spacing.sm),
                Expanded(
                  child: Text(
                    listing?.path ?? '…',
                    style: text.bodyMedium?.copyWith(color: t.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (_error case final error?) ...[
            SizedBox(height: t.spacing.sm),
            Text(error, style: text.bodyMedium?.copyWith(color: t.danger)),
          ],
          SizedBox(height: t.spacing.sm),
          if (_loading && listing == null)
            Padding(
              padding: EdgeInsets.all(t.spacing.lg),
              child: const Center(child: RsSpinner()),
            )
          else ...[
            if (_loading)
              Padding(
                padding: EdgeInsets.only(bottom: t.spacing.sm),
                child: const RsProgressBar(),
              ),
            ...rows,
            if (listing != null && listing.entries.isEmpty)
              Padding(
                padding: EdgeInsets.all(t.spacing.md),
                child: Text(
                  'No folders in here. Select it, or go up a level.',
                  style: text.bodyMedium?.copyWith(color: t.textMuted),
                ),
              ),
          ],
        ],
      ),
      actions: [
        RsButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        RsButton(
          label: widget.selectLabel,
          icon: Icons.check_rounded,
          variant: RsButtonVariant.primary,
          focusNode: _select,
          onPressed: listing == null || _loading
              ? null
              : () => Navigator.of(context).pop(listing.path),
        ),
      ],
    );
  }

  static IconData _shortcutIcon(String name) => switch (name) {
    'Home' => Icons.home_rounded,
    'Desktop' => Icons.desktop_windows_rounded,
    'Documents' => Icons.description_outlined,
    'Downloads' => Icons.download_rounded,
    _ => Icons.storage_rounded,
  };
}
