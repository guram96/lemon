import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Single-line text input with label, hint, error and password mode.
///
/// Typing is never swallowed by `RsInputScope` (Backspace edits, it does not
/// go back). Tab / Shift+Tab and up / down move focus between fields.
class RsTextField extends StatelessWidget {
  const RsTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.obscure = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLength,
    this.icon,
  });

  final TextEditingController? controller;

  /// Shown above the field.
  final String? label;

  /// Placeholder inside the empty field.
  final String? hint;

  /// Muted text below the field; replaced by [errorText] when that is set.
  final String? helperText;

  /// Validation message; non-null puts the field in the error state.
  final String? errorText;

  /// Password mode: hides the text and offers a reveal toggle.
  final bool obscure;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLength;

  /// Leading icon inside the field.
  final IconData? icon;

  /// Keys that `RsInputScope` binds but that belong to the text field while
  /// it has focus (on the web the browser edits the text itself), plus
  /// up / down, which leave this single-line field like a d-pad would.
  static final Map<ShortcutActivator, Intent> typingShortcuts = {
    const SingleActivator(LogicalKeyboardKey.backspace): kIsWeb
        ? const DoNothingAndStopPropagationTextIntent()
        : const DeleteCharacterIntent(forward: false),
    const SingleActivator(
      LogicalKeyboardKey.arrowUp,
    ): const DirectionalFocusIntent(
      TraversalDirection.up,
      ignoreTextFields: false,
    ),
    const SingleActivator(
      LogicalKeyboardKey.arrowDown,
    ): const DirectionalFocusIntent(
      TraversalDirection.down,
      ignoreTextFields: false,
    ),
  };

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: typingShortcuts,
    child: RsComponents.of(context).textField(context, this),
  );
}
