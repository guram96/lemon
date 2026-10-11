import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../app/theme_settings_provider.dart';

/// Temporary start page that exercises the component set and theming.
/// Replaced by the first real screen.
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.rsTokens;
    final settings = ref.watch(themeSettingsProvider);
    final isDark = settings.mode == ThemeMode.dark;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.all(t.spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Retro Steam',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: t.spacing.xs),
              Text(
                'Workspace is up. Waiting for the first screen.',
                style: TextStyle(color: t.textMuted),
              ),
              SizedBox(height: t.spacing.xl),
              RsToggle(
                label: 'Dark mode',
                description: 'Use the dark Big Picture theme',
                value: isDark,
                autofocus: true,
                onChanged: (v) => ref
                    .read(themeSettingsProvider.notifier)
                    .update(
                      settings.copyWith(
                        mode: v ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
              ),
              SizedBox(height: t.spacing.lg),
              Row(
                children: [
                  RsButton(
                    label: 'Play',
                    variant: RsButtonVariant.primary,
                    onPressed: () {},
                  ),
                  SizedBox(width: t.spacing.md),
                  RsButton(label: 'Settings', onPressed: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
