import 'package:flutter/widgets.dart';

/// Remembers which of its [RsFocusMemoryItem]s had focus last, and sends
/// focus back there when it re-enters the group from outside (for example
/// pressing down from one shelf into the next returns to the game you were
/// on, not the one that happens to be geometrically closest).
///
/// Does not trap focus: directional navigation leaves the group normally.
class RsFocusMemory extends StatefulWidget {
  const RsFocusMemory({super.key, required this.child});

  final Widget child;

  @override
  State<RsFocusMemory> createState() => _RsFocusMemoryState();
}

class _RsFocusMemoryState extends State<RsFocusMemory> {
  final _items = <Object, FocusNode>{};
  Object? _last;
  bool _hadFocus = false;
  bool _redirecting = false;

  late final FocusNode _groupNode = FocusNode(
    debugLabel: 'RsFocusMemory',
    canRequestFocus: false,
    skipTraversal: true,
  );

  void _attach(Object id, FocusNode node) => _items[id] = node;

  void _detach(Object id, FocusNode node) {
    if (identical(_items[id], node)) _items.remove(id);
  }

  void _onItemFocus(Object id) {
    if (_redirecting) return;
    final entering = !_hadFocus;
    _hadFocus = true;
    final last = _last;
    if (entering && last != null && last != id) {
      final target = _items[last];
      final focusable = target?.traversalDescendants.firstOrNull;
      if (focusable != null && focusable.context != null) {
        _redirecting = true;
        focusable.requestFocus();
        _redirecting = false;
        return;
      }
    }
    _last = id;
  }

  void _onGroupFocus(bool hasFocus) {
    if (!hasFocus) _hadFocus = false;
  }

  @override
  void dispose() {
    _groupNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _RsFocusMemoryScope(
    state: this,
    child: Focus(
      focusNode: _groupNode,
      onFocusChange: _onGroupFocus,
      child: widget.child,
    ),
  );
}

class _RsFocusMemoryScope extends InheritedWidget {
  const _RsFocusMemoryScope({required this.state, required super.child});

  final _RsFocusMemoryState state;

  @override
  bool updateShouldNotify(_RsFocusMemoryScope oldWidget) => false;
}

/// One remembered child of an [RsFocusMemory], identified by [id] (usually
/// the item index).
class RsFocusMemoryItem extends StatefulWidget {
  const RsFocusMemoryItem({super.key, required this.id, required this.child});

  final Object id;
  final Widget child;

  @override
  State<RsFocusMemoryItem> createState() => _RsFocusMemoryItemState();
}

class _RsFocusMemoryItemState extends State<RsFocusMemoryItem> {
  late final FocusNode _node = FocusNode(
    debugLabel: 'RsFocusMemoryItem',
    canRequestFocus: false,
    skipTraversal: true,
  );
  _RsFocusMemoryState? _memory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final memory = context
        .getInheritedWidgetOfExactType<_RsFocusMemoryScope>()
        ?.state;
    if (memory != _memory) {
      _memory?._detach(widget.id, _node);
      _memory = memory?.._attach(widget.id, _node);
    }
  }

  @override
  void didUpdateWidget(RsFocusMemoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _memory?._detach(oldWidget.id, _node);
      _memory?._attach(widget.id, _node);
    }
  }

  @override
  void dispose() {
    _memory?._detach(widget.id, _node);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    focusNode: _node,
    onFocusChange: (has) {
      if (has) _memory?._onItemFocus(widget.id);
    },
    child: widget.child,
  );
}
