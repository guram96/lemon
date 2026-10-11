import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';
import 'package:rs_ui/rs_ui.dart';

import '../session/session_provider.dart';
import 'format.dart';
import 'library_providers.dart';
import 'library_widgets.dart';

/// Empty-library copy. Games show up on the shelves as a scan finds them.
const scanningLibraryMessage =
    "Scanning your library — games appear as they're found";

/// First-load stand-in. Static on purpose: a spinner or an indeterminate
/// bar never finishes, and `pumpAndSettle` would time out.
class LibraryLoading extends StatelessWidget {
  const LibraryLoading({super.key, this.label = 'Loading your library'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Text(
        label,
        style: text.bodyLarge?.copyWith(color: context.rsTokens.textSecondary),
      ),
    );
  }
}

/// Failed library request. A 401 is handed to the session and draws nothing,
/// because the shell is already on its way to the login page.
class LibraryLoadError extends ConsumerStatefulWidget {
  const LibraryLoadError({
    super.key,
    required this.error,
    this.title = "Couldn't load the library",
    this.notFoundTitle,
    this.notFoundBody,
  });

  final Object error;
  final String title;

  /// When set, a 404 uses this copy instead of [title].
  final String? notFoundTitle;
  final String? notFoundBody;

  @override
  ConsumerState<LibraryLoadError> createState() => _LibraryLoadErrorState();
}

class _LibraryLoadErrorState extends ConsumerState<LibraryLoadError> {
  Object? _reported;

  @override
  void initState() {
    super.initState();
    _report();
  }

  @override
  void didUpdateWidget(LibraryLoadError oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.error, widget.error)) _report();
  }

  void _report() {
    if (identical(_reported, widget.error)) return;
    _reported = widget.error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(sessionProvider.notifier).handleApiError(widget.error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    if (error is ApiException && error.statusCode == 401) {
      return const SizedBox.shrink();
    }
    final missing = widget.notFoundTitle;
    if (missing != null && isNotFound(error)) {
      return LibraryMessage(
        icon: Icons.search_off_rounded,
        title: missing,
        body: widget.notFoundBody,
      );
    }
    return LibraryMessage(
      icon: Icons.cloud_off_outlined,
      title: widget.title,
      body: describeLoadError(error),
    );
  }
}

/// Loading or error body for a library request.
///
/// Returns null once [async] has a value, including while a refetch is in
/// flight, so the screen keeps showing the previous list.
Widget? libraryPlaceholder<T>(
  AsyncValue<T> async, {
  String title = "Couldn't load the library",
  String? notFoundTitle,
  String? notFoundBody,
  String loadingLabel = 'Loading your library',
}) {
  if (async.hasValue) return null;
  if (async.hasError) {
    return LibraryLoadError(
      error: async.error!,
      title: title,
      notFoundTitle: notFoundTitle,
      notFoundBody: notFoundBody,
    );
  }
  return LibraryLoading(label: loadingLabel);
}

/// Determinate scan progress, or null when there is nothing to measure.
///
/// An unknown total (still discovering) draws no bar: an indeterminate
/// [RsProgressBar] animates forever.
Widget? libraryScanBar(ScanStatus status, List<SystemSummary> systems) {
  if (!status.isRunning || status.total <= 0) return null;
  final id = status.currentSystemId;
  final value = (status.processed / status.total).clamp(0.0, 1.0).toDouble();
  return RsProgressBar(
    value: value,
    label: id == null ? 'Scanning' : 'Scanning ${systemName(id, systems)}',
    trailing: '${formatCount(status.processed)} / ${formatCount(status.total)}',
  );
}
