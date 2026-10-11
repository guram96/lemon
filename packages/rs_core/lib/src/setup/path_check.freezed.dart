// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'path_check.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PathCheckRequest {

 String get path; PathKind get kind;
/// Create a copy of PathCheckRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCheckRequestCopyWith<PathCheckRequest> get copyWith => _$PathCheckRequestCopyWithImpl<PathCheckRequest>(this as PathCheckRequest, _$identity);

  /// Serializes this PathCheckRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PathCheckRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCheckRequest&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.kind, _this.kind) || other.kind == _this.kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PathCheckRequest;
  return Object.hash(runtimeType,_this.path,_this.kind);
}

@override
String toString() {
  final _this = this as PathCheckRequest;
  return 'PathCheckRequest(path: ${_this.path}, kind: ${_this.kind})';
}


}

/// @nodoc
abstract mixin class $PathCheckRequestCopyWith<$Res>  {
  factory $PathCheckRequestCopyWith(PathCheckRequest value, $Res Function(PathCheckRequest) _then) = _$PathCheckRequestCopyWithImpl;
@useResult
$Res call({
 String path, PathKind kind
});




}
/// @nodoc
class _$PathCheckRequestCopyWithImpl<$Res>
    implements $PathCheckRequestCopyWith<$Res> {
  _$PathCheckRequestCopyWithImpl(this._self, this._then);

  final PathCheckRequest _self;
  final $Res Function(PathCheckRequest) _then;

/// Create a copy of PathCheckRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? kind = null,}) {
  return _then(PathCheckRequest(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PathKind,
  ));
}

}


