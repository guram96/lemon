import 'package:rs_core/rs_core.dart';

import '../db/auth_repos.dart';
import '../scrape/screenscraper/screenscraper_client.dart';

/// Settings keys for scrape credentials. Values are the secrets themselves.
abstract final class ScraperSettingKeys {
  static const screenScraperDevId = 'scrapers.screenscraper.devId';
  static const screenScraperDevPassword = 'scrapers.screenscraper.devPassword';
  static const screenScraperUsername = 'scrapers.screenscraper.username';
  static const screenScraperPassword = 'scrapers.screenscraper.password';
  static const steamGridDbApiKey = 'scrapers.steamgriddb.apiKey';
}

/// Stored scrape logins. Empty when that provider is not configured.
class ScraperCredentials {
  const ScraperCredentials({this.screenScraper, this.steamGridDbApiKey});

  final ScreenScraperCredentials? screenScraper;
  final String? steamGridDbApiKey;

  ScraperStatus get status => ScraperStatus(
    screenScraper: screenScraper != null,
    steamGridDb: steamGridDbApiKey != null,
  );

  static ScraperCredentials read(SettingsRepo settings) {
    final devId = settings.get(ScraperSettingKeys.screenScraperDevId);
    final devPassword = settings.get(
      ScraperSettingKeys.screenScraperDevPassword,
    );
    final username = settings.get(ScraperSettingKeys.screenScraperUsername);
    final password = settings.get(ScraperSettingKeys.screenScraperPassword);
    final complete =
        _present(devId) &&
        _present(devPassword) &&
        _present(username) &&
        _present(password);
    final apiKey = settings.get(ScraperSettingKeys.steamGridDbApiKey);
    return ScraperCredentials(
      screenScraper: complete
          ? ScreenScraperCredentials(
              devId: devId!,
              devPassword: devPassword!,
              username: username!,
              password: password!,
            )
          : null,
      steamGridDbApiKey: _present(apiKey) ? apiKey : null,
    );
  }

  /// Applies [update]. A null field is left as stored. An empty SteamGridDB
  /// key, or a ScreenScraper login whose fields are all empty, clears that
  /// provider.
  static void apply(SettingsRepo settings, ScraperSettingsUpdate update) {
    final login = update.screenScraper;
    if (login != null) {
      final fields = [
        login.devId,
        login.devPassword,
        login.username,
        login.password,
      ];
      if (fields.every((field) => field.isEmpty)) {
        settings.remove(ScraperSettingKeys.screenScraperDevId);
        settings.remove(ScraperSettingKeys.screenScraperDevPassword);
        settings.remove(ScraperSettingKeys.screenScraperUsername);
        settings.remove(ScraperSettingKeys.screenScraperPassword);
      } else if (fields.any((field) => field.isEmpty)) {
        throw const ScraperSettingsException(
          'ScreenScraper credentials are incomplete.',
        );
      } else {
        settings.set(ScraperSettingKeys.screenScraperDevId, login.devId);
        settings.set(
          ScraperSettingKeys.screenScraperDevPassword,
          login.devPassword,
        );
        settings.set(ScraperSettingKeys.screenScraperUsername, login.username);
        settings.set(ScraperSettingKeys.screenScraperPassword, login.password);
      }
    }
    final apiKey = update.steamGridDbApiKey;
    if (apiKey == null) return;
    if (apiKey.isEmpty) {
      settings.remove(ScraperSettingKeys.steamGridDbApiKey);
    } else {
      settings.set(ScraperSettingKeys.steamGridDbApiKey, apiKey);
    }
  }

  static bool _present(String? value) => value != null && value.isNotEmpty;
}

class ScraperSettingsException implements Exception {
  const ScraperSettingsException(this.message);

  final String message;

  @override
  String toString() => 'ScraperSettingsException: $message';
}
