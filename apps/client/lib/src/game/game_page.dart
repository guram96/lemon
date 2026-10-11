import 'package:flutter/widgets.dart';

/// Stub from T6. T8 replaces this file's contents (keep the class name and
/// the `gameId` constructor parameter).
///
/// Lives inside the main shell (`AppShell`): return only the page body, no
/// `RsScaffold`. The body extends behind the top bar.
class GameDetailPage extends StatelessWidget {
  const GameDetailPage({super.key, required this.gameId});

  /// From the `/game/:id` path.
  final String gameId;

  @override
  Widget build(BuildContext context) => Center(child: Text('Game $gameId'));
}
