// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_queries.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemSummary {

/// EmulationStation system ID, see [GameSystems].
 String get systemId; String get name; int get gameCount;
/// Create a copy of SystemSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemSummaryCopyWith<SystemSummary> get copyWith => _$SystemSummaryCopyWithImpl<SystemSummary>(this as SystemSummary, _$identity);

  /// Serializes this SystemSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SystemSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemSummary&&(identical(other.systemId, _this.systemId) || other.systemId == _this.systemId)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.gameCount, _this.gameCount) || other.gameCount == _this.gameCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SystemSummary;
  return Object.hash(runtimeType,_this.systemId,_this.name,_this.gameCount);
}

@override
String toString() {
  final _this = this as SystemSummary;
  return 'SystemSummary(systemId: ${_this.systemId}, name: ${_this.name}, gameCount: ${_this.gameCount})';
}


}

/// @nodoc
abstract mixin class $SystemSummaryCopyWith<$Res>  {
  factory $SystemSummaryCopyWith(SystemSummary value, $Res Function(SystemSummary) _then) = _$SystemSummaryCopyWithImpl;
@useResult
$Res call({
 String systemId, String name, int gameCount
});




}
/// @nodoc
class _$SystemSummaryCopyWithImpl<$Res>
    implements $SystemSummaryCopyWith<$Res> {
  _$SystemSummaryCopyWithImpl(this._self, this._then);

  final SystemSummary _self;
  final $Res Function(SystemSummary) _then;

/// Create a copy of SystemSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? systemId = null,Object? name = null,Object? gameCount = null,}) {
  return _then(SystemSummary(
systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gameCount: null == gameCount ? _self.gameCount : gameCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemSummary].
extension SystemSummaryPatterns on SystemSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemSummary value)  $default,){
final _that = this;
switch (_that) {
case _SystemSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SystemSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String systemId,  String name,  int gameCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemSummary() when $default != null:
return $default(_that.systemId,_that.name,_that.gameCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String systemId,  String name,  int gameCount)  $default,) {final _that = this;
switch (_that) {
case _SystemSummary():
return $default(_that.systemId,_that.name,_that.gameCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String systemId,  String name,  int gameCount)?  $default,) {final _that = this;
switch (_that) {
case _SystemSummary() when $default != null:
return $default(_that.systemId,_that.name,_that.gameCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SystemSummary implements SystemSummary {
  const _SystemSummary({required this.systemId, required this.name, required this.gameCount});
  factory _SystemSummary.fromJson(Map<String, dynamic> json) => _$SystemSummaryFromJson(json);

/// EmulationStation system ID, see [GameSystems].
@override final  String systemId;
@override final  String name;
@override final  int gameCount;

/// Create a copy of SystemSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemSummaryCopyWith<_SystemSummary> get copyWith => __$SystemSummaryCopyWithImpl<_SystemSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemSummary&&(identical(other.systemId, systemId) || other.systemId == systemId)&&(identical(other.name, name) || other.name == name)&&(identical(other.gameCount, gameCount) || other.gameCount == gameCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,systemId,name,gameCount);
}

@override
String toString() {
    return 'SystemSummary(systemId: $systemId, name: $name, gameCount: $gameCount)';
}


}

/// @nodoc
abstract mixin class _$SystemSummaryCopyWith<$Res> implements $SystemSummaryCopyWith<$Res> {
  factory _$SystemSummaryCopyWith(_SystemSummary value, $Res Function(_SystemSummary) _then) = __$SystemSummaryCopyWithImpl;
@override @useResult
$Res call({
 String systemId, String name, int gameCount
});




}
/// @nodoc
class __$SystemSummaryCopyWithImpl<$Res>
    implements _$SystemSummaryCopyWith<$Res> {
  __$SystemSummaryCopyWithImpl(this._self, this._then);

  final _SystemSummary _self;
  final $Res Function(_SystemSummary) _then;

/// Create a copy of SystemSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? systemId = null,Object? name = null,Object? gameCount = null,}) {
  return _then(_SystemSummary(
systemId: null == systemId ? _self.systemId : systemId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gameCount: null == gameCount ? _self.gameCount : gameCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GamePage {

 List<Game> get games;/// Total number of games matching the query.
 int get total;
/// Create a copy of GamePage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GamePageCopyWith<GamePage> get copyWith => _$GamePageCopyWithImpl<GamePage>(this as GamePage, _$identity);

  /// Serializes this GamePage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GamePage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GamePage&&const DeepCollectionEquality().equals(other.games, _this.games)&&(identical(other.total, _this.total) || other.total == _this.total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GamePage;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.games),_this.total);
}

@override
String toString() {
  final _this = this as GamePage;
  return 'GamePage(games: ${_this.games}, total: ${_this.total})';
}


}

/// @nodoc
abstract mixin class $GamePageCopyWith<$Res>  {
  factory $GamePageCopyWith(GamePage value, $Res Function(GamePage) _then) = _$GamePageCopyWithImpl;
@useResult
$Res call({
 List<Game> games, int total
});




}
/// @nodoc
class _$GamePageCopyWithImpl<$Res>
    implements $GamePageCopyWith<$Res> {
  _$GamePageCopyWithImpl(this._self, this._then);

  final GamePage _self;
  final $Res Function(GamePage) _then;

/// Create a copy of GamePage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? games = null,Object? total = null,}) {
  return _then(GamePage(
games: null == games ? _self.games : games // ignore: cast_nullable_to_non_nullable
as List<Game>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GamePage].
extension GamePagePatterns on GamePage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GamePage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GamePage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GamePage value)  $default,){
final _that = this;
switch (_that) {
case _GamePage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GamePage value)?  $default,){
final _that = this;
switch (_that) {
case _GamePage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Game> games,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GamePage() when $default != null:
return $default(_that.games,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Game> games,  int total)  $default,) {final _that = this;
switch (_that) {
case _GamePage():
return $default(_that.games,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Game> games,  int total)?  $default,) {final _that = this;
switch (_that) {
case _GamePage() when $default != null:
return $default(_that.games,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GamePage implements GamePage {
  const _GamePage({required  List<Game> games, required this.total}): _games = games;
  factory _GamePage.fromJson(Map<String, dynamic> json) => _$GamePageFromJson(json);

 final  List<Game> _games;
@override List<Game> get games {
  if (_games is EqualUnmodifiableListView) return _games;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_games);
}

/// Total number of games matching the query.
@override final  int total;

/// Create a copy of GamePage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GamePageCopyWith<_GamePage> get copyWith => __$GamePageCopyWithImpl<_GamePage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GamePageToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GamePage&&const DeepCollectionEquality().equals(other.games, _games)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_games),total);
}

@override
String toString() {
    return 'GamePage(games: $games, total: $total)';
}


}

/// @nodoc
abstract mixin class _$GamePageCopyWith<$Res> implements $GamePageCopyWith<$Res> {
  factory _$GamePageCopyWith(_GamePage value, $Res Function(_GamePage) _then) = __$GamePageCopyWithImpl;
@override @useResult
$Res call({
 List<Game> games, int total
});




}
/// @nodoc
class __$GamePageCopyWithImpl<$Res>
    implements _$GamePageCopyWith<$Res> {
  __$GamePageCopyWithImpl(this._self, this._then);

  final _GamePage _self;
  final $Res Function(_GamePage) _then;

/// Create a copy of GamePage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? games = null,Object? total = null,}) {
  return _then(_GamePage(
games: null == games ? _self._games : games // ignore: cast_nullable_to_non_nullable
as List<Game>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
