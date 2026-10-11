import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_ui/rs_ui.dart';

/// Minimal set that renders the label and focus state as text.
class _FakeSet extends RsComponentSet {
  const _FakeSet();

  @override
  String get id => 'fake';
  @override
  String get displayName => 'Fake';

  @override
  Widget button(BuildContext context, RsButton config) => RsFocusable(
    autofocus: config.autofocus,
    onActivate: config.onPressed,
    builder: (_, s) => Text('${config.label}${s.focused ? ' [focused]' : ''}'),
  );

  @override
  Widget toggle(BuildContext context, RsToggle config) => RsFocusable(
    onActivate: config.onChanged == null
        ? null
        : () => config.onChanged!(!config.value),
    builder: (_, _) => Text('${config.label}: ${config.value}'),
  );

  @override
  Widget tile(BuildContext context, RsTile config) => RsFocusable(
    onActivate: config.onPressed,
    onFocusChanged: config.onFocusChanged,
    builder: (_, _) => Text(config.title ?? ''),
  );
}

Widget _app(Widget child) => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (_, _) => RsComponents(
    set: const _FakeSet(),
    child: RsInputScope(child: Column(children: [child])),
  ),
);

void main() {
  testWidgets('components delegate to the active set', (tester) async {
    await tester.pumpWidget(_app(RsButton(label: 'Play', onPressed: () {})));
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('Enter and controller A activate the focused button', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _app(
        RsButton(label: 'Play', autofocus: true, onPressed: () => presses++),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);
    expect(presses, 2);
  });

  testWidgets('tap activates; disabled buttons ignore input', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      _app(RsButton(label: 'Go', onPressed: () => presses++)),
    );
    await tester.tap(find.text('Go'));
    expect(presses, 1);

    await tester.pumpWidget(
      _app(const RsButton(label: 'Off', onPressed: null)),
    );
    await tester.tap(find.text('Off'));
    expect(presses, 1);
  });

  testWidgets('controller B and Escape dispatch RsBackIntent', (tester) async {
    var backs = 0;
    await tester.pumpWidget(
      _app(
        Actions(
          actions: {
            RsBackIntent: CallbackAction<RsBackIntent>(
              onInvoke: (_) => backs++,
            ),
          },
          child: RsButton(label: 'x', autofocus: true, onPressed: () {}),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(backs, 2);
  });
}
