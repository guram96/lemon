// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GameFile {

/// Path relative to the game's system folder, using `/` separators.
 String get path; int get sizeBytes; String? get sha1;
/// Create a copy of GameFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameFileCopyWith<GameFile> get copyWith => _$GameFileCopyWithImpl<GameFile>(this as GameFile, _$identity);

  /// Serializes this GameFile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GameFile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameFile&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes)&&(identical(other.sha1, _this.sha1) || other.sha1 == _this.sha1));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GameFile;
  return Object.hash(runtimeType,_this.path,_this.sizeBytes,_this.sha1);
}

@override
String toString() {
  final _this = this as GameFile;
  return 'GameFile(path: ${_this.path}, sizeBytes: ${_this.sizeBytes}, sha1: ${_this.sha1})';
}


}

/// @nodoc
abstract mixin class $GameFileCopyWith<$Res>  {
  factory $GameFileCopyWith(GameFile value, $Res Function(GameFile) _then) = _$GameFileCopyWithImpl;
@useResult
$Res call({
 String path, int sizeBytes, String? sha1
});




}
/// @nodoc
class _$GameFileCopyWithImpl<$Res>
    implements $GameFileCopyWith<$Res> {
  _$GameFileCopyWithImpl(this._self, this._then);

  final GameFile _self;
  final $Res Function(GameFile) _then;

/// Create a copy of GameFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? sizeBytes = null,Object? sha1 = freezed,}) {
  return _then(GameFile(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha1: freezed == sha1 ? _self.sha1 : sha1 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GameFile].
extension GameFilePatterns on GameFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameFile value)  $default,){
final _that = this;
switch (_that) {
case _GameFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameFile value)?  $default,){
final _that = this;
switch (_that) {
case _GameFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int sizeBytes,  String? sha1)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameFile() when $default != null:
return $default(_that.path,_that.sizeBytes,_that.sha1);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int sizeBytes,  String? sha1)  $default,) {final _that = this;
switch (_that) {
case _GameFile():
return $default(_that.path,_that.sizeBytes,_that.sha1);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int sizeBytes,  String? sha1)?  $default,) {final _that = this;
switch (_that) {
case _GameFile() when $default != null:
return $default(_that.path,_that.sizeBytes,_that.sha1);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GameFile implements GameFile {
  const _GameFile({required this.path, required this.sizeBytes, this.sha1});
  factory _GameFile.fromJson(Map<String, dynamic> json) => _$GameFileFromJson(json);

/// Path relative to the game's system folder, using `/` separators.
@override final  String path;
@override final  int sizeBytes;
@override final  String? sha1;

/// Create a copy of GameFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameFileCopyWith<_GameFile> get copyWith => __$GameFileCopyWithImpl<_GameFile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameFileToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameFile&&(identical(other.path, path) || other.path == path)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.sha1, sha1) || other.sha1 == sha1));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,path,sizeBytes,sha1);
}

@override
String toString() {
    return 'GameFile(path: $path, sizeBytes: $sizeBytes, sha1: $sha1)';
}


}

/// @nodoc
abstract mixin class _$GameFileCopyWith<$Res> implements $GameFileCopyWith<$Res> {
  factory _$GameFileCopyWith(_GameFile value, $Res Function(_GameFile) _then) = __$GameFileCopyWithImpl;
@override @useResult
$Res call({
 String path, int sizeBytes, String? sha1
});




}
/// @nodoc
class __$GameFileCopyWithImpl<$Res>
    implements _$GameFileCopyWith<$Res> {
  __$GameFileCopyWithImpl(this._self, this._then);

  final _GameFile _self;
  final $Res Function(_GameFile) _then;

/// Create a copy of GameFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? sizeBytes = null,Object? sha1 = freezed,}) {
  return _then(_GameFile(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,sha1: freezed == sha1 ? _self.sha1 : sha1 // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Game {

 String get id;/// EmulationStation system ID, see [GameSystems].
 String get systemId; String get title;/// ID of the [LibraryRoot] the game lives in.
 String get rootId; List<GameFile> get files;/// Selected artwork per kind. Per-game overrides replace entries here.
 Map<ArtworkKind, Artwork> get artwork; String? get description; String? get developer; String? get publisher; int? get releaseYear;
/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameCopyWith<Game> get copyWith => _$GameCopyWithImpl<Game>(this as Game, _$identity);

  /// Serializes this Game to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Game;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Game&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.systemId, _this.systemId) || other.systemId == _this.systemId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.rootId, _this.rootId) || other.rootId == _this.rootId)&&const DeepCollectionEquality().equals(other.files, _this.files)&&const DeepCollectionEquality().equals(other.artwork, _this.artwork)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.developer, _this.developer) || other.developer == _this.developer)&&(identical(other.publisher, _this.publisher) || other.publisher == _this.publisher)&&(identical(other.releaseYear, _this.releaseYear) || other.releaseYear == _this.releaseYear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Game;
  return Object.hash(runtimeType,_this.id,_this.systemId,_this.title,_this.rootId,const DeepCollectionEquality().hash(_this.files),const DeepCollectionEquality().hash(_this.artwork),_this.description,_this.developer,_this.publisher,_this.releaseYear);
}

@override
String toString() {
  final _this = this as Game;
  return 'Game(id: ${_this.id}, systemId: ${_this.systemId}, title: ${_this.title}, rootId: ${_this.rootId}, files: ${_this.files}, artwork: ${_this.artwork}, description: ${_this.description}, developer: ${_this.developer}, publisher: ${_this.publisher}, releaseYear: ${_this.releaseYear})';
}


}

/// @nodoc
abstract mixin class $GameCopyWith<$Res>  {
  factory $GameCopyWith(Game value, $Res Function(Game) _then) = _$GameCopyWithImpl;
@useResult
$Res call({
 String id, String systemId, String title, String rootId, List<GameFile> files, Map<ArtworkKind, Artwork> artwork, String? description, String? developer, String? publisher, int? releaseYear
});




}
/// @nodoc
class _$GameCopyWithImpl<$Res>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._self, this._then);

  final Game _self;
  final $Res Function(Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? systemId = null,Object? title = null,Object? rootId = null,Object? files = null,Object? artwork = null,Object? description = freezed,Object? developer = freezed,Object? publisher = freezed,Object? releaseYear = freezed,}) {
  return _then(Game(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,rootId: null == rootId ? _self.rootId : rootId // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<GameFile>,artwork: null == artwork ? _self.artwork : artwork // ignore: cast_nullable_to_non_nullable
as Map<ArtworkKind, Artwork>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,releaseYear: freezed == releaseYear ? _self.releaseYear : releaseYear // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Game].
extension GamePatterns on Game {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Game value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Game value)  $default,){
final _that = this;
switch (_that) {
case _Game():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Game value)?  $default,){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String systemId,  String title,  String rootId,  List<GameFile> files,  Map<ArtworkKind, Artwork> artwork,  String? description,  String? developer,  String? publisher,  int? releaseYear)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.id,_that.systemId,_that.title,_that.rootId,_that.files,_that.artwork,_that.description,_that.developer,_that.publisher,_that.releaseYear);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String systemId,  String title,  String rootId,  List<GameFile> files,  Map<ArtworkKind, Artwork> artwork,  String? description,  String? developer,  String? publisher,  int? releaseYear)  $default,) {final _that = this;
switch (_that) {
case _Game():
return $default(_that.id,_that.systemId,_that.title,_that.rootId,_that.files,_that.artwork,_that.description,_that.developer,_that.publisher,_that.releaseYear);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String systemId,  String title,  String rootId,  List<GameFile> files,  Map<ArtworkKind, Artwork> artwork,  String? description,  String? developer,  String? publisher,  int? releaseYear)?  $default,) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.id,_that.systemId,_that.title,_that.rootId,_that.files,_that.artwork,_that.description,_that.developer,_that.publisher,_that.releaseYear);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Game extends Game {
  const _Game({required this.id, required this.systemId, required this.title, required this.rootId, required  List<GameFile> files,  Map<ArtworkKind, Artwork> artwork = const {}, this.description, this.developer, this.publisher, this.releaseYear}): _files = files,_artwork = artwork,super._();
  factory _Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

@override final  String id;
/// EmulationStation system ID, see [GameSystems].
@override final  String systemId;
@override final  String title;
/// ID of the [LibraryRoot] the game lives in.
@override final  String rootId;
 final  List<GameFile> _files;
@override List<GameFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

/// Selected artwork per kind. Per-game overrides replace entries here.
 final  Map<ArtworkKind, Artwork> _artwork;
/// Selected artwork per kind. Per-game overrides replace entries here.
@override@JsonKey() Map<ArtworkKind, Artwork> get artwork {
  if (_artwork is EqualUnmodifiableMapView) return _artwork;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_artwork);
}

