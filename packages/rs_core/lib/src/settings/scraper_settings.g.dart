// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scraper_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScraperStatus _$ScraperStatusFromJson(Map<String, dynamic> json) =>
    _ScraperStatus(
      screenScraper: json['screenScraper'] as bool,
      steamGridDb: json['steamGridDb'] as bool,
    );

Map<String, dynamic> _$ScraperStatusToJson(_ScraperStatus instance) =>
    <String, dynamic>{
      'screenScraper': instance.screenScraper,
      'steamGridDb': instance.steamGridDb,
    };

_ScreenScraperLogin _$ScreenScraperLoginFromJson(Map<String, dynamic> json) =>
    _ScreenScraperLogin(
      devId: json['devId'] as String,
      devPassword: json['devPassword'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$ScreenScraperLoginToJson(_ScreenScraperLogin instance) =>
    <String, dynamic>{
      'devId': instance.devId,
      'devPassword': instance.devPassword,
      'username': instance.username,
      'password': instance.password,
    };

_ScraperSettingsUpdate _$ScraperSettingsUpdateFromJson(
  Map<String, dynamic> json,
) => _ScraperSettingsUpdate(
  screenScraper: json['screenScraper'] == null
      ? null
      : ScreenScraperLogin.fromJson(
          json['screenScraper'] as Map<String, dynamic>,
        ),
  steamGridDbApiKey: json['steamGridDbApiKey'] as String?,
);

Map<String, dynamic> _$ScraperSettingsUpdateToJson(
  _ScraperSettingsUpdate instance,
) => <String, dynamic>{
  'screenScraper': ?instance.screenScraper?.toJson(),
  'steamGridDbApiKey': ?instance.steamGridDbApiKey,
};