/// Adds pattern-matching-related methods to [PathCheckRequest].
extension PathCheckRequestPatterns on PathCheckRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathCheckRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathCheckRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathCheckRequest value)  $default,){
final _that = this;
switch (_that) {
case _PathCheckRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathCheckRequest value)?  $default,){
final _that = this;
switch (_that) {
case _PathCheckRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  PathKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathCheckRequest() when $default != null:
return $default(_that.path,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  PathKind kind)  $default,) {final _that = this;
switch (_that) {
case _PathCheckRequest():
return $default(_that.path,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  PathKind kind)?  $default,) {final _that = this;
switch (_that) {
case _PathCheckRequest() when $default != null:
return $default(_that.path,_that.kind);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathCheckRequest implements PathCheckRequest {
  const _PathCheckRequest({required this.path, required this.kind});
  factory _PathCheckRequest.fromJson(Map<String, dynamic> json) => _$PathCheckRequestFromJson(json);

@override final  String path;
@override final  PathKind kind;

/// Create a copy of PathCheckRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathCheckRequestCopyWith<_PathCheckRequest> get copyWith => __$PathCheckRequestCopyWithImpl<_PathCheckRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathCheckRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathCheckRequest&&(identical(other.path, path) || other.path == path)&&(identical(other.kind, kind) || other.kind == kind));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path,kind);
}

@override
String toString() {
    return 'PathCheckRequest(path: $path, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$PathCheckRequestCopyWith<$Res> implements $PathCheckRequestCopyWith<$Res> {
  factory _$PathCheckRequestCopyWith(_PathCheckRequest value, $Res Function(_PathCheckRequest) _then) = __$PathCheckRequestCopyWithImpl;
@override @useResult
$Res call({
 String path, PathKind kind
});




}
/// @nodoc
class __$PathCheckRequestCopyWithImpl<$Res>
    implements _$PathCheckRequestCopyWith<$Res> {
  __$PathCheckRequestCopyWithImpl(this._self, this._then);

  final _PathCheckRequest _self;
  final $Res Function(_PathCheckRequest) _then;

/// Create a copy of PathCheckRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? kind = null,}) {
  return _then(_PathCheckRequest(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PathKind,
  ));
}


}


/// @nodoc
mixin _$DetectedSystem {

/// EmulationStation system ID, see [GameSystems].
 String get systemId; int get fileCount;
/// Create a copy of DetectedSystem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectedSystemCopyWith<DetectedSystem> get copyWith => _$DetectedSystemCopyWithImpl<DetectedSystem>(this as DetectedSystem, _$identity);

  /// Serializes this DetectedSystem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DetectedSystem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectedSystem&&(identical(other.systemId, _this.systemId) || other.systemId == _this.systemId)&&(identical(other.fileCount, _this.fileCount) || other.fileCount == _this.fileCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DetectedSystem;
  return Object.hash(runtimeType,_this.systemId,_this.fileCount);
}

@override
String toString() {
  final _this = this as DetectedSystem;
  return 'DetectedSystem(systemId: ${_this.systemId}, fileCount: ${_this.fileCount})';
}


}

/// @nodoc
abstract mixin class $DetectedSystemCopyWith<$Res>  {
  factory $DetectedSystemCopyWith(DetectedSystem value, $Res Function(DetectedSystem) _then) = _$DetectedSystemCopyWithImpl;
@useResult
$Res call({
 String systemId, int fileCount
});




}
/// @nodoc
class _$DetectedSystemCopyWithImpl<$Res>
    implements $DetectedSystemCopyWith<$Res> {
  _$DetectedSystemCopyWithImpl(this._self, this._then);

  final DetectedSystem _self;
  final $Res Function(DetectedSystem) _then;

/// Create a copy of DetectedSystem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? systemId = null,Object? fileCount = null,}) {
  return _then(DetectedSystem(
systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DetectedSystem].
extension DetectedSystemPatterns on DetectedSystem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetectedSystem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetectedSystem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetectedSystem value)  $default,){
final _that = this;
switch (_that) {
case _DetectedSystem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetectedSystem value)?  $default,){
final _that = this;
switch (_that) {
case _DetectedSystem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String systemId,  int fileCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetectedSystem() when $default != null:
return $default(_that.systemId,_that.fileCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String systemId,  int fileCount)  $default,) {final _that = this;
switch (_that) {
case _DetectedSystem():
return $default(_that.systemId,_that.fileCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String systemId,  int fileCount)?  $default,) {final _that = this;
switch (_that) {
case _DetectedSystem() when $default != null:
return $default(_that.systemId,_that.fileCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetectedSystem implements DetectedSystem {
  const _DetectedSystem({required this.systemId, required this.fileCount});
  factory _DetectedSystem.fromJson(Map<String, dynamic> json) => _$DetectedSystemFromJson(json);

/// EmulationStation system ID, see [GameSystems].
@override final  String systemId;
@override final  int fileCount;

/// Create a copy of DetectedSystem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetectedSystemCopyWith<_DetectedSystem> get copyWith => __$DetectedSystemCopyWithImpl<_DetectedSystem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetectedSystemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetectedSystem&&(identical(other.systemId, systemId) || other.systemId == systemId)&&(identical(other.fileCount, fileCount) || other.fileCount == fileCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,systemId,fileCount);
}

@override
String toString() {
    return 'DetectedSystem(systemId: $systemId, fileCount: $fileCount)';
}


}

/// @nodoc
abstract mixin class _$DetectedSystemCopyWith<$Res> implements $DetectedSystemCopyWith<$Res> {
  factory _$DetectedSystemCopyWith(_DetectedSystem value, $Res Function(_DetectedSystem) _then) = __$DetectedSystemCopyWithImpl;
@override @useResult
$Res call({
 String systemId, int fileCount
});




}
/// @nodoc
class __$DetectedSystemCopyWithImpl<$Res>
    implements _$DetectedSystemCopyWith<$Res> {
  __$DetectedSystemCopyWithImpl(this._self, this._then);

  final _DetectedSystem _self;
  final $Res Function(_DetectedSystem) _then;

/// Create a copy of DetectedSystem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? systemId = null,Object? fileCount = null,}) {
  return _then(_DetectedSystem(
systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,fileCount: null == fileCount ? _self.fileCount : fileCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PathCheckResult {

/// Normalized absolute path.
 String get path;/// The kind that was checked, echoed from [PathCheckRequest.kind].
 PathKind get kind; bool get exists; bool get readable;/// For a missing [PathKind.dataDir], whether it can be created.
 bool get writable;/// The OS refused access (macOS TCC, ACLs). The client shows how to grant
/// it.
 bool get permissionDenied;/// ID from an existing `.retrosteam/root.json`: the folder can be adopted.
 String? get existingMarkerId;/// System folders found. Only for [PathKind.libraryRoot].
 List<DetectedSystem> get detectedSystems; int? get freeBytes;/// Human-readable notes, for example "read-only filesystem", "not empty".
 List<String> get warnings;
/// Create a copy of PathCheckResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PathCheckResultCopyWith<PathCheckResult> get copyWith => _$PathCheckResultCopyWithImpl<PathCheckResult>(this as PathCheckResult, _$identity);

  /// Serializes this PathCheckResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PathCheckResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PathCheckResult&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.exists, _this.exists) || other.exists == _this.exists)&&(identical(other.readable, _this.readable) || other.readable == _this.readable)&&(identical(other.writable, _this.writable) || other.writable == _this.writable)&&(identical(other.permissionDenied, _this.permissionDenied) || other.permissionDenied == _this.permissionDenied)&&(identical(other.existingMarkerId, _this.existingMarkerId) || other.existingMarkerId == _this.existingMarkerId)&&const DeepCollectionEquality().equals(other.detectedSystems, _this.detectedSystems)&&(identical(other.freeBytes, _this.freeBytes) || other.freeBytes == _this.freeBytes)&&const DeepCollectionEquality().equals(other.warnings, _this.warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PathCheckResult;
  return Object.hash(runtimeType,_this.path,_this.kind,_this.exists,_this.readable,_this.writable,_this.permissionDenied,_this.existingMarkerId,const DeepCollectionEquality().hash(_this.detectedSystems),_this.freeBytes,const DeepCollectionEquality().hash(_this.warnings));
}

@override
String toString() {
  final _this = this as PathCheckResult;
  return 'PathCheckResult(path: ${_this.path}, kind: ${_this.kind}, exists: ${_this.exists}, readable: ${_this.readable}, writable: ${_this.writable}, permissionDenied: ${_this.permissionDenied}, existingMarkerId: ${_this.existingMarkerId}, detectedSystems: ${_this.detectedSystems}, freeBytes: ${_this.freeBytes}, warnings: ${_this.warnings})';
}


}

/// @nodoc
abstract mixin class $PathCheckResultCopyWith<$Res>  {
  factory $PathCheckResultCopyWith(PathCheckResult value, $Res Function(PathCheckResult) _then) = _$PathCheckResultCopyWithImpl;
@useResult
$Res call({
 String path, PathKind kind, bool exists, bool readable, bool writable, bool permissionDenied, String? existingMarkerId, List<DetectedSystem> detectedSystems, int? freeBytes, List<String> warnings
});




}
/// @nodoc
class _$PathCheckResultCopyWithImpl<$Res>
    implements $PathCheckResultCopyWith<$Res> {
  _$PathCheckResultCopyWithImpl(this._self, this._then);

  final PathCheckResult _self;
  final $Res Function(PathCheckResult) _then;

/// Create a copy of PathCheckResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? kind = null,Object? exists = null,Object? readable = null,Object? writable = null,Object? permissionDenied = null,Object? existingMarkerId = freezed,Object? detectedSystems = null,Object? freeBytes = freezed,Object? warnings = null,}) {
  return _then(PathCheckResult(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PathKind,exists: null == exists ? _self.exists : exists // ignore: cast_nullable_to_non_nullable
as bool,readable: null == readable ? _self.readable : readable // ignore: cast_nullable_to_non_nullable
as bool,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,permissionDenied: null == permissionDenied ? _self.permissionDenied : permissionDenied // ignore: cast_nullable_to_non_nullable
as bool,existingMarkerId: freezed == existingMarkerId ? _self.existingMarkerId : existingMarkerId // ignore: cast_nullable_to_non_nullable
as String?,detectedSystems: null == detectedSystems ? _self.detectedSystems : detectedSystems // ignore: cast_nullable_to_non_nullable
as List<DetectedSystem>,freeBytes: freezed == freeBytes ? _self.freeBytes : freeBytes // ignore: cast_nullable_to_non_nullable
as int?,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [PathCheckResult].
extension PathCheckResultPatterns on PathCheckResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PathCheckResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PathCheckResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PathCheckResult value)  $default,){
final _that = this;
switch (_that) {
case _PathCheckResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PathCheckResult value)?  $default,){
final _that = this;
switch (_that) {
case _PathCheckResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  PathKind kind,  bool exists,  bool readable,  bool writable,  bool permissionDenied,  String? existingMarkerId,  List<DetectedSystem> detectedSystems,  int? freeBytes,  List<String> warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PathCheckResult() when $default != null:
return $default(_that.path,_that.kind,_that.exists,_that.readable,_that.writable,_that.permissionDenied,_that.existingMarkerId,_that.detectedSystems,_that.freeBytes,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  PathKind kind,  bool exists,  bool readable,  bool writable,  bool permissionDenied,  String? existingMarkerId,  List<DetectedSystem> detectedSystems,  int? freeBytes,  List<String> warnings)  $default,) {final _that = this;
switch (_that) {
case _PathCheckResult():
return $default(_that.path,_that.kind,_that.exists,_that.readable,_that.writable,_that.permissionDenied,_that.existingMarkerId,_that.detectedSystems,_that.freeBytes,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  PathKind kind,  bool exists,  bool readable,  bool writable,  bool permissionDenied,  String? existingMarkerId,  List<DetectedSystem> detectedSystems,  int? freeBytes,  List<String> warnings)?  $default,) {final _that = this;
switch (_that) {
case _PathCheckResult() when $default != null:
return $default(_that.path,_that.kind,_that.exists,_that.readable,_that.writable,_that.permissionDenied,_that.existingMarkerId,_that.detectedSystems,_that.freeBytes,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PathCheckResult extends PathCheckResult {
  const _PathCheckResult({required this.path, required this.kind, required this.exists, required this.readable, required this.writable, this.permissionDenied = false, this.existingMarkerId,  List<DetectedSystem> detectedSystems = const [], this.freeBytes,  List<String> warnings = const []}): _detectedSystems = detectedSystems,_warnings = warnings,super._();
  factory _PathCheckResult.fromJson(Map<String, dynamic> json) => _$PathCheckResultFromJson(json);

/// Normalized absolute path.
@override final  String path;
/// The kind that was checked, echoed from [PathCheckRequest.kind].
@override final  PathKind kind;
@override final  bool exists;
@override final  bool readable;
/// For a missing [PathKind.dataDir], whether it can be created.
@override final  bool writable;
/// The OS refused access (macOS TCC, ACLs). The client shows how to grant
/// it.
@override@JsonKey() final  bool permissionDenied;
/// ID from an existing `.retrosteam/root.json`: the folder can be adopted.
@override final  String? existingMarkerId;
/// System folders found. Only for [PathKind.libraryRoot].
 final  List<DetectedSystem> _detectedSystems;
/// System folders found. Only for [PathKind.libraryRoot].
@override@JsonKey() List<DetectedSystem> get detectedSystems {
  if (_detectedSystems is EqualUnmodifiableListView) return _detectedSystems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detectedSystems);
}

@override final  int? freeBytes;
/// Human-readable notes, for example "read-only filesystem", "not empty".
 final  List<String> _warnings;
/// Human-readable notes, for example "read-only filesystem", "not empty".
@override@JsonKey() List<String> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}


/// Create a copy of PathCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PathCheckResultCopyWith<_PathCheckResult> get copyWith => __$PathCheckResultCopyWithImpl<_PathCheckResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PathCheckResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PathCheckResult&&(identical(other.path, path) || other.path == path)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.exists, exists) || other.exists == exists)&&(identical(other.readable, readable) || other.readable == readable)&&(identical(other.writable, writable) || other.writable == writable)&&(identical(other.permissionDenied, permissionDenied) || other.permissionDenied == permissionDenied)&&(identical(other.existingMarkerId, existingMarkerId) || other.existingMarkerId == existingMarkerId)&&const DeepCollectionEquality().equals(other.detectedSystems, _detectedSystems)&&(identical(other.freeBytes, freeBytes) || other.freeBytes == freeBytes)&&const DeepCollectionEquality().equals(other.warnings, _warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path,kind,exists,readable,writable,permissionDenied,existingMarkerId,const DeepCollectionEquality().hash(_detectedSystems),freeBytes,const DeepCollectionEquality().hash(_warnings));
}

@override
String toString() {
    return 'PathCheckResult(path: $path, kind: $kind, exists: $exists, readable: $readable, writable: $writable, permissionDenied: $permissionDenied, existingMarkerId: $existingMarkerId, detectedSystems: $detectedSystems, freeBytes: $freeBytes, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$PathCheckResultCopyWith<$Res> implements $PathCheckResultCopyWith<$Res> {
  factory _$PathCheckResultCopyWith(_PathCheckResult value, $Res Function(_PathCheckResult) _then) = __$PathCheckResultCopyWithImpl;
@override @useResult
$Res call({
 String path, PathKind kind, bool exists, bool readable, bool writable, bool permissionDenied, String? existingMarkerId, List<DetectedSystem> detectedSystems, int? freeBytes, List<String> warnings
});




}
/// @nodoc
class __$PathCheckResultCopyWithImpl<$Res>
    implements _$PathCheckResultCopyWith<$Res> {
  __$PathCheckResultCopyWithImpl(this._self, this._then);

  final _PathCheckResult _self;
  final $Res Function(_PathCheckResult) _then;

/// Create a copy of PathCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? kind = null,Object? exists = null,Object? readable = null,Object? writable = null,Object? permissionDenied = null,Object? existingMarkerId = freezed,Object? detectedSystems = null,Object? freeBytes = freezed,Object? warnings = null,}) {
  return _then(_PathCheckResult(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PathKind,exists: null == exists ? _self.exists : exists // ignore: cast_nullable_to_non_nullable
as bool,readable: null == readable ? _self.readable : readable // ignore: cast_nullable_to_non_nullable
as bool,writable: null == writable ? _self.writable : writable // ignore: cast_nullable_to_non_nullable
as bool,permissionDenied: null == permissionDenied ? _self.permissionDenied : permissionDenied // ignore: cast_nullable_to_non_nullable
as bool,existingMarkerId: freezed == existingMarkerId ? _self.existingMarkerId : existingMarkerId // ignore: cast_nullable_to_non_nullable
as String?,detectedSystems: null == detectedSystems ? _self._detectedSystems : detectedSystems // ignore: cast_nullable_to_non_nullable
as List<DetectedSystem>,freeBytes: freezed == freeBytes ? _self.freeBytes : freeBytes // ignore: cast_nullable_to_non_nullable
as int?,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
