// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scraper_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScraperStatus {

 bool get screenScraper; bool get steamGridDb;
/// Create a copy of ScraperStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScraperStatusCopyWith<ScraperStatus> get copyWith => _$ScraperStatusCopyWithImpl<ScraperStatus>(this as ScraperStatus, _$identity);

  /// Serializes this ScraperStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScraperStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScraperStatus&&(identical(other.screenScraper, _this.screenScraper) || other.screenScraper == _this.screenScraper)&&(identical(other.steamGridDb, _this.steamGridDb) || other.steamGridDb == _this.steamGridDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScraperStatus;
  return Object.hash(runtimeType,_this.screenScraper,_this.steamGridDb);
}

@override
String toString() {
  final _this = this as ScraperStatus;
  return 'ScraperStatus(screenScraper: ${_this.screenScraper}, steamGridDb: ${_this.steamGridDb})';
}


}

/// @nodoc
abstract mixin class $ScraperStatusCopyWith<$Res>  {
  factory $ScraperStatusCopyWith(ScraperStatus value, $Res Function(ScraperStatus) _then) = _$ScraperStatusCopyWithImpl;
@useResult
$Res call({
 bool screenScraper, bool steamGridDb
});




}
/// @nodoc
class _$ScraperStatusCopyWithImpl<$Res>
    implements $ScraperStatusCopyWith<$Res> {
  _$ScraperStatusCopyWithImpl(this._self, this._then);

  final ScraperStatus _self;
  final $Res Function(ScraperStatus) _then;

/// Create a copy of ScraperStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenScraper = null,Object? steamGridDb = null,}) {
  return _then(ScraperStatus(
screenScraper: null == screenScraper ? _self.screenScraper : screenScraper // ignore: cast_nullable_to_non_nullable
as bool,steamGridDb: null == steamGridDb ? _self.steamGridDb : steamGridDb // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScraperStatus].
extension ScraperStatusPatterns on ScraperStatus {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScraperStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScraperStatus() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScraperStatus value)  $default,){
final _that = this;
switch (_that) {
case _ScraperStatus():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScraperStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ScraperStatus() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool screenScraper,  bool steamGridDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScraperStatus() when $default != null:
return $default(_that.screenScraper,_that.steamGridDb);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool screenScraper,  bool steamGridDb)  $default,) {final _that = this;
switch (_that) {
case _ScraperStatus():
return $default(_that.screenScraper,_that.steamGridDb);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool screenScraper,  bool steamGridDb)?  $default,) {final _that = this;
switch (_that) {
case _ScraperStatus() when $default != null:
return $default(_that.screenScraper,_that.steamGridDb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScraperStatus implements ScraperStatus {
  const _ScraperStatus({required this.screenScraper, required this.steamGridDb});
  factory _ScraperStatus.fromJson(Map<String, dynamic> json) => _$ScraperStatusFromJson(json);

@override final  bool screenScraper;
@override final  bool steamGridDb;

/// Create a copy of ScraperStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScraperStatusCopyWith<_ScraperStatus> get copyWith => __$ScraperStatusCopyWithImpl<_ScraperStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScraperStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScraperStatus&&(identical(other.screenScraper, screenScraper) || other.screenScraper == screenScraper)&&(identical(other.steamGridDb, steamGridDb) || other.steamGridDb == steamGridDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,screenScraper,steamGridDb);
}

@override
String toString() {
    return 'ScraperStatus(screenScraper: $screenScraper, steamGridDb: $steamGridDb)';
}


}

/// @nodoc
abstract mixin class _$ScraperStatusCopyWith<$Res> implements $ScraperStatusCopyWith<$Res> {
  factory _$ScraperStatusCopyWith(_ScraperStatus value, $Res Function(_ScraperStatus) _then) = __$ScraperStatusCopyWithImpl;
@override @useResult
$Res call({
 bool screenScraper, bool steamGridDb
});




}
/// @nodoc
class __$ScraperStatusCopyWithImpl<$Res>
    implements _$ScraperStatusCopyWith<$Res> {
  __$ScraperStatusCopyWithImpl(this._self, this._then);

  final _ScraperStatus _self;
  final $Res Function(_ScraperStatus) _then;

/// Create a copy of ScraperStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenScraper = null,Object? steamGridDb = null,}) {
  return _then(_ScraperStatus(
screenScraper: null == screenScraper ? _self.screenScraper : screenScraper // ignore: cast_nullable_to_non_nullable
as bool,steamGridDb: null == steamGridDb ? _self.steamGridDb : steamGridDb // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ScreenScraperLogin {

 String get devId; String get devPassword; String get username; String get password;
/// Create a copy of ScreenScraperLogin
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenScraperLoginCopyWith<ScreenScraperLogin> get copyWith => _$ScreenScraperLoginCopyWithImpl<ScreenScraperLogin>(this as ScreenScraperLogin, _$identity);

  /// Serializes this ScreenScraperLogin to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScreenScraperLogin;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenScraperLogin&&(identical(other.devId, _this.devId) || other.devId == _this.devId)&&(identical(other.devPassword, _this.devPassword) || other.devPassword == _this.devPassword)&&(identical(other.username, _this.username) || other.username == _this.username)&&(identical(other.password, _this.password) || other.password == _this.password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScreenScraperLogin;
  return Object.hash(runtimeType,_this.devId,_this.devPassword,_this.username,_this.password);
}

@override
String toString() {
  final _this = this as ScreenScraperLogin;
  return 'ScreenScraperLogin(devId: ${_this.devId}, devPassword: ${_this.devPassword}, username: ${_this.username}, password: ${_this.password})';
}


}

/// @nodoc
abstract mixin class $ScreenScraperLoginCopyWith<$Res>  {
  factory $ScreenScraperLoginCopyWith(ScreenScraperLogin value, $Res Function(ScreenScraperLogin) _then) = _$ScreenScraperLoginCopyWithImpl;
@useResult
$Res call({
 String devId, String devPassword, String username, String password
});




}
/// @nodoc
class _$ScreenScraperLoginCopyWithImpl<$Res>
    implements $ScreenScraperLoginCopyWith<$Res> {
  _$ScreenScraperLoginCopyWithImpl(this._self, this._then);

  final ScreenScraperLogin _self;
  final $Res Function(ScreenScraperLogin) _then;

/// Create a copy of ScreenScraperLogin
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? devId = null,Object? devPassword = null,Object? username = null,Object? password = null,}) {
  return _then(ScreenScraperLogin(
devId: null == devId ? _self.devId : devId // ignore: cast_nullable_to_non_nullable
as String,devPassword: null == devPassword ? _self.devPassword : devPassword // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScreenScraperLogin].
extension ScreenScraperLoginPatterns on ScreenScraperLogin {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScreenScraperLogin value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScreenScraperLogin() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScreenScraperLogin value)  $default,){
final _that = this;
switch (_that) {
case _ScreenScraperLogin():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScreenScraperLogin value)?  $default,){
final _that = this;
switch (_that) {
case _ScreenScraperLogin() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String devId,  String devPassword,  String username,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScreenScraperLogin() when $default != null:
return $default(_that.devId,_that.devPassword,_that.username,_that.password);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String devId,  String devPassword,  String username,  String password)  $default,) {final _that = this;
switch (_that) {
case _ScreenScraperLogin():
return $default(_that.devId,_that.devPassword,_that.username,_that.password);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String devId,  String devPassword,  String username,  String password)?  $default,) {final _that = this;
switch (_that) {
case _ScreenScraperLogin() when $default != null:
return $default(_that.devId,_that.devPassword,_that.username,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScreenScraperLogin implements ScreenScraperLogin {
  const _ScreenScraperLogin({required this.devId, required this.devPassword, required this.username, required this.password});
  factory _ScreenScraperLogin.fromJson(Map<String, dynamic> json) => _$ScreenScraperLoginFromJson(json);

@override final  String devId;
@override final  String devPassword;
@override final  String username;
@override final  String password;

/// Create a copy of ScreenScraperLogin
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScreenScraperLoginCopyWith<_ScreenScraperLogin> get copyWith => __$ScreenScraperLoginCopyWithImpl<_ScreenScraperLogin>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScreenScraperLoginToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScreenScraperLogin&&(identical(other.devId, devId) || other.devId == devId)&&(identical(other.devPassword, devPassword) || other.devPassword == devPassword)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,devId,devPassword,username,password);
}

@override
String toString() {
    return 'ScreenScraperLogin(devId: $devId, devPassword: $devPassword, username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class _$ScreenScraperLoginCopyWith<$Res> implements $ScreenScraperLoginCopyWith<$Res> {
  factory _$ScreenScraperLoginCopyWith(_ScreenScraperLogin value, $Res Function(_ScreenScraperLogin) _then) = __$ScreenScraperLoginCopyWithImpl;
@override @useResult
$Res call({
 String devId, String devPassword, String username, String password
});




}
/// @nodoc
class __$ScreenScraperLoginCopyWithImpl<$Res>
    implements _$ScreenScraperLoginCopyWith<$Res> {
  __$ScreenScraperLoginCopyWithImpl(this._self, this._then);

  final _ScreenScraperLogin _self;
  final $Res Function(_ScreenScraperLogin) _then;

/// Create a copy of ScreenScraperLogin
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? devId = null,Object? devPassword = null,Object? username = null,Object? password = null,}) {
  return _then(_ScreenScraperLogin(
devId: null == devId ? _self.devId : devId // ignore: cast_nullable_to_non_nullable
as String,devPassword: null == devPassword ? _self.devPassword : devPassword // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ScraperSettingsUpdate {

 ScreenScraperLogin? get screenScraper; String? get steamGridDbApiKey;
/// Create a copy of ScraperSettingsUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScraperSettingsUpdateCopyWith<ScraperSettingsUpdate> get copyWith => _$ScraperSettingsUpdateCopyWithImpl<ScraperSettingsUpdate>(this as ScraperSettingsUpdate, _$identity);

  /// Serializes this ScraperSettingsUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScraperSettingsUpdate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScraperSettingsUpdate&&(identical(other.screenScraper, _this.screenScraper) || other.screenScraper == _this.screenScraper)&&(identical(other.steamGridDbApiKey, _this.steamGridDbApiKey) || other.steamGridDbApiKey == _this.steamGridDbApiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScraperSettingsUpdate;
  return Object.hash(runtimeType,_this.screenScraper,_this.steamGridDbApiKey);
}

@override
String toString() {
  final _this = this as ScraperSettingsUpdate;
  return 'ScraperSettingsUpdate(screenScraper: ${_this.screenScraper}, steamGridDbApiKey: ${_this.steamGridDbApiKey})';
}


}

/// @nodoc
abstract mixin class $ScraperSettingsUpdateCopyWith<$Res>  {
  factory $ScraperSettingsUpdateCopyWith(ScraperSettingsUpdate value, $Res Function(ScraperSettingsUpdate) _then) = _$ScraperSettingsUpdateCopyWithImpl;
@useResult
$Res call({
 ScreenScraperLogin? screenScraper, String? steamGridDbApiKey
});


$ScreenScraperLoginCopyWith<$Res>? get screenScraper;

}
/// @nodoc
class _$ScraperSettingsUpdateCopyWithImpl<$Res>
    implements $ScraperSettingsUpdateCopyWith<$Res> {
  _$ScraperSettingsUpdateCopyWithImpl(this._self, this._then);

  final ScraperSettingsUpdate _self;
  final $Res Function(ScraperSettingsUpdate) _then;

/// Create a copy of ScraperSettingsUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenScraper = freezed,Object? steamGridDbApiKey = freezed,}) {
  return _then(ScraperSettingsUpdate(
screenScraper: freezed == screenScraper ? _self.screenScraper : screenScraper // ignore: cast_nullable_to_non_nullable
as ScreenScraperLogin?,steamGridDbApiKey: freezed == steamGridDbApiKey ? _self.steamGridDbApiKey : steamGridDbApiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ScraperSettingsUpdate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenScraperLoginCopyWith<$Res>? get screenScraper {
    if (_self.screenScraper == null) {
    return null;
  }

  return $ScreenScraperLoginCopyWith<$Res>(_self.screenScraper!, (value) {
    return _then(_self.copyWith(screenScraper: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScraperSettingsUpdate].
extension ScraperSettingsUpdatePatterns on ScraperSettingsUpdate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScraperSettingsUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScraperSettingsUpdate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScraperSettingsUpdate value)  $default,){
final _that = this;
switch (_that) {
case _ScraperSettingsUpdate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScraperSettingsUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _ScraperSettingsUpdate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScreenScraperLogin? screenScraper,  String? steamGridDbApiKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScraperSettingsUpdate() when $default != null:
return $default(_that.screenScraper,_that.steamGridDbApiKey);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScreenScraperLogin? screenScraper,  String? steamGridDbApiKey)  $default,) {final _that = this;
switch (_that) {
case _ScraperSettingsUpdate():
return $default(_that.screenScraper,_that.steamGridDbApiKey);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScreenScraperLogin? screenScraper,  String? steamGridDbApiKey)?  $default,) {final _that = this;
switch (_that) {
case _ScraperSettingsUpdate() when $default != null:
return $default(_that.screenScraper,_that.steamGridDbApiKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScraperSettingsUpdate implements ScraperSettingsUpdate {
  const _ScraperSettingsUpdate({this.screenScraper, this.steamGridDbApiKey});
  factory _ScraperSettingsUpdate.fromJson(Map<String, dynamic> json) => _$ScraperSettingsUpdateFromJson(json);

@override final  ScreenScraperLogin? screenScraper;
@override final  String? steamGridDbApiKey;

/// Create a copy of ScraperSettingsUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScraperSettingsUpdateCopyWith<_ScraperSettingsUpdate> get copyWith => __$ScraperSettingsUpdateCopyWithImpl<_ScraperSettingsUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScraperSettingsUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScraperSettingsUpdate&&(identical(other.screenScraper, screenScraper) || other.screenScraper == screenScraper)&&(identical(other.steamGridDbApiKey, steamGridDbApiKey) || other.steamGridDbApiKey == steamGridDbApiKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,screenScraper,steamGridDbApiKey);
}

@override
String toString() {
    return 'ScraperSettingsUpdate(screenScraper: $screenScraper, steamGridDbApiKey: $steamGridDbApiKey)';
}


}

/// @nodoc
abstract mixin class _$ScraperSettingsUpdateCopyWith<$Res> implements $ScraperSettingsUpdateCopyWith<$Res> {
  factory _$ScraperSettingsUpdateCopyWith(_ScraperSettingsUpdate value, $Res Function(_ScraperSettingsUpdate) _then) = __$ScraperSettingsUpdateCopyWithImpl;
@override @useResult
$Res call({
 ScreenScraperLogin? screenScraper, String? steamGridDbApiKey
});


@override $ScreenScraperLoginCopyWith<$Res>? get screenScraper;

}
/// @nodoc
class __$ScraperSettingsUpdateCopyWithImpl<$Res>
    implements _$ScraperSettingsUpdateCopyWith<$Res> {
  __$ScraperSettingsUpdateCopyWithImpl(this._self, this._then);

  final _ScraperSettingsUpdate _self;
  final $Res Function(_ScraperSettingsUpdate) _then;

/// Create a copy of ScraperSettingsUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenScraper = freezed,Object? steamGridDbApiKey = freezed,}) {
  return _then(_ScraperSettingsUpdate(
screenScraper: freezed == screenScraper ? _self.screenScraper : screenScraper // ignore: cast_nullable_to_non_nullable
as ScreenScraperLogin?,steamGridDbApiKey: freezed == steamGridDbApiKey ? _self.steamGridDbApiKey : steamGridDbApiKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ScraperSettingsUpdate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenScraperLoginCopyWith<$Res>? get screenScraper {
    if (_self.screenScraper == null) {
    return null;
  }

  return $ScreenScraperLoginCopyWith<$Res>(_self.screenScraper!, (value) {
    return _then(_self.copyWith(screenScraper: value));
  });
}
}

// dart format on
