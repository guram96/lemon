// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanStatus {

 ScanPhase get phase;/// Files processed so far.
 int get processed;/// Files found in total. `0` while discovering.
 int get total; String? get currentSystemId; String? get currentFile; int get added; int get updated; int get removed; DateTime? get startedAt; DateTime? get finishedAt;/// Set when [phase] is [ScanPhase.failed].
 String? get error;
/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanStatusCopyWith<ScanStatus> get copyWith => _$ScanStatusCopyWithImpl<ScanStatus>(this as ScanStatus, _$identity);

  /// Serializes this ScanStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ScanStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanStatus&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.processed, _this.processed) || other.processed == _this.processed)&&(identical(other.total, _this.total) || other.total == _this.total)&&(identical(other.currentSystemId, _this.currentSystemId) || other.currentSystemId == _this.currentSystemId)&&(identical(other.currentFile, _this.currentFile) || other.currentFile == _this.currentFile)&&(identical(other.added, _this.added) || other.added == _this.added)&&(identical(other.updated, _this.updated) || other.updated == _this.updated)&&(identical(other.removed, _this.removed) || other.removed == _this.removed)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.finishedAt, _this.finishedAt) || other.finishedAt == _this.finishedAt)&&(identical(other.error, _this.error) || other.error == _this.error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ScanStatus;
  return Object.hash(runtimeType,_this.phase,_this.processed,_this.total,_this.currentSystemId,_this.currentFile,_this.added,_this.updated,_this.removed,_this.startedAt,_this.finishedAt,_this.error);
}

@override
String toString() {
  final _this = this as ScanStatus;
  return 'ScanStatus(phase: ${_this.phase}, processed: ${_this.processed}, total: ${_this.total}, currentSystemId: ${_this.currentSystemId}, currentFile: ${_this.currentFile}, added: ${_this.added}, updated: ${_this.updated}, removed: ${_this.removed}, startedAt: ${_this.startedAt}, finishedAt: ${_this.finishedAt}, error: ${_this.error})';
}


}

/// @nodoc
abstract mixin class $ScanStatusCopyWith<$Res>  {
  factory $ScanStatusCopyWith(ScanStatus value, $Res Function(ScanStatus) _then) = _$ScanStatusCopyWithImpl;
@useResult
$Res call({
 ScanPhase phase, int processed, int total, String? currentSystemId, String? currentFile, int added, int updated, int removed, DateTime? startedAt, DateTime? finishedAt, String? error
});




}
/// @nodoc
class _$ScanStatusCopyWithImpl<$Res>
    implements $ScanStatusCopyWith<$Res> {
  _$ScanStatusCopyWithImpl(this._self, this._then);

  final ScanStatus _self;
  final $Res Function(ScanStatus) _then;

/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? processed = null,Object? total = null,Object? currentSystemId = freezed,Object? currentFile = freezed,Object? added = null,Object? updated = null,Object? removed = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? error = freezed,}) {
  return _then(ScanStatus(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ScanPhase,processed: null == processed ? _self.processed : processed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currentSystemId: freezed == currentSystemId ? _self.currentSystemId : currentSystemId // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanStatus].
extension ScanStatusPatterns on ScanStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanStatus value)  $default,){
final _that = this;
switch (_that) {
case _ScanStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanStatus value)?  $default,){
final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScanPhase phase,  int processed,  int total,  String? currentSystemId,  String? currentFile,  int added,  int updated,  int removed,  DateTime? startedAt,  DateTime? finishedAt,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
return $default(_that.phase,_that.processed,_that.total,_that.currentSystemId,_that.currentFile,_that.added,_that.updated,_that.removed,_that.startedAt,_that.finishedAt,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScanPhase phase,  int processed,  int total,  String? currentSystemId,  String? currentFile,  int added,  int updated,  int removed,  DateTime? startedAt,  DateTime? finishedAt,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ScanStatus():
return $default(_that.phase,_that.processed,_that.total,_that.currentSystemId,_that.currentFile,_that.added,_that.updated,_that.removed,_that.startedAt,_that.finishedAt,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScanPhase phase,  int processed,  int total,  String? currentSystemId,  String? currentFile,  int added,  int updated,  int removed,  DateTime? startedAt,  DateTime? finishedAt,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ScanStatus() when $default != null:
return $default(_that.phase,_that.processed,_that.total,_that.currentSystemId,_that.currentFile,_that.added,_that.updated,_that.removed,_that.startedAt,_that.finishedAt,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanStatus extends ScanStatus {
  const _ScanStatus({required this.phase, this.processed = 0, this.total = 0, this.currentSystemId, this.currentFile, this.added = 0, this.updated = 0, this.removed = 0, this.startedAt, this.finishedAt, this.error}): super._();
  factory _ScanStatus.fromJson(Map<String, dynamic> json) => _$ScanStatusFromJson(json);

@override final  ScanPhase phase;
/// Files processed so far.
@override@JsonKey() final  int processed;
/// Files found in total. `0` while discovering.
@override@JsonKey() final  int total;
@override final  String? currentSystemId;
@override final  String? currentFile;
@override@JsonKey() final  int added;
@override@JsonKey() final  int updated;
@override@JsonKey() final  int removed;
@override final  DateTime? startedAt;
@override final  DateTime? finishedAt;
/// Set when [phase] is [ScanPhase.failed].
@override final  String? error;

/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanStatusCopyWith<_ScanStatus> get copyWith => __$ScanStatusCopyWithImpl<_ScanStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanStatusToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanStatus&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.processed, processed) || other.processed == processed)&&(identical(other.total, total) || other.total == total)&&(identical(other.currentSystemId, currentSystemId) || other.currentSystemId == currentSystemId)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile)&&(identical(other.added, added) || other.added == added)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,phase,processed,total,currentSystemId,currentFile,added,updated,removed,startedAt,finishedAt,error);
}

@override
String toString() {
    return 'ScanStatus(phase: $phase, processed: $processed, total: $total, currentSystemId: $currentSystemId, currentFile: $currentFile, added: $added, updated: $updated, removed: $removed, startedAt: $startedAt, finishedAt: $finishedAt, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ScanStatusCopyWith<$Res> implements $ScanStatusCopyWith<$Res> {
  factory _$ScanStatusCopyWith(_ScanStatus value, $Res Function(_ScanStatus) _then) = __$ScanStatusCopyWithImpl;
@override @useResult
$Res call({
 ScanPhase phase, int processed, int total, String? currentSystemId, String? currentFile, int added, int updated, int removed, DateTime? startedAt, DateTime? finishedAt, String? error
});




}
/// @nodoc
class __$ScanStatusCopyWithImpl<$Res>
    implements _$ScanStatusCopyWith<$Res> {
  __$ScanStatusCopyWithImpl(this._self, this._then);

  final _ScanStatus _self;
  final $Res Function(_ScanStatus) _then;

/// Create a copy of ScanStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? processed = null,Object? total = null,Object? currentSystemId = freezed,Object? currentFile = freezed,Object? added = null,Object? updated = null,Object? removed = null,Object? startedAt = freezed,Object? finishedAt = freezed,Object? error = freezed,}) {
  return _then(_ScanStatus(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ScanPhase,processed: null == processed ? _self.processed : processed // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currentSystemId: freezed == currentSystemId ? _self.currentSystemId : currentSystemId // ignore: cast_nullable_to_non_nullable
as String?,currentFile: freezed == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String?,added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
