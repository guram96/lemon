// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'setup_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SetupRequest {

 String get adminUsername;/// At least [minPasswordLength] characters.
 String get adminPassword;/// Absolute path of the data directory.
 String get dataDir;/// Absolute paths of the library roots. At least one.
 List<String> get libraryRoots;/// Name of the setup device, which joins the server automatically.
 String get deviceName;
/// Create a copy of SetupRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetupRequestCopyWith<SetupRequest> get copyWith => _$SetupRequestCopyWithImpl<SetupRequest>(this as SetupRequest, _$identity);

  /// Serializes this SetupRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SetupRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetupRequest&&(identical(other.adminUsername, _this.adminUsername) || other.adminUsername == _this.adminUsername)&&(identical(other.adminPassword, _this.adminPassword) || other.adminPassword == _this.adminPassword)&&(identical(other.dataDir, _this.dataDir) || other.dataDir == _this.dataDir)&&const DeepCollectionEquality().equals(other.libraryRoots, _this.libraryRoots)&&(identical(other.deviceName, _this.deviceName) || other.deviceName == _this.deviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SetupRequest;
  return Object.hash(runtimeType,_this.adminUsername,_this.adminPassword,_this.dataDir,const DeepCollectionEquality().hash(_this.libraryRoots),_this.deviceName);
}

@override
String toString() {
  final _this = this as SetupRequest;
  return 'SetupRequest(adminUsername: ${_this.adminUsername}, adminPassword: ${_this.adminPassword}, dataDir: ${_this.dataDir}, libraryRoots: ${_this.libraryRoots}, deviceName: ${_this.deviceName})';
}


}

/// @nodoc
abstract mixin class $SetupRequestCopyWith<$Res>  {
  factory $SetupRequestCopyWith(SetupRequest value, $Res Function(SetupRequest) _then) = _$SetupRequestCopyWithImpl;
@useResult
$Res call({
 String adminUsername, String adminPassword, String dataDir, List<String> libraryRoots, String deviceName
});




}
/// @nodoc
class _$SetupRequestCopyWithImpl<$Res>
    implements $SetupRequestCopyWith<$Res> {
  _$SetupRequestCopyWithImpl(this._self, this._then);

  final SetupRequest _self;
  final $Res Function(SetupRequest) _then;

/// Create a copy of SetupRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? adminUsername = null,Object? adminPassword = null,Object? dataDir = null,Object? libraryRoots = null,Object? deviceName = null,}) {
  return _then(SetupRequest(
adminUsername: null == adminUsername ? _self.adminUsername : adminUsername // ignore: cast_nullable_to_non_nullable
as String,adminPassword: null == adminPassword ? _self.adminPassword : adminPassword // ignore: cast_nullable_to_non_nullable
as String,dataDir: null == dataDir ? _self.dataDir : dataDir // ignore: cast_nullable_to_non_nullable
as String,libraryRoots: null == libraryRoots ? _self.libraryRoots : libraryRoots // ignore: cast_nullable_to_non_nullable
as List<String>,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SetupRequest].
extension SetupRequestPatterns on SetupRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetupRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetupRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetupRequest value)  $default,){
final _that = this;
switch (_that) {
case _SetupRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetupRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SetupRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String adminUsername,  String adminPassword,  String dataDir,  List<String> libraryRoots,  String deviceName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetupRequest() when $default != null:
return $default(_that.adminUsername,_that.adminPassword,_that.dataDir,_that.libraryRoots,_that.deviceName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String adminUsername,  String adminPassword,  String dataDir,  List<String> libraryRoots,  String deviceName)  $default,) {final _that = this;
switch (_that) {
case _SetupRequest():
return $default(_that.adminUsername,_that.adminPassword,_that.dataDir,_that.libraryRoots,_that.deviceName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String adminUsername,  String adminPassword,  String dataDir,  List<String> libraryRoots,  String deviceName)?  $default,) {final _that = this;
switch (_that) {
case _SetupRequest() when $default != null:
return $default(_that.adminUsername,_that.adminPassword,_that.dataDir,_that.libraryRoots,_that.deviceName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SetupRequest implements SetupRequest {
  const _SetupRequest({required this.adminUsername, required this.adminPassword, required this.dataDir, required  List<String> libraryRoots, required this.deviceName}): _libraryRoots = libraryRoots;
  factory _SetupRequest.fromJson(Map<String, dynamic> json) => _$SetupRequestFromJson(json);

@override final  String adminUsername;
/// At least [minPasswordLength] characters.
@override final  String adminPassword;
/// Absolute path of the data directory.
@override final  String dataDir;
/// Absolute paths of the library roots. At least one.
 final  List<String> _libraryRoots;
/// Absolute paths of the library roots. At least one.
@override List<String> get libraryRoots {
  if (_libraryRoots is EqualUnmodifiableListView) return _libraryRoots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_libraryRoots);
}

/// Name of the setup device, which joins the server automatically.
@override final  String deviceName;

/// Create a copy of SetupRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetupRequestCopyWith<_SetupRequest> get copyWith => __$SetupRequestCopyWithImpl<_SetupRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SetupRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetupRequest&&(identical(other.adminUsername, adminUsername) || other.adminUsername == adminUsername)&&(identical(other.adminPassword, adminPassword) || other.adminPassword == adminPassword)&&(identical(other.dataDir, dataDir) || other.dataDir == dataDir)&&const DeepCollectionEquality().equals(other.libraryRoots, _libraryRoots)&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,adminUsername,adminPassword,dataDir,const DeepCollectionEquality().hash(_libraryRoots),deviceName);
}

@override
String toString() {
    return 'SetupRequest(adminUsername: $adminUsername, adminPassword: $adminPassword, dataDir: $dataDir, libraryRoots: $libraryRoots, deviceName: $deviceName)';
}


}

/// @nodoc
abstract mixin class _$SetupRequestCopyWith<$Res> implements $SetupRequestCopyWith<$Res> {
  factory _$SetupRequestCopyWith(_SetupRequest value, $Res Function(_SetupRequest) _then) = __$SetupRequestCopyWithImpl;
@override @useResult
$Res call({
 String adminUsername, String adminPassword, String dataDir, List<String> libraryRoots, String deviceName
});




}
/// @nodoc
class __$SetupRequestCopyWithImpl<$Res>
    implements _$SetupRequestCopyWith<$Res> {
  __$SetupRequestCopyWithImpl(this._self, this._then);

  final _SetupRequest _self;
  final $Res Function(_SetupRequest) _then;

/// Create a copy of SetupRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? adminUsername = null,Object? adminPassword = null,Object? dataDir = null,Object? libraryRoots = null,Object? deviceName = null,}) {
  return _then(_SetupRequest(
adminUsername: null == adminUsername ? _self.adminUsername : adminUsername // ignore: cast_nullable_to_non_nullable
as String,adminPassword: null == adminPassword ? _self.adminPassword : adminPassword // ignore: cast_nullable_to_non_nullable
as String,dataDir: null == dataDir ? _self.dataDir : dataDir // ignore: cast_nullable_to_non_nullable
as String,libraryRoots: null == libraryRoots ? _self._libraryRoots : libraryRoots // ignore: cast_nullable_to_non_nullable
as List<String>,deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
