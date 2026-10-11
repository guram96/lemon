// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'browse.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BrowseRequest {

/// Absolute path to list. `null` lists the roots: the home directory and
/// mounted volumes or drives.
 String? get path;
/// Create a copy of BrowseRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrowseRequestCopyWith<BrowseRequest> get copyWith => _$BrowseRequestCopyWithImpl<BrowseRequest>(this as BrowseRequest, _$identity);

  /// Serializes this BrowseRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrowseRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrowseRequest&&(identical(other.path, _this.path) || other.path == _this.path));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrowseRequest;
  return Object.hash(runtimeType,_this.path);
}

@override
String toString() {
  final _this = this as BrowseRequest;
  return 'BrowseRequest(path: ${_this.path})';
}


}

/// @nodoc
abstract mixin class $BrowseRequestCopyWith<$Res>  {
  factory $BrowseRequestCopyWith(BrowseRequest value, $Res Function(BrowseRequest) _then) = _$BrowseRequestCopyWithImpl;
@useResult
$Res call({
 String? path
});




}
/// @nodoc
class _$BrowseRequestCopyWithImpl<$Res>
    implements $BrowseRequestCopyWith<$Res> {
  _$BrowseRequestCopyWithImpl(this._self, this._then);

  final BrowseRequest _self;
  final $Res Function(BrowseRequest) _then;

/// Create a copy of BrowseRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = freezed,}) {
  return _then(BrowseRequest(
path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BrowseRequest].
extension BrowseRequestPatterns on BrowseRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrowseRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrowseRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrowseRequest value)  $default,){
final _that = this;
switch (_that) {
case _BrowseRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrowseRequest value)?  $default,){
final _that = this;
switch (_that) {
case _BrowseRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? path)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrowseRequest() when $default != null:
return $default(_that.path);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? path)  $default,) {final _that = this;
switch (_that) {
case _BrowseRequest():
return $default(_that.path);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? path)?  $default,) {final _that = this;
switch (_that) {
case _BrowseRequest() when $default != null:
return $default(_that.path);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrowseRequest implements BrowseRequest {
  const _BrowseRequest({this.path});
  factory _BrowseRequest.fromJson(Map<String, dynamic> json) => _$BrowseRequestFromJson(json);

/// Absolute path to list. `null` lists the roots: the home directory and
/// mounted volumes or drives.
@override final  String? path;

/// Create a copy of BrowseRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrowseRequestCopyWith<_BrowseRequest> get copyWith => __$BrowseRequestCopyWithImpl<_BrowseRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrowseRequestToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrowseRequest&&(identical(other.path, path) || other.path == path));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path);
}

@override
String toString() {
    return 'BrowseRequest(path: $path)';
}


}

/// @nodoc
abstract mixin class _$BrowseRequestCopyWith<$Res> implements $BrowseRequestCopyWith<$Res> {
  factory _$BrowseRequestCopyWith(_BrowseRequest value, $Res Function(_BrowseRequest) _then) = __$BrowseRequestCopyWithImpl;
@override @useResult
$Res call({
 String? path
});




}
/// @nodoc
class __$BrowseRequestCopyWithImpl<$Res>
    implements _$BrowseRequestCopyWith<$Res> {
  __$BrowseRequestCopyWithImpl(this._self, this._then);

  final _BrowseRequest _self;
  final $Res Function(_BrowseRequest) _then;

/// Create a copy of BrowseRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = freezed,}) {
  return _then(_BrowseRequest(
path: freezed == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BrowseEntry {

 String get name;/// Absolute path on the server.
 String get path; bool get isDirectory; bool get readable;
/// Create a copy of BrowseEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrowseEntryCopyWith<BrowseEntry> get copyWith => _$BrowseEntryCopyWithImpl<BrowseEntry>(this as BrowseEntry, _$identity);

  /// Serializes this BrowseEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrowseEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrowseEntry&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.isDirectory, _this.isDirectory) || other.isDirectory == _this.isDirectory)&&(identical(other.readable, _this.readable) || other.readable == _this.readable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrowseEntry;
  return Object.hash(runtimeType,_this.name,_this.path,_this.isDirectory,_this.readable);
}

@override
String toString() {
  final _this = this as BrowseEntry;
  return 'BrowseEntry(name: ${_this.name}, path: ${_this.path}, isDirectory: ${_this.isDirectory}, readable: ${_this.readable})';
}


}

/// @nodoc
abstract mixin class $BrowseEntryCopyWith<$Res>  {
  factory $BrowseEntryCopyWith(BrowseEntry value, $Res Function(BrowseEntry) _then) = _$BrowseEntryCopyWithImpl;
@useResult
$Res call({
 String name, String path, bool isDirectory, bool readable
});




}
/// @nodoc
class _$BrowseEntryCopyWithImpl<$Res>
    implements $BrowseEntryCopyWith<$Res> {
  _$BrowseEntryCopyWithImpl(this._self, this._then);

  final BrowseEntry _self;
  final $Res Function(BrowseEntry) _then;

/// Create a copy of BrowseEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? path = null,Object? isDirectory = null,Object? readable = null,}) {
  return _then(BrowseEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,readable: null == readable ? _self.readable : readable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [BrowseEntry].
extension BrowseEntryPatterns on BrowseEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrowseEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrowseEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrowseEntry value)  $default,){
final _that = this;
switch (_that) {
case _BrowseEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrowseEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BrowseEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String path,  bool isDirectory,  bool readable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrowseEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDirectory,_that.readable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String path,  bool isDirectory,  bool readable)  $default,) {final _that = this;
switch (_that) {
case _BrowseEntry():
return $default(_that.name,_that.path,_that.isDirectory,_that.readable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String path,  bool isDirectory,  bool readable)?  $default,) {final _that = this;
switch (_that) {
case _BrowseEntry() when $default != null:
return $default(_that.name,_that.path,_that.isDirectory,_that.readable);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrowseEntry implements BrowseEntry {
  const _BrowseEntry({required this.name, required this.path, required this.isDirectory, required this.readable});
  factory _BrowseEntry.fromJson(Map<String, dynamic> json) => _$BrowseEntryFromJson(json);

@override final  String name;
/// Absolute path on the server.
@override final  String path;
@override final  bool isDirectory;
@override final  bool readable;

/// Create a copy of BrowseEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrowseEntryCopyWith<_BrowseEntry> get copyWith => __$BrowseEntryCopyWithImpl<_BrowseEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrowseEntryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrowseEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.isDirectory, isDirectory) || other.isDirectory == isDirectory)&&(identical(other.readable, readable) || other.readable == readable));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,path,isDirectory,readable);
}

@override
String toString() {
    return 'BrowseEntry(name: $name, path: $path, isDirectory: $isDirectory, readable: $readable)';
}


}

/// @nodoc
abstract mixin class _$BrowseEntryCopyWith<$Res> implements $BrowseEntryCopyWith<$Res> {
  factory _$BrowseEntryCopyWith(_BrowseEntry value, $Res Function(_BrowseEntry) _then) = __$BrowseEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, String path, bool isDirectory, bool readable
});




}
/// @nodoc
class __$BrowseEntryCopyWithImpl<$Res>
    implements _$BrowseEntryCopyWith<$Res> {
  __$BrowseEntryCopyWithImpl(this._self, this._then);

  final _BrowseEntry _self;
  final $Res Function(_BrowseEntry) _then;

/// Create a copy of BrowseEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? path = null,Object? isDirectory = null,Object? readable = null,}) {
  return _then(_BrowseEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,isDirectory: null == isDirectory ? _self.isDirectory : isDirectory // ignore: cast_nullable_to_non_nullable
as bool,readable: null == readable ? _self.readable : readable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BrowseResult {

/// The listed folder, normalized and absolute.
 String get path;/// Parent folder, `null` at a filesystem root.
 String? get parent; List<BrowseEntry> get entries;/// Home, Desktop, Documents and mounted volumes (`/Volumes/*`, drive
/// letters, `/media`, `/mnt`).
 List<BrowseEntry> get shortcuts;
/// Create a copy of BrowseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BrowseResultCopyWith<BrowseResult> get copyWith => _$BrowseResultCopyWithImpl<BrowseResult>(this as BrowseResult, _$identity);

  /// Serializes this BrowseResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BrowseResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BrowseResult&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.parent, _this.parent) || other.parent == _this.parent)&&const DeepCollectionEquality().equals(other.entries, _this.entries)&&const DeepCollectionEquality().equals(other.shortcuts, _this.shortcuts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BrowseResult;
  return Object.hash(runtimeType,_this.path,_this.parent,const DeepCollectionEquality().hash(_this.entries),const DeepCollectionEquality().hash(_this.shortcuts));
}

@override
String toString() {
  final _this = this as BrowseResult;
  return 'BrowseResult(path: ${_this.path}, parent: ${_this.parent}, entries: ${_this.entries}, shortcuts: ${_this.shortcuts})';
}


}

/// @nodoc
abstract mixin class $BrowseResultCopyWith<$Res>  {
  factory $BrowseResultCopyWith(BrowseResult value, $Res Function(BrowseResult) _then) = _$BrowseResultCopyWithImpl;
@useResult
$Res call({
 String path, String? parent, List<BrowseEntry> entries, List<BrowseEntry> shortcuts
});




}
/// @nodoc
class _$BrowseResultCopyWithImpl<$Res>
    implements $BrowseResultCopyWith<$Res> {
  _$BrowseResultCopyWithImpl(this._self, this._then);

  final BrowseResult _self;
  final $Res Function(BrowseResult) _then;

/// Create a copy of BrowseResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? parent = freezed,Object? entries = null,Object? shortcuts = null,}) {
  return _then(BrowseResult(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String?,entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as List<BrowseEntry>,shortcuts: null == shortcuts ? _self.shortcuts : shortcuts // ignore: cast_nullable_to_non_nullable
as List<BrowseEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [BrowseResult].
extension BrowseResultPatterns on BrowseResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BrowseResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BrowseResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BrowseResult value)  $default,){
final _that = this;
switch (_that) {
case _BrowseResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BrowseResult value)?  $default,){
final _that = this;
switch (_that) {
case _BrowseResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  String? parent,  List<BrowseEntry> entries,  List<BrowseEntry> shortcuts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BrowseResult() when $default != null:
return $default(_that.path,_that.parent,_that.entries,_that.shortcuts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  String? parent,  List<BrowseEntry> entries,  List<BrowseEntry> shortcuts)  $default,) {final _that = this;
switch (_that) {
case _BrowseResult():
return $default(_that.path,_that.parent,_that.entries,_that.shortcuts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  String? parent,  List<BrowseEntry> entries,  List<BrowseEntry> shortcuts)?  $default,) {final _that = this;
switch (_that) {
case _BrowseResult() when $default != null:
return $default(_that.path,_that.parent,_that.entries,_that.shortcuts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BrowseResult implements BrowseResult {
  const _BrowseResult({required this.path, this.parent,  List<BrowseEntry> entries = const [],  List<BrowseEntry> shortcuts = const []}): _entries = entries,_shortcuts = shortcuts;
  factory _BrowseResult.fromJson(Map<String, dynamic> json) => _$BrowseResultFromJson(json);

/// The listed folder, normalized and absolute.
@override final  String path;
/// Parent folder, `null` at a filesystem root.
@override final  String? parent;
 final  List<BrowseEntry> _entries;
@override@JsonKey() List<BrowseEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

/// Home, Desktop, Documents and mounted volumes (`/Volumes/*`, drive
/// letters, `/media`, `/mnt`).
 final  List<BrowseEntry> _shortcuts;
/// Home, Desktop, Documents and mounted volumes (`/Volumes/*`, drive
/// letters, `/media`, `/mnt`).
@override@JsonKey() List<BrowseEntry> get shortcuts {
  if (_shortcuts is EqualUnmodifiableListView) return _shortcuts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shortcuts);
}


/// Create a copy of BrowseResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BrowseResultCopyWith<_BrowseResult> get copyWith => __$BrowseResultCopyWithImpl<_BrowseResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BrowseResultToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BrowseResult&&(identical(other.path, path) || other.path == path)&&(identical(other.parent, parent) || other.parent == parent)&&const DeepCollectionEquality().equals(other.entries, _entries)&&const DeepCollectionEquality().equals(other.shortcuts, _shortcuts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path,parent,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_shortcuts));
}

@override
String toString() {
    return 'BrowseResult(path: $path, parent: $parent, entries: $entries, shortcuts: $shortcuts)';
}


}

/// @nodoc
abstract mixin class _$BrowseResultCopyWith<$Res> implements $BrowseResultCopyWith<$Res> {
  factory _$BrowseResultCopyWith(_BrowseResult value, $Res Function(_BrowseResult) _then) = __$BrowseResultCopyWithImpl;
@override @useResult
$Res call({
 String path, String? parent, List<BrowseEntry> entries, List<BrowseEntry> shortcuts
});




}
/// @nodoc
class __$BrowseResultCopyWithImpl<$Res>
    implements _$BrowseResultCopyWith<$Res> {
  __$BrowseResultCopyWithImpl(this._self, this._then);

  final _BrowseResult _self;
  final $Res Function(_BrowseResult) _then;

/// Create a copy of BrowseResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? parent = freezed,Object? entries = null,Object? shortcuts = null,}) {
  return _then(_BrowseResult(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as String?,entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<BrowseEntry>,shortcuts: null == shortcuts ? _self._shortcuts : shortcuts // ignore: cast_nullable_to_non_nullable
as List<BrowseEntry>,
  ));
}


}

// dart format on
