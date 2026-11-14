import 'package:flutter/material.dart';

/// User-configurable theme options, edited in the client settings UI and
/// persisted by the app.
@immutable
class RsThemeSettings {
  const RsThemeSettings({
    this.mode = ThemeMode.dark,
    this.accent = defaultAccent,
    this.look = defaultLook,
  });

  factory RsThemeSettings.fromJson(Map<String, Object?> json) =>
      RsThemeSettings(
        mode: ThemeMode.values.asNameMap()[json['mode']] ?? ThemeMode.dark,
        accent: switch (json['accent']) {
          final int argb => Color(argb),
          _ => defaultAccent,
        },
        look: switch (json['look']) {
          final String id when id.isNotEmpty => id,
          _ => defaultLook,
        },
      );

  /// Steam blue.
  static const defaultAccent = Color(0xFF1A9FFF);

  /// ID of the default component set (the Crossblade look).
  static const defaultLook = 'crossblade';

  final ThemeMode mode;
  final Color accent;

  /// ID of the selected component set (look and feel).
  final String look;

  RsThemeSettings copyWith({ThemeMode? mode, Color? accent, String? look}) =>
      RsThemeSettings(
        mode: mode ?? this.mode,
        accent: accent ?? this.accent,
        look: look ?? this.look,
      );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'accent': accent.toARGB32(),
    'look': look,
  };

  @override
  bool operator ==(Object other) =>
      other is RsThemeSettings &&
      other.mode == mode &&
      other.accent == accent &&
      other.look == look;

  @override
  int get hashCode => Object.hash(mode, accent, look);
}
