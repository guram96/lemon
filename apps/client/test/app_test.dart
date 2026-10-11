import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_client/src/app/retro_steam_app.dart';
import 'package:rs_client/src/app/theme_settings_provider.dart';

void main() {
  testWidgets('app boots and toggles theme mode', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RetroSteamApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retro Steam'), findsOneWidget);
    expect(container.read(themeSettingsProvider).mode, ThemeMode.dark);

    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(container.read(themeSettingsProvider).mode, ThemeMode.light);
  });
}
