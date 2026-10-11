// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'server_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
ServerEvent _$ServerEventFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'scan_progress':
          return ScanProgressEvent.fromJson(
            json
          );
                case 'library_changed':
          return LibraryChangedEvent.fromJson(
            json
          );
                case 'root_status_changed':
          return RootStatusChangedEvent.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'ServerEvent',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$ServerEvent {



  /// Serializes this ServerEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ServerEvent);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ServerEvent()';
}


}

/// @nodoc
class $ServerEventCopyWith<$Res>  {
$ServerEventCopyWith(ServerEvent _, $Res Function(ServerEvent) __);
}


/// Adds pattern-matching-related methods to [ServerEvent].
extension ServerEventPatterns on ServerEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ScanProgressEvent value)?  scanProgress,TResult Function( LibraryChangedEvent value)?  libraryChanged,TResult Function( RootStatusChangedEvent value)?  rootStatusChanged,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ScanProgressEvent() when scanProgress != null:
return scanProgress(_that);case LibraryChangedEvent() when libraryChanged != null:
return libraryChanged(_that);case RootStatusChangedEvent() when rootStatusChanged != null:
return rootStatusChanged(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ScanProgressEvent value)  scanProgress,required TResult Function( LibraryChangedEvent value)  libraryChanged,required TResult Function( RootStatusChangedEvent value)  rootStatusChanged,}){
final _that = this;
switch (_that) {
case ScanProgressEvent():
return scanProgress(_that);case LibraryChangedEvent():
return libraryChanged(_that);case RootStatusChangedEvent():
return rootStatusChanged(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ScanProgressEvent value)?  scanProgress,TResult? Function( LibraryChangedEvent value)?  libraryChanged,TResult? Function( RootStatusChangedEvent value)?  rootStatusChanged,}){
final _that = this;
switch (_that) {
case ScanProgressEvent() when scanProgress != null:
return scanProgress(_that);case LibraryChangedEvent() when libraryChanged != null:
return libraryChanged(_that);case RootStatusChangedEvent() when rootStatusChanged != null:
return rootStatusChanged(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ScanStatus status)?  scanProgress,TResult Function( List<String> addedIds,  List<String> updatedIds,  List<String> removedIds)?  libraryChanged,TResult Function( LibraryRoot root)?  rootStatusChanged,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ScanProgressEvent() when scanProgress != null:
return scanProgress(_that.status);case LibraryChangedEvent() when libraryChanged != null:
return libraryChanged(_that.addedIds,_that.updatedIds,_that.removedIds);case RootStatusChangedEvent() when rootStatusChanged != null:
return rootStatusChanged(_that.root);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ScanStatus status)  scanProgress,required TResult Function( List<String> addedIds,  List<String> updatedIds,  List<String> removedIds)  libraryChanged,required TResult Function( LibraryRoot root)  rootStatusChanged,}) {final _that = this;
switch (_that) {
case ScanProgressEvent():
return scanProgress(_that.status);case LibraryChangedEvent():
return libraryChanged(_that.addedIds,_that.updatedIds,_that.removedIds);case RootStatusChangedEvent():
return rootStatusChanged(_that.root);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ScanStatus status)?  scanProgress,TResult? Function( List<String> addedIds,  List<String> updatedIds,  List<String> removedIds)?  libraryChanged,TResult? Function( LibraryRoot root)?  rootStatusChanged,}) {final _that = this;
switch (_that) {
case ScanProgressEvent() when scanProgress != null:
return scanProgress(_that.status);case LibraryChangedEvent() when libraryChanged != null:
return libraryChanged(_that.addedIds,_that.updatedIds,_that.removedIds);case RootStatusChangedEvent() when rootStatusChanged != null:
return rootStatusChanged(_that.root);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ScanProgressEvent implements ServerEvent {
  const ScanProgressEvent({required this.status,  String? $type}): $type = $type ?? 'scan_progress';
  factory ScanProgressEvent.fromJson(Map<String, dynamic> json) => _$ScanProgressEventFromJson(json);

 final  ScanStatus status;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanProgressEventCopyWith<ScanProgressEvent> get copyWith => _$ScanProgressEventCopyWithImpl<ScanProgressEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanProgressEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanProgressEvent&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,status);
}

@override
String toString() {
    return 'ServerEvent.scanProgress(status: $status)';
}


}

/// @nodoc
abstract mixin class $ScanProgressEventCopyWith<$Res> implements $ServerEventCopyWith<$Res> {
  factory $ScanProgressEventCopyWith(ScanProgressEvent value, $Res Function(ScanProgressEvent) _then) = _$ScanProgressEventCopyWithImpl;
@useResult
$Res call({
 ScanStatus status
});


$ScanStatusCopyWith<$Res> get status;

}
/// @nodoc
class _$ScanProgressEventCopyWithImpl<$Res>
    implements $ScanProgressEventCopyWith<$Res> {
  _$ScanProgressEventCopyWithImpl(this._self, this._then);

  final ScanProgressEvent _self;
  final $Res Function(ScanProgressEvent) _then;

/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? status = null,}) {
  return _then(ScanProgressEvent(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ScanStatus,
  ));
}

