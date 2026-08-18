// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatSourceDto {

 String get entityType; int? get entityId; String? get excerpt; Map<String, Object?> get metadata;
/// Create a copy of ChatSourceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSourceDtoCopyWith<ChatSourceDto> get copyWith => _$ChatSourceDtoCopyWithImpl<ChatSourceDto>(this as ChatSourceDto, _$identity);

  /// Serializes this ChatSourceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSourceDto&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&const DeepCollectionEquality().equals(other.metadata, metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,entityId,excerpt,const DeepCollectionEquality().hash(metadata));

@override
String toString() {
  return 'ChatSourceDto(entityType: $entityType, entityId: $entityId, excerpt: $excerpt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class $ChatSourceDtoCopyWith<$Res>  {
  factory $ChatSourceDtoCopyWith(ChatSourceDto value, $Res Function(ChatSourceDto) _then) = _$ChatSourceDtoCopyWithImpl;
@useResult
$Res call({
 String entityType, int? entityId, String? excerpt, Map<String, Object?> metadata
});




}
/// @nodoc
class _$ChatSourceDtoCopyWithImpl<$Res>
    implements $ChatSourceDtoCopyWith<$Res> {
  _$ChatSourceDtoCopyWithImpl(this._self, this._then);

  final ChatSourceDto _self;
  final $Res Function(ChatSourceDto) _then;

/// Create a copy of ChatSourceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? entityId = freezed,Object? excerpt = freezed,Object? metadata = null,}) {
  return _then(_self.copyWith(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as int?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatSourceDto].
extension ChatSourceDtoPatterns on ChatSourceDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSourceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSourceDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSourceDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatSourceDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSourceDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSourceDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entityType,  int? entityId,  String? excerpt,  Map<String, Object?> metadata)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSourceDto() when $default != null:
return $default(_that.entityType,_that.entityId,_that.excerpt,_that.metadata);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entityType,  int? entityId,  String? excerpt,  Map<String, Object?> metadata)  $default,) {final _that = this;
switch (_that) {
case _ChatSourceDto():
return $default(_that.entityType,_that.entityId,_that.excerpt,_that.metadata);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entityType,  int? entityId,  String? excerpt,  Map<String, Object?> metadata)?  $default,) {final _that = this;
switch (_that) {
case _ChatSourceDto() when $default != null:
return $default(_that.entityType,_that.entityId,_that.excerpt,_that.metadata);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatSourceDto implements ChatSourceDto {
  const _ChatSourceDto({required this.entityType, this.entityId, this.excerpt, final  Map<String, Object?> metadata = const <String, Object?>{}}): _metadata = metadata;
  factory _ChatSourceDto.fromJson(Map<String, dynamic> json) => _$ChatSourceDtoFromJson(json);

@override final  String entityType;
@override final  int? entityId;
@override final  String? excerpt;
 final  Map<String, Object?> _metadata;
@override@JsonKey() Map<String, Object?> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}


/// Create a copy of ChatSourceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSourceDtoCopyWith<_ChatSourceDto> get copyWith => __$ChatSourceDtoCopyWithImpl<_ChatSourceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatSourceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSourceDto&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&const DeepCollectionEquality().equals(other._metadata, _metadata));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,entityId,excerpt,const DeepCollectionEquality().hash(_metadata));

@override
String toString() {
  return 'ChatSourceDto(entityType: $entityType, entityId: $entityId, excerpt: $excerpt, metadata: $metadata)';
}


}

/// @nodoc
abstract mixin class _$ChatSourceDtoCopyWith<$Res> implements $ChatSourceDtoCopyWith<$Res> {
  factory _$ChatSourceDtoCopyWith(_ChatSourceDto value, $Res Function(_ChatSourceDto) _then) = __$ChatSourceDtoCopyWithImpl;
@override @useResult
$Res call({
 String entityType, int? entityId, String? excerpt, Map<String, Object?> metadata
});




}
/// @nodoc
class __$ChatSourceDtoCopyWithImpl<$Res>
    implements _$ChatSourceDtoCopyWith<$Res> {
  __$ChatSourceDtoCopyWithImpl(this._self, this._then);

  final _ChatSourceDto _self;
  final $Res Function(_ChatSourceDto) _then;

/// Create a copy of ChatSourceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? entityId = freezed,Object? excerpt = freezed,Object? metadata = null,}) {
  return _then(_ChatSourceDto(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as int?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}


/// @nodoc
mixin _$ChatResponseDto {

 String get answer; List<ChatSourceDto> get sources;
/// Create a copy of ChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatResponseDtoCopyWith<ChatResponseDto> get copyWith => _$ChatResponseDtoCopyWithImpl<ChatResponseDto>(this as ChatResponseDto, _$identity);

  /// Serializes this ChatResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatResponseDto&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other.sources, sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,answer,const DeepCollectionEquality().hash(sources));

@override
String toString() {
  return 'ChatResponseDto(answer: $answer, sources: $sources)';
}


}

/// @nodoc
abstract mixin class $ChatResponseDtoCopyWith<$Res>  {
  factory $ChatResponseDtoCopyWith(ChatResponseDto value, $Res Function(ChatResponseDto) _then) = _$ChatResponseDtoCopyWithImpl;
@useResult
$Res call({
 String answer, List<ChatSourceDto> sources
});




}
/// @nodoc
class _$ChatResponseDtoCopyWithImpl<$Res>
    implements $ChatResponseDtoCopyWith<$Res> {
  _$ChatResponseDtoCopyWithImpl(this._self, this._then);

  final ChatResponseDto _self;
  final $Res Function(ChatResponseDto) _then;

/// Create a copy of ChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? answer = null,Object? sources = null,}) {
  return _then(_self.copyWith(
answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as List<ChatSourceDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatResponseDto].
extension ChatResponseDtoPatterns on ChatResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String answer,  List<ChatSourceDto> sources)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatResponseDto() when $default != null:
return $default(_that.answer,_that.sources);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String answer,  List<ChatSourceDto> sources)  $default,) {final _that = this;
switch (_that) {
case _ChatResponseDto():
return $default(_that.answer,_that.sources);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String answer,  List<ChatSourceDto> sources)?  $default,) {final _that = this;
switch (_that) {
case _ChatResponseDto() when $default != null:
return $default(_that.answer,_that.sources);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatResponseDto implements ChatResponseDto {
  const _ChatResponseDto({this.answer = '', final  List<ChatSourceDto> sources = const <ChatSourceDto>[]}): _sources = sources;
  factory _ChatResponseDto.fromJson(Map<String, dynamic> json) => _$ChatResponseDtoFromJson(json);

@override@JsonKey() final  String answer;
 final  List<ChatSourceDto> _sources;
@override@JsonKey() List<ChatSourceDto> get sources {
  if (_sources is EqualUnmodifiableListView) return _sources;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sources);
}


/// Create a copy of ChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatResponseDtoCopyWith<_ChatResponseDto> get copyWith => __$ChatResponseDtoCopyWithImpl<_ChatResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatResponseDto&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other._sources, _sources));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,answer,const DeepCollectionEquality().hash(_sources));

@override
String toString() {
  return 'ChatResponseDto(answer: $answer, sources: $sources)';
}


}

/// @nodoc
abstract mixin class _$ChatResponseDtoCopyWith<$Res> implements $ChatResponseDtoCopyWith<$Res> {
  factory _$ChatResponseDtoCopyWith(_ChatResponseDto value, $Res Function(_ChatResponseDto) _then) = __$ChatResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String answer, List<ChatSourceDto> sources
});




}
/// @nodoc
class __$ChatResponseDtoCopyWithImpl<$Res>
    implements _$ChatResponseDtoCopyWith<$Res> {
  __$ChatResponseDtoCopyWithImpl(this._self, this._then);

  final _ChatResponseDto _self;
  final $Res Function(_ChatResponseDto) _then;

/// Create a copy of ChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? answer = null,Object? sources = null,}) {
  return _then(_ChatResponseDto(
answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as String,sources: null == sources ? _self._sources : sources // ignore: cast_nullable_to_non_nullable
as List<ChatSourceDto>,
  ));
}


}

// dart format on
