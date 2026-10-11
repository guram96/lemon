import 'package:flutter/foundation.dart';

/// [LaunchChoice.emulatorId] that runs [LaunchChoice.customCommand].
const customEmulatorId = 'custom';

/// One device-local way to start a game.
///
/// [emulatorId] `custom` requires a non-empty [customCommand]. Any other id
/// must be non-empty. [corePath] and [customCommand] are optional otherwise.
/// Blank text is stored as null. [emulatorId] and [customCommand] are trimmed.
@immutable
class LaunchChoice {
  const LaunchChoice._({
    required this.emulatorId,
    required this.corePath,
    required this.customCommand,
  });

  factory LaunchChoice({
    required String emulatorId,
    String? corePath,
    String? customCommand,
  }) {
    final id = emulatorId.trim();
    final command = _blankToNull(customCommand);
    final core = _blankPath(corePath);
    if (id.isEmpty) {
      throw const FormatException('launch choice emulatorId is empty');
    }
    if (id == customEmulatorId && command == null) {
      throw const FormatException(
        'launch choice custom requires a customCommand',
      );
    }
    return LaunchChoice._(
      emulatorId: id,
      corePath: core,
      customCommand: command,
    );
  }

  final String emulatorId;
  final String? corePath;
  final String? customCommand;

  Map<String, Object?> toJson() => {
    'emulatorId': emulatorId,
    if (corePath != null) 'corePath': corePath,
    if (customCommand != null) 'customCommand': customCommand,
  };

  factory LaunchChoice.fromJson(Map<String, Object?> json) {
    final emulatorId = json['emulatorId'];
    if (emulatorId is! String) {
      throw const FormatException('launch choice emulatorId is not a string');
    }
    return LaunchChoice(
      emulatorId: emulatorId,
      corePath: _optionalJsonString(json, 'corePath'),
      customCommand: _optionalJsonString(json, 'customCommand'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LaunchChoice &&
      other.emulatorId == emulatorId &&
      other.corePath == corePath &&
      other.customCommand == customCommand;

  @override
  int get hashCode => Object.hash(emulatorId, corePath, customCommand);

  @override
  String toString() =>
      'LaunchChoice($emulatorId, core: $corePath, command: $customCommand)';
}

/// Device-local emulator choices. Not the server API.
///
/// [systems] is one [LaunchChoice] per EmulationStation system id.
/// [games] is an optional choice per server id, then game id.
/// [resolve] returns the game choice, otherwise the system choice,
/// otherwise null.
@immutable
class LaunchOptions {
  LaunchOptions({
    Map<String, LaunchChoice> systems = const {},
    Map<String, Map<String, LaunchChoice>> games = const {},
  }) : systems = Map.unmodifiable(Map<String, LaunchChoice>.of(systems)),
       games = _freezeGames(games);

  final Map<String, LaunchChoice> systems;
  final Map<String, Map<String, LaunchChoice>> games;

  LaunchChoice? resolve(String systemId, String serverId, String gameId) {
    final game = games[serverId]?[gameId];
    if (game != null) return game;
    return systems[systemId];
  }

  LaunchOptions withSystem(String systemId, LaunchChoice choice) {
    final next = Map<String, LaunchChoice>.of(systems);
    next[systemId] = choice;
    return LaunchOptions(systems: next, games: games);
  }

  LaunchOptions withoutSystem(String systemId) {
    if (!systems.containsKey(systemId)) return this;
    final next = Map<String, LaunchChoice>.of(systems)..remove(systemId);
    return LaunchOptions(systems: next, games: games);
  }

  LaunchOptions withGame(String serverId, String gameId, LaunchChoice choice) {
    final next = _copyGames(games);
    final serverGames = Map<String, LaunchChoice>.of(
      next[serverId] ?? const {},
    );
    serverGames[gameId] = choice;
    next[serverId] = serverGames;
    return LaunchOptions(systems: systems, games: next);
  }

  LaunchOptions withoutGame(String serverId, String gameId) {
    final serverGames = games[serverId];
    if (serverGames == null || !serverGames.containsKey(gameId)) return this;
    final next = _copyGames(games);
    final remaining = Map<String, LaunchChoice>.of(next[serverId] ?? const {})
      ..remove(gameId);
    if (remaining.isEmpty) {
      next.remove(serverId);
    } else {
      next[serverId] = remaining;
    }
    return LaunchOptions(systems: systems, games: next);
  }

  Map<String, Object?> toJson() => {
    'systems': {
      for (final entry in systems.entries) entry.key: entry.value.toJson(),
    },
    'games': {
      for (final server in games.entries)
        server.key: {
          for (final game in server.value.entries)
            game.key: game.value.toJson(),
        },
    },
  };

  factory LaunchOptions.fromJson(Map<String, Object?> json) => LaunchOptions(
    systems: _choicesFromJson(json['systems'], 'systems'),
    games: _gamesFromJson(json['games']),
  );

  @override
  bool operator ==(Object other) =>
      other is LaunchOptions &&
      mapEquals(other.systems, systems) &&
      _sameGames(other.games, games);

  @override
  int get hashCode => Object.hash(_choiceMapHash(systems), _gamesHash(games));

  @override
  String toString() => 'LaunchOptions(systems: $systems, games: $games)';
}

Map<String, Map<String, LaunchChoice>> _copyGames(
  Map<String, Map<String, LaunchChoice>> games,
) => {
  for (final entry in games.entries)
    entry.key: Map<String, LaunchChoice>.of(entry.value),
};

Map<String, Map<String, LaunchChoice>> _freezeGames(
  Map<String, Map<String, LaunchChoice>> games,
) => Map.unmodifiable({
  for (final entry in games.entries)
    entry.key: Map<String, LaunchChoice>.unmodifiable(
      Map<String, LaunchChoice>.of(entry.value),
    ),
});

bool _sameGames(
  Map<String, Map<String, LaunchChoice>> a,
  Map<String, Map<String, LaunchChoice>> b,
) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null || !mapEquals(other, entry.value)) return false;
  }
  return true;
}

