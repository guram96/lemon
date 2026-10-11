import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rs_ui/rs_ui.dart';

/// Minimal set that renders labels and state as text, so the shared
/// behavior in `rs_ui` can be tested without a real look.
class _FakeSet extends RsComponentSet {
  const _FakeSet();

  @override
  String get id => 'fake';
  @override
  String get displayName => 'Fake';

  Widget _focusable(
    String label, {
    VoidCallback? onActivate,
    bool autofocus = false,
    FocusNode? focusNode,
  }) => RsFocusable(
    autofocus: autofocus,
    focusNode: focusNode,
    onActivate: onActivate,
    builder: (_, s) => Text('$label${s.focused ? ' [focused]' : ''}'),
  );

  @override
  Widget button(BuildContext context, RsButton config) => _focusable(
    config.label,
    onActivate: config.onPressed,
    autofocus: config.autofocus,
    focusNode: config.focusNode,
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

  @override
  Widget textField(BuildContext context, RsTextField config) =>
      Text(config.label ?? '');

  @override
  Widget listRow(BuildContext context, RsListRow config) =>
      _focusable(config.title, onActivate: config.onPressed);

  @override
  Widget tabs(BuildContext context, RsTabs config) =>
      Text('tab:${config.selectedIndex}');

  @override
  Widget gameArt(BuildContext context, RsGameArt config) => Text(config.title);

  @override
  Widget gameCard(BuildContext context, RsGameCard config) => _focusable(
    config.title,
    onActivate: config.onPressed,
    autofocus: config.autofocus,
    focusNode: config.focusNode,
  );

  @override
  Widget shelf(BuildContext context, RsShelf config) => RsFocusMemory(
    child: Row(
      children: [
        for (var i = 0; i < config.itemCount; i++)
          RsFocusMemoryItem(id: i, child: config.itemBuilder(context, i)),
      ],
    ),
  );

  @override
  Widget grid(BuildContext context, RsGrid config) => Column(
    children: [
      for (var i = 0; i < config.itemCount; i++) config.itemBuilder(context, i),
    ],
  );

  @override
  Widget hero(BuildContext context, RsHero config) => Text(config.title);

  @override
  Widget scaffold(BuildContext context, RsScaffold config) => Column(
    children: [
      ?config.topBar,
      Expanded(child: config.body),
      ?config.hints,
    ],
  );

  @override
  Widget topBar(BuildContext context, RsTopBar config) =>
      Text('nav:${config.selectedIndex}');

  @override
  Widget buttonHints(BuildContext context, RsButtonHints config) =>
      Text(config.hints.map((h) => h.label).join(','));

  @override
  Widget glyph(BuildContext context, RsGlyph config) =>
      Text('${config.effectiveStyle(context).name}:${config.button.name}');

  @override
  Widget wizardFrame(BuildContext context, RsWizardFrame config) =>
      config.child;

  @override
  Widget progressBar(BuildContext context, RsProgressBar config) =>
      Text('${config.value}');

  @override
  Widget spinner(BuildContext context, RsSpinner config) => const Text('…');

  @override
  Widget toast(BuildContext context, RsToast config) => Text(config.title);

  @override
  Widget toastStack(BuildContext context, RsToastStack config) =>
      Column(children: config.toasts);

  @override
  Widget dialog(BuildContext context, RsDialog config) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [Text(config.title ?? ''), ...config.actions],
  );

  @override
  Route<T> dialogRoute<T>(
    BuildContext context,
    WidgetBuilder builder, {
    required bool dismissible,
  }) => RawDialogRoute<T>(
    barrierDismissible: dismissible,
    barrierLabel: 'Dismiss',
    pageBuilder: (context, _, _) => builder(context),
  );
}

Widget _app(Widget child) => WidgetsApp(
  color: const Color(0xFF000000),
  builder: (_, _) => RsComponents(
    set: const _FakeSet(),
    child: RsInputScope(child: Column(children: [child])),
  ),
);

