import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rs_theme/rs_theme.dart';

/// Callbacks the settings columns use to move focus between each other.
class SettingsColumnLink {
  /// Focuses the first row in the column.
  void Function()? focusFirst;

  /// Focuses the row at the given index, clamped to the column.
  void Function(int index)? focusIndex;
}

/// A vertically scrolling column of focusable rows.
///
/// Up and down move inside the column and stop at the ends. Left and right
/// are reported through [onHorizontal] so the other column can take focus.
class SettingsFocusColumn extends StatefulWidget {
  const SettingsFocusColumn({
    super.key,
    required this.link,
    required this.length,
    required this.onHorizontal,
    required this.itemBuilder,
  });

  final SettingsColumnLink link;
  final int length;
  final void Function(TraversalDirection direction) onHorizontal;
  final Widget Function(BuildContext context, int index, FocusNode node)
  itemBuilder;

  @override
  State<SettingsFocusColumn> createState() => _SettingsFocusColumnState();
}

class _SettingsFocusColumnState extends State<SettingsFocusColumn> {
  List<FocusNode> _nodes = const [];

  @override
  void initState() {
    super.initState();
    _syncNodes(widget.length);
  }

  @override
  void didUpdateWidget(SettingsFocusColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.length != widget.length) _syncNodes(widget.length);
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _nodes = const [];
    super.dispose();
  }

  FocusNode _node(int index) =>
      FocusNode(debugLabel: 'settings-column-$index', onKeyEvent: _onKey);

  /// Grows or shrinks [_nodes]. Nodes that fall off the end are disposed
  /// after this frame so the current row can detach them first.
  void _syncNodes(int length) {
    if (length == _nodes.length) return;
    if (length < _nodes.length) {
      final extra = _nodes.sublist(length);
      _nodes = List<FocusNode>.of(_nodes.take(length));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in extra) {
          node.dispose();
        }
      });
      return;
    }
    _nodes = [..._nodes, for (var i = _nodes.length; i < length; i++) _node(i)];
  }

  void _focusFirst() {
    if (!mounted || _nodes.isEmpty) return;
    _nodes.first.requestFocus();
  }

  void _focusIndex(int index) {
    if (!mounted || _nodes.isEmpty) return;
    _nodes[index.clamp(0, _nodes.length - 1)].requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final index = _nodes.indexOf(node);
    if (index < 0) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (index > 0) _nodes[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (index + 1 < _nodes.length) _nodes[index + 1].requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onHorizontal(TraversalDirection.left);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onHorizontal(TraversalDirection.right);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    widget.link.focusFirst = _focusFirst;
    widget.link.focusIndex = _focusIndex;
    final gap = context.rsTokens.spacing.xs;
    return ListView.builder(
      primary: false,
      clipBehavior: Clip.none,
      itemCount: widget.length,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: widget.itemBuilder(context, index, _nodes[index]),
      ),
    );
  }
}
