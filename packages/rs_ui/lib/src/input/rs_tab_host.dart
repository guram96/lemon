import 'package:flutter/widgets.dart';

import 'rs_intents.dart';

/// Handles one [RsTabIntent]. Returns `true` when it consumed the intent.
typedef RsTabHandler = bool Function(int direction);

/// Routes LB / RB ([RsTabIntent]) to tab-like widgets that are not ancestors
/// of the focused widget, for example a top bar or a tab strip while focus is
/// in the grid below it.
///
/// [RsScaffold] installs one per page. Tab widgets register with
/// [RsTabHost.maybeOf]; the handler with the highest priority wins, and among
/// equal priorities the one registered last. So a page's [RsTabs]
/// (priority [RsTabHost.tabsPriority]) take LB / RB over the top bar
/// ([RsTabHost.navPriority]).
class RsTabHost extends StatefulWidget {
  const RsTabHost({super.key, required this.child});

  final Widget child;

  /// Priority used by navigation bars.
  static const navPriority = 0;

  /// Priority used by in-page tab strips.
  static const tabsPriority = 10;

  static RsTabHostState? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_RsTabHostScope>()?.state;

  @override
  State<RsTabHost> createState() => RsTabHostState();
}

/// A live registration; call [dispose] when the widget goes away.
class RsTabRegistration {
  RsTabRegistration._(this._host, this.priority, this._order, this.handler);

  final RsTabHostState _host;
  final int priority;
  final int _order;

  /// Can be swapped when the owning widget rebuilds.
  RsTabHandler handler;

  void dispose() => _host._entries.remove(this);
}

class RsTabHostState extends State<RsTabHost> {
  final _entries = <RsTabRegistration>[];
  int _counter = 0;

  late final _action = _RsTabHostAction(this);

  RsTabRegistration register(RsTabHandler handler, {int priority = 0}) {
    final entry = RsTabRegistration._(this, priority, _counter++, handler);
    _entries.add(entry);
    return entry;
  }

  /// Offers [direction] to the registered handlers, best first.
  bool dispatch(int direction) {
    final ordered = [..._entries]
      ..sort((a, b) {
        final p = b.priority.compareTo(a.priority);
        return p != 0 ? p : b._order.compareTo(a._order);
      });
    for (final entry in ordered) {
      if (entry.handler(direction)) return true;
    }
    return false;
  }

  bool get _hasHandlers => _entries.isNotEmpty;

  @override
  Widget build(BuildContext context) => Actions(
    actions: {RsTabIntent: _action},
    child: _RsTabHostScope(state: this, child: widget.child),
  );
}

class _RsTabHostAction extends Action<RsTabIntent> {
  _RsTabHostAction(this.host);

  final RsTabHostState host;

  @override
  bool isEnabled(RsTabIntent intent) => host._hasHandlers;

  @override
  Object? invoke(RsTabIntent intent) => host.dispatch(intent.direction);
}

class _RsTabHostScope extends InheritedWidget {
  const _RsTabHostScope({required this.state, required super.child});

  final RsTabHostState state;

  @override
  bool updateShouldNotify(_RsTabHostScope oldWidget) => false;
}

/// Mixin for the state of tab-like widgets: registers [onTab] with the
/// nearest [RsTabHost] for as long as the widget is mounted.
mixin RsTabHostClient<T extends StatefulWidget> on State<T> {
  RsTabRegistration? _registration;

  /// Priority passed to [RsTabHostState.register].
  int get tabPriority;

  /// Called for LB (`-1`) / RB (`1`). Return `true` if handled.
  bool onTab(int direction);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registration ??= RsTabHost.maybeOf(context)
        ?.register(onTab, priority: tabPriority);
  }

  @override
  void dispose() {
    _registration?.dispose();
    super.dispose();
  }

  /// Wrap the widget's own subtree so LB / RB also work while focus is
  /// inside it, even without an [RsTabHost].
  Widget wrapTabActions(Widget child) => Actions(
    actions: {
      RsTabIntent: CallbackAction<RsTabIntent>(
        onInvoke: (intent) => onTab(intent.direction),
      ),
    },
    child: child,
  );
}