/// App with a navigator, so dialogs can be pushed.
Widget _navApp(Widget home) => WidgetsApp(
  color: const Color(0xFF000000),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (c, _, _) => builder(c),
  ),
  home: home,
  builder: (_, child) => RsComponents(
    set: const _FakeSet(),
    child: RsInputScope(child: child!),
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

  group('RsTabHost', () {
    Widget page({
      required int nav,
      required ValueChanged<int> onNav,
      int? tab,
      ValueChanged<int>? onTab,
    }) => _app(
      SizedBox(
        height: 300,
        child: RsScaffold(
          topBar: RsTopBar(
            items: const [
              RsNavItem(label: 'Home'),
              RsNavItem(label: 'Library'),
              RsNavItem(label: 'Settings'),
            ],
            selectedIndex: nav,
            onSelected: onNav,
          ),
          body: Column(
            children: [
              if (tab != null)
                RsTabs(
                  tabs: const [
                    RsTab(label: 'All'),
                    RsTab(label: 'SNES'),
                  ],
                  selectedIndex: tab,
                  onChanged: onTab!,
                ),
              RsButton(label: 'body', autofocus: true, onPressed: () {}),
            ],
          ),
        ),
      ),
    );

    testWidgets('LB / RB reach the top bar from the page body', (tester) async {
      var nav = 0;
      await tester.pumpWidget(page(nav: nav, onNav: (i) => nav = i));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
      expect(nav, 1);
      await tester.pumpWidget(page(nav: nav, onNav: (i) => nav = i));
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      expect(nav, 2);
      await tester.pumpWidget(page(nav: nav, onNav: (i) => nav = i));
      // Clamped at the end, no wrap-around.
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
      expect(nav, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonLeft1);
      expect(nav, 1);
    });

    testWidgets('in-page tabs take LB / RB over the top bar', (tester) async {
      var nav = 0;
      var tab = 0;
      await tester.pumpWidget(
        page(nav: nav, onNav: (i) => nav = i, tab: tab, onTab: (i) => tab = i),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
      expect(tab, 1);
      expect(nav, 0);
    });
  });

  testWidgets('RsFocusMemory restores the last focused item on re-entry', (
    tester,
  ) async {
    final outside = FocusNode();
    final nodes = List.generate(4, (_) => FocusNode());
    addTearDown(() {
      outside.dispose();
      for (final n in nodes) {
        n.dispose();
      }
    });
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            RsButton(label: 'outside', focusNode: outside, onPressed: () {}),
            RsShelf(
              title: 'Shelf',
              itemCount: 4,
              itemBuilder: (_, i) => RsGameCard(
                title: 'g$i',
                focusNode: nodes[i],
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
    nodes[2].requestFocus();
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);

    outside.requestFocus();
    await tester.pump();
    // Entering at item 0 (as directional focus might) lands on item 2.
    nodes[0].requestFocus();
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);

    // Moving inside the group is not redirected.
    nodes[3].requestFocus();
    await tester.pump();
    expect(nodes[3].hasFocus, isTrue);
  });

  group('showRsDialog', () {
    Widget home({required ValueChanged<int> onTab}) => Builder(
      builder: (context) => RsScaffold(
        topBar: RsTopBar(
          items: const [
            RsNavItem(label: 'A'),
            RsNavItem(label: 'B'),
          ],
          selectedIndex: 0,
          onSelected: onTab,
        ),
        body: Column(
          children: [
            RsButton(label: 'behind', onPressed: () {}),
            RsButton(
              label: 'open',
              autofocus: true,
              onPressed: () => showRsDialog<void>(
                context: context,
                builder: (context) => RsDialog(
                  title: 'Sure?',
                  actions: [
                    RsButton(label: 'No', onPressed: () {}),
                    RsButton(label: 'Yes', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    testWidgets('focuses the first action, traps focus, B closes', (
      tester,
    ) async {
      var navChanges = 0;
      await tester.pumpWidget(_navApp(home(onTab: (_) => navChanges++)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Sure?'), findsOneWidget);
      expect(find.text('No [focused]'), findsOneWidget);

      // Tab cycles inside the dialog only.
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(find.text('behind [focused]'), findsNothing);
        expect(find.text('open [focused]'), findsNothing);
      }

      // LB / RB don't reach the page underneath.
      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonRight1);
      expect(navChanges, 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
      await tester.pumpAndSettle();
      expect(find.text('Sure?'), findsNothing);
    });

    testWidgets('non-dismissible dialogs ignore back', (tester) async {
      await tester.pumpWidget(
        _navApp(
          Builder(
            builder: (context) => RsButton(
              label: 'open',
              autofocus: true,
              onPressed: () => showRsDialog<void>(
                context: context,
                dismissible: false,
                builder: (_) => const RsDialog(title: 'Busy'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Busy'), findsOneWidget);
    });
  });

  testWidgets('RsGlyphStyleScope sets the default glyph style', (tester) async {
    await tester.pumpWidget(
      _app(
        const RsGlyphStyleScope(
          style: RsGlyphStyle.playstation,
          child: Column(
            children: [
              RsGlyph(button: RsControllerButton.a),
              RsGlyph(button: RsControllerButton.b, style: RsGlyphStyle.xbox),
            ],
          ),
        ),
      ),
    );
    expect(find.text('playstation:a'), findsOneWidget);
    expect(find.text('xbox:b'), findsOneWidget);
  });
}
