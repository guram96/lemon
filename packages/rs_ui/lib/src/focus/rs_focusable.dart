import 'package:flutter/widgets.dart';

/// Interaction state passed to [RsFocusable.builder].
@immutable
class RsFocusState {
  const RsFocusState({
    required this.focused,
    required this.hovered,
    required this.pressed,
    required this.enabled,
  });

  final bool focused;
  final bool hovered;
  final bool pressed;
  final bool enabled;

  /// Whether to draw the highlighted look: focused by controller or keyboard,
  /// or hovered by a mouse.
  bool get highlighted => enabled && (focused || hovered);
}

/// The single focus and activation primitive used by every component set.
///
/// Handles keyboard / d-pad focus, controller and keyboard activation
/// (via [ActivateIntent]), mouse hover and touch, and scrolls itself into
/// view when focused.
class RsFocusable extends StatefulWidget {
  const RsFocusable({
    super.key,
    required this.builder,
    required this.onActivate,
    this.autofocus = false,
    this.focusNode,
    this.onFocusChanged,
    this.semanticLabel,
  });

  final Widget Function(BuildContext context, RsFocusState state) builder;

  /// `null` makes the widget disabled but still focusable, so controller
  /// navigation does not skip over it unexpectedly.
  final VoidCallback? onActivate;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChanged;
  final String? semanticLabel;

  @override
  State<RsFocusable> createState() => _RsFocusableState();
}

class _RsFocusableState extends State<RsFocusable> {
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  late final Map<Type, Action<Intent>> _actions = {
    ActivateIntent: CallbackAction<ActivateIntent>(
      onInvoke: (_) => _activate(),
    ),
  };

  void _activate() => widget.onActivate?.call();

  void _onFocus(bool focused) {
    setState(() => _focused = focused);
    widget.onFocusChanged?.call(focused);
    if (focused) {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onActivate != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        actions: _actions,
        onShowFocusHighlight: _onFocus,
        onShowHoverHighlight: (h) => setState(() => _hovered = h),
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTap: enabled ? _activate : null,
          child: widget.builder(
            context,
            RsFocusState(
              focused: _focused,
              hovered: _hovered,
              pressed: _pressed,
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
  }
}
