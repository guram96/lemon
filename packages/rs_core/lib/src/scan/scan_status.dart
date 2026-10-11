import 'package:freezed_annotation/freezed_annotation.dart';

part 'scan_status.freezed.dart';
part 'scan_status.g.dart';

enum ScanPhase { idle, discovering, hashing, saving, done, failed }

/// Progress of the current or last library scan.
@freezed
abstract class ScanStatus with _$ScanStatus {
  const ScanStatus._();

  const factory ScanStatus({
    required ScanPhase phase,

    /// Files processed so far.
    @Default(0) int processed,

    /// Files found in total. `0` while discovering.
    @Default(0) int total,
    String? currentSystemId,
    String? currentFile,
    @Default(0) int added,
    @Default(0) int updated,
    @Default(0) int removed,
    DateTime? startedAt,
    DateTime? finishedAt,

    /// Set when [phase] is [ScanPhase.failed].
    String? error,
  }) = _ScanStatus;

  factory ScanStatus.fromJson(Map<String, Object?> json) =>
      _$ScanStatusFromJson(json);

  /// No scan has run yet.
  static const idle = ScanStatus(phase: ScanPhase.idle);

  bool get isRunning => switch (phase) {
    ScanPhase.discovering || ScanPhase.hashing || ScanPhase.saving => true,
    ScanPhase.idle || ScanPhase.done || ScanPhase.failed => false,
  };
}
