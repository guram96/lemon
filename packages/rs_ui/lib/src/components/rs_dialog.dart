import 'package:flutter/widgets.dart';

import '../component_set.dart';
import '../input/rs_input_scope.dart';
import '../input/rs_intents.dart';

/// Modal dialog panel. Show it with [showRsDialog], which traps focus inside
/// it and closes it on B / Escape ([RsBackIntent]).
class RsDialog extends StatelessWidget {
  const RsDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.actions = const [],
    this.icon,
    this.maxWidth,
  });

  final String? title;

  /// Plain body text, shown above [content].
  final String? message;

  /// Custom body (form fields, lists, …).
  final Widget? content;

  /// Usually [RsButton]s; laid out right-aligned, stacked on narrow screens.
  /// The first one gets focus when the dialog opens unless something else
  /// asks for autofocus.
  final List<Widget> actions;
  final IconData? icon;

  /// Defaults to the set's dialog width.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).dialog(context, this);
}

/// Shows a modal dialog built by [builder] (usually an [RsDialog]) using
/// the active set's dialog route.
///
/// - Focus is trapped in the dialog, and the first focusable widget gets
///   focus when it opens.
/// - B / Escape / Backspace ([RsBackIntent]) and tapping the backdrop close
///   it when [dismissible] is true.
/// - LB / RB do not reach the page underneath.
///
/// Completes with the value passed to `Navigator.pop`, or `null`.
Future<T?> showRsDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
  bool useRootNavigator = true,
}) {
  final set = RsComponents.of(context);
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    set.dialogRoute<T>(
      context,
      (routeContext) => themes.wrap(
        RsComponents(
          set: set,
          child: RsInputScope(
            child: RsDialogScope(
              dismissible: dismissible,
              child: Builder(builder: builder),
            ),
          ),
        ),
      ),
      dismissible: dismissible,
    ),
  );
}

/// Dialog behavior shared by every set: back closes, LB / RB are blocked,
/// the first focusable child is focused on open. Used by [showRsDialog];
/// sets with custom overlays can use it too.
class RsDialogScope extends StatefulWidget {
  const RsDialogScope({
    super.key,
    required this.child,
    this.dismissible = true,
  });

  final Widget child;
  final bool dismissible;

  @override
  State<RsDialogScope> createState() => _RsDialogScopeState();
}

class _RsDialogScopeState extends State<RsDialogScope> {
  final _scopeNode = FocusScopeNode(debugLabel: 'RsDialogScope');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final primary = FocusManager.instance.primaryFocus;
      final inside =
          primary != null &&
          primary != _scopeNode &&
          primary.ancestors.contains(_scopeNode);
      if (!inside) {
        final first = _scopeNode.traversalDescendants.firstOrNull;
        if (first != null) {
          first.requestFocus();
        } else {
          _scopeNode.requestFocus();
        }
      }
    });
  }

  @override
  void dispose() {
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      RsBackIntent: CallbackAction<RsBackIntent>(
        onInvoke: (_) {
          if (widget.dismissible) Navigator.of(context).maybePop();
          return null;
        },
      ),
      RsTabIntent: DoNothingAction(consumesKey: true),
    },
    child: FocusScope(node: _scopeNode, child: widget.child),
  );
}
