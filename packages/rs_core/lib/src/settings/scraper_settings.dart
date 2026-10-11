import 'package:freezed_annotation/freezed_annotation.dart';

part 'scraper_settings.freezed.dart';
part 'scraper_settings.g.dart';

/// Which scrape providers have credentials stored. Secrets are never included.
@freezed
abstract class ScraperStatus with _$ScraperStatus {
  const factory ScraperStatus({
    required bool screenScraper,
    required bool steamGridDb,
  }) = _ScraperStatus;

  factory ScraperStatus.fromJson(Map<String, Object?> json) =>
      _$ScraperStatusFromJson(json);
}

/// ScreenScraper developer and user login. Every field empty clears the
/// stored login.
@freezed
abstract class ScreenScraperLogin with _$ScreenScraperLogin {
  const factory ScreenScraperLogin({
    required String devId,
    required String devPassword,
    required String username,
    required String password,
  }) = _ScreenScraperLogin;

  factory ScreenScraperLogin.fromJson(Map<String, Object?> json) =>
      _$ScreenScraperLoginFromJson(json);
}

/// `PUT /settings/scrapers`. A null field is left unchanged.
@freezed
abstract class ScraperSettingsUpdate with _$ScraperSettingsUpdate {
  const factory ScraperSettingsUpdate({
    ScreenScraperLogin? screenScraper,
    String? steamGridDbApiKey,
  }) = _ScraperSettingsUpdate;

  factory ScraperSettingsUpdate.fromJson(Map<String, Object?> json) =>
      _$ScraperSettingsUpdateFromJson(json);
}
