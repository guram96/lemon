import 'dart:async';

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rs_core/rs_core.dart';
import 'package:rs_theme/rs_theme.dart';

import '../events/scan_status_provider.dart';

/// One notification. Shown as a toast while in
/// [NotificationCenterState.toasts]; transient ones also go to the history
/// behind the bell.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.body,
    this.icon,
    this.progress,
    this.indeterminate = false,
    this.persistent = false,
  });

  /// Showing a notification with an existing id replaces it in place.
  final String id;
  final String title;
  final String? body;
  final IconData? icon;

  /// 0..1 progress bar.
  final double? progress;
  final bool indeterminate;

  /// Stays until replaced or dismissed in code (progress toasts). Otherwise
  /// the toast hides after [NotificationCenter.toastHold] and is recorded in
  /// the history.
  final bool persistent;

  @override
  bool operator ==(Object other) =>
      other is AppNotification &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.icon == icon &&
      other.progress == progress &&
      other.indeterminate == indeterminate &&
      other.persistent == persistent;

  @override
  int get hashCode =>
      Object.hash(id, title, body, icon, progress, indeterminate, persistent);

  @override
  String toString() => 'AppNotification($id, $title, $body)';
}

@immutable
class NotificationCenterState {
  const NotificationCenterState({
    this.toasts = const [],
    this.history = const [],
    this.unreadCount = 0,
  });

  /// On screen now, oldest first.
  final List<AppNotification> toasts;

  /// Past transient notifications, newest first.
  final List<AppNotification> history;

  /// Badge on the top bar's bell.
  final int unreadCount;

  NotificationCenterState copyWith({
    List<AppNotification>? toasts,
    List<AppNotification>? history,
    int? unreadCount,
  }) => NotificationCenterState(
    toasts: toasts ?? this.toasts,
    history: history ?? this.history,
    unreadCount: unreadCount ?? this.unreadCount,
  );
}

final notificationCenterProvider =
    NotifierProvider<NotificationCenter, NotificationCenterState>(
      NotificationCenter.new,
    );

/// App-wide notifications (toasts bottom-right + bell history).
///
/// Also turns library scans into toasts: one persistent progress toast that
/// updates in place, replaced by a summary (or error) toast when the scan
/// ends.
class NotificationCenter extends Notifier<NotificationCenterState> {
  /// Id of the scan progress / summary toast.
  static const scanToastId = 'scan';
  static const historyLimit = 50;

  /// How long transient toasts stay. Kept in sync with
  /// `RsMotion.toastHold` by the notification host.
  Duration toastHold = const RsMotion().toastHold;

  final _timers = <String, Timer>{};

  @override
  NotificationCenterState build() {
    ref.listen(scanStatusProvider, _onScan);
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const NotificationCenterState();
  }

  /// Shows [notification], replacing a visible one with the same id in place.
  void show(AppNotification notification) {
    _timers.remove(notification.id)?.cancel();
    final toasts = [...state.toasts];
    final index = toasts.indexWhere((n) => n.id == notification.id);
    if (index >= 0) {
      toasts[index] = notification;
    } else {
      toasts.add(notification);
    }
    var history = state.history;
    var unread = state.unreadCount;
    if (!notification.persistent) {
      history = [notification, ...history].take(historyLimit).toList();
      unread++;
      _timers[notification.id] = Timer(
        toastHold,
        () => dismiss(notification.id),
      );
    }
    state = state.copyWith(
      toasts: toasts,
      history: history,
      unreadCount: unread,
    );
  }

  /// Hides the toast with [id] (history is kept).
  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    if (!ref.mounted) return;
    if (!state.toasts.any((n) => n.id == id)) return;
    state = state.copyWith(
      toasts: [
        for (final n in state.toasts)
          if (n.id != id) n,
      ],
    );
  }

  /// Clears the bell badge.
  void markAllRead() {
    if (state.unreadCount != 0) state = state.copyWith(unreadCount: 0);
  }

  void _onScan(ScanStatus? previous, ScanStatus next) {
    if (next.isRunning) {
      show(scanProgressNotification(next));
      return;
    }
    final wasRunning = previous?.isRunning ?? false;
    switch (next.phase) {
      case ScanPhase.done when wasRunning:
        show(scanSummaryNotification(next));
      case ScanPhase.failed when wasRunning:
        show(
          AppNotification(
            id: scanToastId,
            title: 'Library scan failed',
            body: next.error ?? 'Something went wrong while scanning.',
            icon: Icons.error_outline_rounded,
          ),
        );
      default:
        // Logged out or reset: drop a progress toast that can't finish.
        if (state.toasts.any((n) => n.id == scanToastId && n.persistent)) {
          dismiss(scanToastId);
        }
    }
  }

  @visibleForTesting
  static AppNotification scanProgressNotification(ScanStatus s) {
    final system = switch (s.currentSystemId) {
      final id? => GameSystems.byId(id)?.name ?? id,
      null => null,
    };
    final counting = s.phase == ScanPhase.discovering || s.total == 0;
    return AppNotification(
      id: scanToastId,
      title: 'Scanning library',
      body: counting
          ? (system == null ? 'Looking for games…' : 'Looking in $system…')
          : ['${s.processed} / ${s.total} files', ?system].join(' · '),
      icon: Icons.sync_rounded,
      progress: counting ? null : (s.processed / s.total).clamp(0.0, 1.0),
      indeterminate: counting,
      persistent: true,
    );
  }

  @visibleForTesting
  static AppNotification scanSummaryNotification(ScanStatus s) {
    String games(int n) => n == 1 ? '1 game' : '$n games';
    final parts = [
      '${games(s.added)} added',
      if (s.updated > 0) '${s.updated} updated',
      if (s.removed > 0) '${s.removed} removed',
    ];
    return AppNotification(
      id: scanToastId,
      title: 'Library updated',
      body: parts.join(' · '),
      icon: Icons.videogame_asset_rounded,
    );
  }
}
