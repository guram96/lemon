import 'package:flutter/widgets.dart';

import '../component_set.dart';

/// Horizontal progress bar. `value == null` is indeterminate.
class RsProgressBar extends StatelessWidget {
  const RsProgressBar({super.key, this.value, this.label, this.trailing});

  /// 0..1, or `null` for an indeterminate sweep.
  final double? value;

  /// Text above the bar on the left, for example "Scanning snes".
  final String? label;

  /// Text above the bar on the right, for example "312 / 1 204".
  final String? trailing;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).progressBar(context, this);
}

/// Indeterminate activity indicator.
class RsSpinner extends StatelessWidget {
  const RsSpinner({super.key, this.size, this.label});

  /// Diameter; defaults to the set's spinner size.
  final double? size;

  /// Optional text next to the spinner.
  final String? label;

  @override
  Widget build(BuildContext context) =>
      RsComponents.of(context).spinner(context, this);
}
