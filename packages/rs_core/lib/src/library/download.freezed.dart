// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadFile {

 int get index;/// Path relative to the game's system folder, using `/` separators.
 String get path; int get sizeBytes; String? get sha1;
/// Create a copy of DownloadFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadFileCopyWith<DownloadFile> get copyWith => _$DownloadFileCopyWithImpl<DownloadFile>(this as DownloadFile, _$identity);

  /// Serializes this DownloadFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DownloadFile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadFile&&(identical(other.index, _this.index) || other.index == _this.index)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha1, _this.sha1) || other.sha1 == _this.sha1));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DownloadFile;
  return Object.hash(runtimeType,_this.index,_this.path,_this.sizeBytes,_this.sha1);
}

@override
String toString() {
  final _this = this as DownloadFile;
  return 'DownloadFile(index: ${_this.index}, path: ${_this.path}, sizeBytes: ${_this.sizeBytes}, sha1: ${_this.sha1})';
}


}

/// @nodoc
abstract mixin class $DownloadFileCopyWith<$Res>  {
  factory $DownloadFileCopyWith(DownloadFile value, $Res Function(DownloadFile) _then) = _$DownloadFileCopyWithImpl;
@useResult
$Res call({
 int index, String path, int sizeBytes, String? sha1
});




}
/// @nodoc
class _$DownloadFileCopyWithImpl<$Res>
    implements $DownloadFileCopyWith<$Res> {
  _$DownloadFileCopyWithImpl(this._self, this._then);

  final DownloadFile _self;
  final $Res Function(DownloadFile) _then;

/// Create a copy of DownloadFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? index = null,Object? path = null,Object? sizeBytes = null,Object? sha1 = freezed,}) {
  return _then(DownloadFile(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha1: freezed == sha1 ? _self.sha1 : sha1 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadFile].
extension DownloadFilePatterns on DownloadFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadFile value)  $default,){
final _that = this;
switch (_that) {
case _DownloadFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadFile value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int index,  String path,  int sizeBytes,  String? sha1)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadFile() when $default != null:
return $default(_that.index,_that.path,_that.sizeBytes,_that.sha1);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int index,  String path,  int sizeBytes,  String? sha1)  $default,) {final _that = this;
switch (_that) {
case _DownloadFile():
return $default(_that.index,_that.path,_that.sizeBytes,_that.sha1);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int index,  String path,  int sizeBytes,  String? sha1)?  $default,) {final _that = this;
switch (_that) {
case _DownloadFile() when $default != null:
return $default(_that.index,_that.path,_that.sizeBytes,_that.sha1);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadFile implements DownloadFile {
  const _DownloadFile({required this.index, required this.path, required this.sizeBytes, this.sha1});
  factory _DownloadFile.fromJson(Map<String, dynamic> json) => _$DownloadFileFromJson(json);

@override final  int index;
/// Path relative to the game's system folder, using `/` separators.
@override final  String path;
@override final  int sizeBytes;
@override final  String? sha1;

/// Create a copy of DownloadFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadFileCopyWith<_DownloadFile> get copyWith => __$DownloadFileCopyWithImpl<_DownloadFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadFileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadFile&&(identical(other.index, index) || other.index == index)&&(identical(other.path, path) || other.path == path)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha1, sha1) || other.sha1 == sha1));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,index,path,sizeBytes,sha1);
}

@override
String toString() {
    return 'DownloadFile(index: $index, path: $path, sizeBytes: $sizeBytes, sha1: $sha1)';
}


}

/// @nodoc
abstract mixin class _$DownloadFileCopyWith<$Res> implements $DownloadFileCopyWith<$Res> {
  factory _$DownloadFileCopyWith(_DownloadFile value, $Res Function(_DownloadFile) _then) = __$DownloadFileCopyWithImpl;
@override @useResult
$Res call({
 int index, String path, int sizeBytes, String? sha1
});




}
/// @nodoc
class __$DownloadFileCopyWithImpl<$Res>
    implements _$DownloadFileCopyWith<$Res> {
  __$DownloadFileCopyWithImpl(this._self, this._then);

  final _DownloadFile _self;
  final $Res Function(_DownloadFile) _then;

/// Create a copy of DownloadFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? index = null,Object? path = null,Object? sizeBytes = null,Object? sha1 = freezed,}) {
  return _then(_DownloadFile(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha1: freezed == sha1 ? _self.sha1 : sha1 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DownloadManifest {

 String get gameId; String get systemId; List<DownloadFile> get files;
/// Create a copy of DownloadManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadManifestCopyWith<DownloadManifest> get copyWith => _$DownloadManifestCopyWithImpl<DownloadManifest>(this as DownloadManifest, _$identity);

  /// Serializes this DownloadManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DownloadManifest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadManifest&&(identical(other.gameId, _this.gameId) || other.gameId == _this.gameId)&&(identical(other.systemId, _this.systemId) || other.systemId == _this.systemId)&&const DeepCollectionEquality().equals(other.files, _this.files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DownloadManifest;
  return Object.hash(runtimeType,_this.gameId,_this.systemId,const DeepCollectionEquality().hash(_this.files));
}

@override
String toString() {
  final _this = this as DownloadManifest;
  return 'DownloadManifest(gameId: ${_this.gameId}, systemId: ${_this.systemId}, files: ${_this.files})';
}


}

/// @nodoc
abstract mixin class $DownloadManifestCopyWith<$Res>  {
  factory $DownloadManifestCopyWith(DownloadManifest value, $Res Function(DownloadManifest) _then) = _$DownloadManifestCopyWithImpl;
@useResult
$Res call({
 String gameId, String systemId, List<DownloadFile> files
});




}
/// @nodoc
class _$DownloadManifestCopyWithImpl<$Res>
    implements $DownloadManifestCopyWith<$Res> {
  _$DownloadManifestCopyWithImpl(this._self, this._then);

  final DownloadManifest _self;
  final $Res Function(DownloadManifest) _then;

/// Create a copy of DownloadManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gameId = null,Object? systemId = null,Object? files = null,}) {
  return _then(DownloadManifest(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<DownloadFile>,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadManifest].
extension DownloadManifestPatterns on DownloadManifest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadManifest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadManifest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadManifest value)  $default,){
final _that = this;
switch (_that) {
case _DownloadManifest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadManifest value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadManifest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gameId,  String systemId,  List<DownloadFile> files)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadManifest() when $default != null:
return $default(_that.gameId,_that.systemId,_that.files);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gameId,  String systemId,  List<DownloadFile> files)  $default,) {final _that = this;
switch (_that) {
case _DownloadManifest():
return $default(_that.gameId,_that.systemId,_that.files);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gameId,  String systemId,  List<DownloadFile> files)?  $default,) {final _that = this;
switch (_that) {
case _DownloadManifest() when $default != null:
return $default(_that.gameId,_that.systemId,_that.files);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadManifest implements DownloadManifest {
  const _DownloadManifest({required this.gameId, required this.systemId, required  List<DownloadFile> files}): _files = files;
  factory _DownloadManifest.fromJson(Map<String, dynamic> json) => _$DownloadManifestFromJson(json);

@override final  String gameId;
@override final  String systemId;
 final  List<DownloadFile> _files;
@override List<DownloadFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}


/// Create a copy of DownloadManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadManifestCopyWith<_DownloadManifest> get copyWith => __$DownloadManifestCopyWithImpl<_DownloadManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadManifestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadManifest&&(identical(other.gameId, gameId) || other.gameId == gameId)&&(identical(other.systemId, systemId) || other.systemId == systemId)&&const DeepCollectionEquality().equals(other.files, _files));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,gameId,systemId,const DeepCollectionEquality().hash(_files));
}

@override
String toString() {
    return 'DownloadManifest(gameId: $gameId, systemId: $systemId, files: $files)';
}


}

/// @nodoc
abstract mixin class _$DownloadManifestCopyWith<$Res> implements $DownloadManifestCopyWith<$Res> {
  factory _$DownloadManifestCopyWith(_DownloadManifest value, $Res Function(_DownloadManifest) _then) = __$DownloadManifestCopyWithImpl;
@override @useResult
$Res call({
 String gameId, String systemId, List<DownloadFile> files
});




}
/// @nodoc
class __$DownloadManifestCopyWithImpl<$Res>
    implements _$DownloadManifestCopyWith<$Res> {
  __$DownloadManifestCopyWithImpl(this._self, this._then);

  final _DownloadManifest _self;
  final $Res Function(_DownloadManifest) _then;

/// Create a copy of DownloadManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gameId = null,Object? systemId = null,Object? files = null,}) {
  return _then(_DownloadManifest(
gameId: null == gameId ? _self.gameId : gameId // ignore: cast_nullable_to_non_nullable
as String,systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<DownloadFile>,
  ));
}


}

// dart format on