int _choiceMapHash(Map<String, LaunchChoice> map) {
  final keys = map.keys.toList()..sort();
  return Object.hashAll([for (final key in keys) Object.hash(key, map[key])]);
}

int _gamesHash(Map<String, Map<String, LaunchChoice>> games) {
  final servers = games.keys.toList()..sort();
  return Object.hashAll([
    for (final server in servers)
      Object.hash(server, _choiceMapHash(games[server]!)),
  ]);
}

String? _blankToNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}

/// Whitespace-only paths are absent. Any other path is kept as given.
String? _blankPath(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

String? _optionalJsonString(Map<String, Object?> json, String key) {
  if (!json.containsKey(key) || json[key] == null) return null;
  final value = json[key];
  if (value is! String) {
    throw FormatException('launch choice $key is not a string');
  }
  return value;
}

Map<String, LaunchChoice> _choicesFromJson(Object? raw, String field) {
  if (raw == null) return const {};
  if (raw is! Map) {
    throw FormatException('launch options $field is not an object');
  }
  final choices = <String, LaunchChoice>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    if (key is! String) {
      throw FormatException('launch options $field key is not a string');
    }
    choices[key] = LaunchChoice.fromJson(_asMap(entry.value, field));
  }
  return choices;
}

Map<String, Map<String, LaunchChoice>> _gamesFromJson(Object? raw) {
  if (raw == null) return const {};
  if (raw is! Map) {
    throw const FormatException('launch options games is not an object');
  }
  final games = <String, Map<String, LaunchChoice>>{};
  for (final server in raw.entries) {
    final serverId = server.key;
    if (serverId is! String) {
      throw const FormatException('launch options server id is not a string');
    }
    final serverGames = server.value;
    if (serverGames is! Map) {
      throw const FormatException(
        'launch options games for a server is not an object',
      );
    }
    final byGame = <String, LaunchChoice>{};
    for (final game in serverGames.entries) {
      final gameId = game.key;
      if (gameId is! String) {
        throw const FormatException('launch options game id is not a string');
      }
      byGame[gameId] = LaunchChoice.fromJson(_asMap(game.value, 'games'));
    }
    if (byGame.isNotEmpty) games[serverId] = byGame;
  }
  return games;
}

Map<String, Object?> _asMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('launch store field $field is not an object');
  }
  return Map<String, Object?>.from(value);
}
