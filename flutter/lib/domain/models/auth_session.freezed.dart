// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthSession {

 String get token; String get email; String get nombre; String? get rol; int get usuarioId; List<String> get permisos;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.token, token) || other.token == token)&&(identical(other.email, email) || other.email == email)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&const DeepCollectionEquality().equals(other.permisos, permisos));
}


@override
int get hashCode => Object.hash(runtimeType,token,email,nombre,rol,usuarioId,const DeepCollectionEquality().hash(permisos));

@override
String toString() {
  return 'AuthSession(token: $token, email: $email, nombre: $nombre, rol: $rol, usuarioId: $usuarioId, permisos: $permisos)';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 String token, String email, String nombre, String? rol, int usuarioId, List<String> permisos
});




}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? email = null,Object? nombre = null,Object? rol = freezed,Object? usuarioId = null,Object? permisos = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,rol: freezed == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int,permisos: null == permisos ? _self.permisos : permisos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String email,  String nombre,  String? rol,  int usuarioId,  List<String> permisos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.token,_that.email,_that.nombre,_that.rol,_that.usuarioId,_that.permisos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String email,  String nombre,  String? rol,  int usuarioId,  List<String> permisos)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.token,_that.email,_that.nombre,_that.rol,_that.usuarioId,_that.permisos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String email,  String nombre,  String? rol,  int usuarioId,  List<String> permisos)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.token,_that.email,_that.nombre,_that.rol,_that.usuarioId,_that.permisos);case _:
  return null;

}
}

}

/// @nodoc


class _AuthSession implements AuthSession {
  const _AuthSession({required this.token, required this.email, required this.nombre, this.rol, required this.usuarioId, final  List<String> permisos = const <String>[]}): _permisos = permisos;
  

@override final  String token;
@override final  String email;
@override final  String nombre;
@override final  String? rol;
@override final  int usuarioId;
 final  List<String> _permisos;
@override@JsonKey() List<String> get permisos {
  if (_permisos is EqualUnmodifiableListView) return _permisos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permisos);
}


/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.token, token) || other.token == token)&&(identical(other.email, email) || other.email == email)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.rol, rol) || other.rol == rol)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&const DeepCollectionEquality().equals(other._permisos, _permisos));
}


@override
int get hashCode => Object.hash(runtimeType,token,email,nombre,rol,usuarioId,const DeepCollectionEquality().hash(_permisos));

@override
String toString() {
  return 'AuthSession(token: $token, email: $email, nombre: $nombre, rol: $rol, usuarioId: $usuarioId, permisos: $permisos)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 String token, String email, String nombre, String? rol, int usuarioId, List<String> permisos
});




}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? email = null,Object? nombre = null,Object? rol = freezed,Object? usuarioId = null,Object? permisos = null,}) {
  return _then(_AuthSession(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,rol: freezed == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int,permisos: null == permisos ? _self._permisos : permisos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