/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScanStatusCopyWith<$Res> get status {
  
  return $ScanStatusCopyWith<$Res>(_self.status, (value) {
    return _then(_self.copyWith(status: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class LibraryChangedEvent implements ServerEvent {
  const LibraryChangedEvent({ List<String> addedIds = const [],  List<String> updatedIds = const [],  List<String> removedIds = const [],  String? $type}): _addedIds = addedIds,_updatedIds = updatedIds,_removedIds = removedIds,$type = $type ?? 'library_changed';
  factory LibraryChangedEvent.fromJson(Map<String, dynamic> json) => _$LibraryChangedEventFromJson(json);

 final  List<String> _addedIds;
@JsonKey() List<String> get addedIds {
  if (_addedIds is EqualUnmodifiableListView) return _addedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addedIds);
}

 final  List<String> _updatedIds;
@JsonKey() List<String> get updatedIds {
  if (_updatedIds is EqualUnmodifiableListView) return _updatedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_updatedIds);
}

 final  List<String> _removedIds;
@JsonKey() List<String> get removedIds {
  if (_removedIds is EqualUnmodifiableListView) return _removedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_removedIds);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryChangedEventCopyWith<LibraryChangedEvent> get copyWith => _$LibraryChangedEventCopyWithImpl<LibraryChangedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LibraryChangedEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryChangedEvent&&const DeepCollectionEquality().equals(other.addedIds, _addedIds)&&const DeepCollectionEquality().equals(other.updatedIds, _updatedIds)&&const DeepCollectionEquality().equals(other.removedIds, _removedIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_addedIds),const DeepCollectionEquality().hash(_updatedIds),const DeepCollectionEquality().hash(_removedIds));
}

@override
String toString() {
    return 'ServerEvent.libraryChanged(addedIds: $addedIds, updatedIds: $updatedIds, removedIds: $removedIds)';
}


}

/// @nodoc
abstract mixin class $LibraryChangedEventCopyWith<$Res> implements $ServerEventCopyWith<$Res> {
  factory $LibraryChangedEventCopyWith(LibraryChangedEvent value, $Res Function(LibraryChangedEvent) _then) = _$LibraryChangedEventCopyWithImpl;
@useResult
$Res call({
 List<String> addedIds, List<String> updatedIds, List<String> removedIds
});




}
/// @nodoc
class _$LibraryChangedEventCopyWithImpl<$Res>
    implements $LibraryChangedEventCopyWith<$Res> {
  _$LibraryChangedEventCopyWithImpl(this._self, this._then);

  final LibraryChangedEvent _self;
  final $Res Function(LibraryChangedEvent) _then;

/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? addedIds = null,Object? updatedIds = null,Object? removedIds = null,}) {
  return _then(LibraryChangedEvent(
addedIds: null == addedIds ? _self._addedIds : addedIds // ignore: cast_nullable_to_non_nullable
as List<String>,updatedIds: null == updatedIds ? _self._updatedIds : updatedIds // ignore: cast_nullable_to_non_nullable
as List<String>,removedIds: null == removedIds ? _self._removedIds : removedIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RootStatusChangedEvent implements ServerEvent {
  const RootStatusChangedEvent({required this.root,  String? $type}): $type = $type ?? 'root_status_changed';
  factory RootStatusChangedEvent.fromJson(Map<String, dynamic> json) => _$RootStatusChangedEventFromJson(json);

 final  LibraryRoot root;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RootStatusChangedEventCopyWith<RootStatusChangedEvent> get copyWith => _$RootStatusChangedEventCopyWithImpl<RootStatusChangedEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RootStatusChangedEventToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RootStatusChangedEvent&&(identical(other.root, root) || other.root == root));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,root);
}

@override
String toString() {
    return 'ServerEvent.rootStatusChanged(root: $root)';
}


}

/// @nodoc
abstract mixin class $RootStatusChangedEventCopyWith<$Res> implements $ServerEventCopyWith<$Res> {
  factory $RootStatusChangedEventCopyWith(RootStatusChangedEvent value, $Res Function(RootStatusChangedEvent) _then) = _$RootStatusChangedEventCopyWithImpl;
@useResult
$Res call({
 LibraryRoot root
});


$LibraryRootCopyWith<$Res> get root;

}
/// @nodoc
class _$RootStatusChangedEventCopyWithImpl<$Res>
    implements $RootStatusChangedEventCopyWith<$Res> {
  _$RootStatusChangedEventCopyWithImpl(this._self, this._then);

  final RootStatusChangedEvent _self;
  final $Res Function(RootStatusChangedEvent) _then;

/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? root = null,}) {
  return _then(RootStatusChangedEvent(
root: null == root ? _self.root : root // ignore: cast_nullable_to_non_nullable
as LibraryRoot,
  ));
}

/// Create a copy of ServerEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LibraryRootCopyWith<$Res> get root {
  
  return $LibraryRootCopyWith<$Res>(_self.root, (value) {
    return _then(_self.copyWith(root: value));
  });
}
}

// dart format on