@override final  String? description;
@override final  String? developer;
@override final  String? publisher;
@override final  int? releaseYear;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameCopyWith<_Game> get copyWith => __$GameCopyWithImpl<_Game>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GameToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Game&&(identical(other.id, id) || other.id == id)&&(identical(other.systemId, systemId) || other.systemId == systemId)&&(identical(other.title, title) || other.title == title)&&(identical(other.rootId, rootId) || other.rootId == rootId)&&const DeepCollectionEquality().equals(other.files, _files)&&const DeepCollectionEquality().equals(other.artwork, _artwork)&&(identical(other.description, description) || other.description == description)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.publisher, publisher) || other.publisher == publisher)&&(identical(other.releaseYear, releaseYear) || other.releaseYear == releaseYear));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,systemId,title,rootId,const DeepCollectionEquality().hash(_files),const DeepCollectionEquality().hash(_artwork),description,developer,publisher,releaseYear);
}

@override
String toString() {
    return 'Game(id: $id, systemId: $systemId, title: $title, rootId: $rootId, files: $files, artwork: $artwork, description: $description, developer: $developer, publisher: $publisher, releaseYear: $releaseYear)';
}


}

/// @nodoc
abstract mixin class _$GameCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$GameCopyWith(_Game value, $Res Function(_Game) _then) = __$GameCopyWithImpl;
@override @useResult
$Res call({
 String id, String systemId, String title, String rootId, List<GameFile> files, Map<ArtworkKind, Artwork> artwork, String? description, String? developer, String? publisher, int? releaseYear
});




}
/// @nodoc
class __$GameCopyWithImpl<$Res>
    implements _$GameCopyWith<$Res> {
  __$GameCopyWithImpl(this._self, this._then);

  final _Game _self;
  final $Res Function(_Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? systemId = null,Object? title = null,Object? rootId = null,Object? files = null,Object? artwork = null,Object? description = freezed,Object? developer = freezed,Object? publisher = freezed,Object? releaseYear = freezed,}) {
  return _then(_Game(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,rootId: null == rootId ? _self.rootId : rootId // ignore: cast_nullable_to_non_nullable
as String,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<GameFile>,artwork: null == artwork ? _self._artwork : artwork // ignore: cast_nullable_to_non_nullable
as Map<ArtworkKind, Artwork>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as String?,publisher: freezed == publisher ? _self.publisher : publisher // ignore: cast_nullable_to_non_nullable
as String?,releaseYear: freezed == releaseYear ? _self.releaseYear : releaseYear // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
