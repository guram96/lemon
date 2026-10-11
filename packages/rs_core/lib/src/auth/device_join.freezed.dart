// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device_join.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeviceJoinRequest {

 String get deviceName;/// `macos`, `windows`, `linux`, `android`, `ios` or `web`.
 String get platform;
/// Create a copy of DeviceJoinRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceJoinRequestCopyWith<DeviceJoinRequest> get copyWith => _$DeviceJoinRequestCopyWithImpl<DeviceJoinRequest>(this as DeviceJoinRequest, _$identity);

  /// Serializes this DeviceJoinRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceJoinRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceJoinRequest&&(identical(other.deviceName, _this.deviceName) || other.deviceName == _this.deviceName)&&(identical(other.platform, _this.platform) || other.platform == _this.platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceJoinRequest;
  return Object.hash(runtimeType,_this.deviceName,_this.platform);
}

@override
String toString() {
  final _this = this as DeviceJoinRequest;
  return 'DeviceJoinRequest(deviceName: ${_this.deviceName}, platform: ${_this.platform})';
}


}

/// @nodoc
abstract mixin class $DeviceJoinRequestCopyWith<$Res>  {
  factory $DeviceJoinRequestCopyWith(DeviceJoinRequest value, $Res Function(DeviceJoinRequest) _then) = _$DeviceJoinRequestCopyWithImpl;
@useResult
$Res call({
 String deviceName, String platform
});




}
/// @nodoc
class _$DeviceJoinRequestCopyWithImpl<$Res>
    implements $DeviceJoinRequestCopyWith<$Res> {
  _$DeviceJoinRequestCopyWithImpl(this._self, this._then);

  final DeviceJoinRequest _self;
  final $Res Function(DeviceJoinRequest) _then;

/// Create a copy of DeviceJoinRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceName = null,Object? platform = null,}) {
  return _then(DeviceJoinRequest(
deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceJoinRequest].
extension DeviceJoinRequestPatterns on DeviceJoinRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceJoinRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceJoinRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceJoinRequest value)  $default,){
final _that = this;
switch (_that) {
case _DeviceJoinRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceJoinRequest value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceJoinRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceName,  String platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceJoinRequest() when $default != null:
return $default(_that.deviceName,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceName,  String platform)  $default,) {final _that = this;
switch (_that) {
case _DeviceJoinRequest():
return $default(_that.deviceName,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceName,  String platform)?  $default,) {final _that = this;
switch (_that) {
case _DeviceJoinRequest() when $default != null:
return $default(_that.deviceName,_that.platform);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceJoinRequest implements DeviceJoinRequest {
  const _DeviceJoinRequest({required this.deviceName, required this.platform});
  factory _DeviceJoinRequest.fromJson(Map<String, dynamic> json) => _$DeviceJoinRequestFromJson(json);

@override final  String deviceName;
/// `macos`, `windows`, `linux`, `android`, `ios` or `web`.
@override final  String platform;

/// Create a copy of DeviceJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceJoinRequestCopyWith<_DeviceJoinRequest> get copyWith => __$DeviceJoinRequestCopyWithImpl<_DeviceJoinRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceJoinRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceJoinRequest&&(identical(other.deviceName, deviceName) || other.deviceName == deviceName)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deviceName,platform);
}

@override
String toString() {
    return 'DeviceJoinRequest(deviceName: $deviceName, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$DeviceJoinRequestCopyWith<$Res> implements $DeviceJoinRequestCopyWith<$Res> {
  factory _$DeviceJoinRequestCopyWith(_DeviceJoinRequest value, $Res Function(_DeviceJoinRequest) _then) = __$DeviceJoinRequestCopyWithImpl;
@override @useResult
$Res call({
 String deviceName, String platform
});




}
/// @nodoc
class __$DeviceJoinRequestCopyWithImpl<$Res>
    implements _$DeviceJoinRequestCopyWith<$Res> {
  __$DeviceJoinRequestCopyWithImpl(this._self, this._then);

  final _DeviceJoinRequest _self;
  final $Res Function(_DeviceJoinRequest) _then;

/// Create a copy of DeviceJoinRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceName = null,Object? platform = null,}) {
  return _then(_DeviceJoinRequest(
deviceName: null == deviceName ? _self.deviceName : deviceName // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DeviceJoinResult {

 String get deviceId;/// Sent as [ApiHeaders.device] from now on.
 String get deviceToken;
/// Create a copy of DeviceJoinResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceJoinResultCopyWith<DeviceJoinResult> get copyWith => _$DeviceJoinResultCopyWithImpl<DeviceJoinResult>(this as DeviceJoinResult, _$identity);

  /// Serializes this DeviceJoinResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DeviceJoinResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceJoinResult&&(identical(other.deviceId, _this.deviceId) || other.deviceId == _this.deviceId)&&(identical(other.deviceToken, _this.deviceToken) || other.deviceToken == _this.deviceToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DeviceJoinResult;
  return Object.hash(runtimeType,_this.deviceId,_this.deviceToken);
}

@override
String toString() {
  final _this = this as DeviceJoinResult;
  return 'DeviceJoinResult(deviceId: ${_this.deviceId}, deviceToken: ${_this.deviceToken})';
}


}

/// @nodoc
abstract mixin class $DeviceJoinResultCopyWith<$Res>  {
  factory $DeviceJoinResultCopyWith(DeviceJoinResult value, $Res Function(DeviceJoinResult) _then) = _$DeviceJoinResultCopyWithImpl;
@useResult
$Res call({
 String deviceId, String deviceToken
});




}
/// @nodoc
class _$DeviceJoinResultCopyWithImpl<$Res>
    implements $DeviceJoinResultCopyWith<$Res> {
  _$DeviceJoinResultCopyWithImpl(this._self, this._then);

  final DeviceJoinResult _self;
  final $Res Function(DeviceJoinResult) _then;

/// Create a copy of DeviceJoinResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceId = null,Object? deviceToken = null,}) {
  return _then(DeviceJoinResult(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeviceJoinResult].
extension DeviceJoinResultPatterns on DeviceJoinResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceJoinResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceJoinResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceJoinResult value)  $default,){
final _that = this;
switch (_that) {
case _DeviceJoinResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceJoinResult value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceJoinResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceId,  String deviceToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceJoinResult() when $default != null:
return $default(_that.deviceId,_that.deviceToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceId,  String deviceToken)  $default,) {final _that = this;
switch (_that) {
case _DeviceJoinResult():
return $default(_that.deviceId,_that.deviceToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceId,  String deviceToken)?  $default,) {final _that = this;
switch (_that) {
case _DeviceJoinResult() when $default != null:
return $default(_that.deviceId,_that.deviceToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceJoinResult implements DeviceJoinResult {
  const _DeviceJoinResult({required this.deviceId, required this.deviceToken});
  factory _DeviceJoinResult.fromJson(Map<String, dynamic> json) => _$DeviceJoinResultFromJson(json);

@override final  String deviceId;
/// Sent as [ApiHeaders.device] from now on.
@override final  String deviceToken;

/// Create a copy of DeviceJoinResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceJoinResultCopyWith<_DeviceJoinResult> get copyWith => __$DeviceJoinResultCopyWithImpl<_DeviceJoinResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceJoinResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceJoinResult&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.deviceToken, deviceToken) || other.deviceToken == deviceToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,deviceId,deviceToken);
}

@override
String toString() {
    return 'DeviceJoinResult(deviceId: $deviceId, deviceToken: $deviceToken)';
}


}

/// @nodoc
abstract mixin class _$DeviceJoinResultCopyWith<$Res> implements $DeviceJoinResultCopyWith<$Res> {
  factory _$DeviceJoinResultCopyWith(_DeviceJoinResult value, $Res Function(_DeviceJoinResult) _then) = __$DeviceJoinResultCopyWithImpl;
@override @useResult
$Res call({
 String deviceId, String deviceToken
});




}
/// @nodoc
class __$DeviceJoinResultCopyWithImpl<$Res>
    implements _$DeviceJoinResultCopyWith<$Res> {
  __$DeviceJoinResultCopyWithImpl(this._self, this._then);

  final _DeviceJoinResult _self;
  final $Res Function(_DeviceJoinResult) _then;

/// Create a copy of DeviceJoinResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceId = null,Object? deviceToken = null,}) {
  return _then(_DeviceJoinResult(
deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,deviceToken: null == deviceToken ? _self.deviceToken : deviceToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
