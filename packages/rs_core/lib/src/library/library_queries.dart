import 'package:freezed_annotation/freezed_annotation.dart';

import 'game.dart';

part 'library_queries.freezed.dart';
part 'library_queries.g.dart';

/// A system that has at least one game in the library.
@freezed
abstract class SystemSummary with _$SystemSummary {
  const factory SystemSummary({
    /// EmulationStation system ID, see [GameSystems].
    required String systemId,
    required String name,
    required int gameCount,
  }) = _SystemSummary;

  factory SystemSummary.fromJson(Map<String, Object?> json) =>
      _$SystemSummaryFromJson(json);
}

/// Result of a game listing query.
@freezed
abstract class GamePage with _$GamePage {
  const factory GamePage({
    required List<Game> games,

    /// Total number of games matching the query.
    required int total,
  }) = _GamePage;

  factory GamePage.fromJson(Map<String, Object?> json) =>
      _$GamePageFromJson(json);
}
