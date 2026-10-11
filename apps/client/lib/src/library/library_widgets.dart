import 'package:flutter/material.dart';
import 'package:rs_api_client/rs_api_client.dart';
import 'package:rs_theme/rs_theme.dart';

/// Centered message panel for loading errors and empty states: icon,
/// title, body, then optional [content] and [actions].
class LibraryMessage extends StatelessWidget {
  const LibraryMessage({
    super.key,
    required this.title,
    this.icon,
    this.body,
    this.content,
    this.actions = const [],
  });

  final IconData? icon;
  final String title;
  final String? body;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = context.rsTokens;
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.rsPageGutter),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.sizes.dialogMaxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: t.sizes.iconLg * 2, color: t.accent),
                SizedBox(height: t.spacing.lg),
              ],
              Text(
                title,
                style: text.headlineMedium?.copyWith(color: t.textPrimary),
              ),
              if (body != null) ...[
                SizedBox(height: t.spacing.sm),
                Text(
                  body!,
                  style: text.bodyLarge?.copyWith(color: t.textSecondary),
                ),
              ],
              if (content != null) ...[
                SizedBox(height: t.spacing.xl),
                content!,
              ],
              if (actions.isNotEmpty) ...[
                SizedBox(height: t.spacing.xl),
                Wrap(
                  spacing: t.spacing.md,
                  runSpacing: t.spacing.md,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Short user-facing text for a failed library request.
String describeLoadError(Object error) {
  if (error is ApiException) {
    if (error.isUnreachable) return 'The server could not be reached.';
    return error.error.message;
  }
  return 'Something went wrong.';
}

/// Whether [error] means the item does not exist (any more).
bool isNotFound(Object? error) =>
    error is ApiException && error.statusCode == 404;
