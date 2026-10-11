import 'package:flutter/material.dart';

/// User-configurable theme options, edited in the client settings UI and
/// persisted by the app.
@immutable
class RsThemeSettings {
  const RsThemeSettings({
    this.mode = ThemeMode.dark,
    this.accent = defaultAccent,
  });

  factory RsThemeSettings.fromJson(Map<String, Object?> json) =>
      RsThemeSettings(
        mode: ThemeMode.values.asNameMap()[json['mode']] ?? ThemeMode.dark,
        accent: switch (json['accent']) {
          final int argb => Color(argb),
          _ => defaultAccent,
        },
      );

  /// Steam blue.
  static const defaultAccent = Color(0xFF1A9FFF);

  final ThemeMode mode;
  final Color accent;

  RsThemeSettings copyWith({ThemeMode? mode, Color? accent}) =>
      RsThemeSettings(mode: mode ?? this.mode, accent: accent ?? this.accent);

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'accent': accent.toARGB32(),
  };

  @override
  bool operator ==(Object other) =>
      other is RsThemeSettings && other.mode == mode && other.accent == accent;

  @override
  int get hashCode => Object.hash(mode, accent);
}
