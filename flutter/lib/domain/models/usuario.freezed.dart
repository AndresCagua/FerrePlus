// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'usuario.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Usuario {

 int get id; String get nombre; String get email; String? get telefono; bool get activo; int? get rolId; String? get rolNombre; List<String> get permisos;
/// Create a copy of Usuario
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsuarioCopyWith<Usuario> get copyWith => _$UsuarioCopyWithImpl<Usuario>(this as Usuario, _$identity);

  /// Serializes this Usuario to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Usuario&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.email, email) || other.email == email)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.rolId, rolId) || other.rolId == rolId)&&(identical(other.rolNombre, rolNombre) || other.rolNombre == rolNombre)&&const DeepCollectionEquality().equals(other.permisos, permisos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,email,telefono,activo,rolId,rolNombre,const DeepCollectionEquality().hash(permisos));

@override
String toString() {
  return 'Usuario(id: $id, nombre: $nombre, email: $email, telefono: $telefono, activo: $activo, rolId: $rolId, rolNombre: $rolNombre, permisos: $permisos)';
}


}

/// @nodoc
abstract mixin class $UsuarioCopyWith<$Res>  {
  factory $UsuarioCopyWith(Usuario value, $Res Function(Usuario) _then) = _$UsuarioCopyWithImpl;
@useResult
$Res call({
 int id, String nombre, String email, String? telefono, bool activo, int? rolId, String? rolNombre, List<String> permisos
});




}
/// @nodoc
class _$UsuarioCopyWithImpl<$Res>
    implements $UsuarioCopyWith<$Res> {
  _$UsuarioCopyWithImpl(this._self, this._then);

  final Usuario _self;
  final $Res Function(Usuario) _then;

/// Create a copy of Usuario
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? email = null,Object? telefono = freezed,Object? activo = null,Object? rolId = freezed,Object? rolNombre = freezed,Object? permisos = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,rolId: freezed == rolId ? _self.rolId : rolId // ignore: cast_nullable_to_non_nullable
as int?,rolNombre: freezed == rolNombre ? _self.rolNombre : rolNombre // ignore: cast_nullable_to_non_nullable
as String?,permisos: null == permisos ? _self.permisos : permisos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Usuario].
extension UsuarioPatterns on Usuario {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Usuario value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Usuario() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Usuario value)  $default,){
final _that = this;
switch (_that) {
case _Usuario():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Usuario value)?  $default,){
final _that = this;
switch (_that) {
case _Usuario() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nombre,  String email,  String? telefono,  bool activo,  int? rolId,  String? rolNombre,  List<String> permisos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Usuario() when $default != null:
return $default(_that.id,_that.nombre,_that.email,_that.telefono,_that.activo,_that.rolId,_that.rolNombre,_that.permisos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nombre,  String email,  String? telefono,  bool activo,  int? rolId,  String? rolNombre,  List<String> permisos)  $default,) {final _that = this;
switch (_that) {
case _Usuario():
return $default(_that.id,_that.nombre,_that.email,_that.telefono,_that.activo,_that.rolId,_that.rolNombre,_that.permisos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nombre,  String email,  String? telefono,  bool activo,  int? rolId,  String? rolNombre,  List<String> permisos)?  $default,) {final _that = this;
switch (_that) {
case _Usuario() when $default != null:
return $default(_that.id,_that.nombre,_that.email,_that.telefono,_that.activo,_that.rolId,_that.rolNombre,_that.permisos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Usuario implements Usuario {
  const _Usuario({required this.id, required this.nombre, required this.email, this.telefono, this.activo = true, this.rolId, this.rolNombre, final  List<String> permisos = const <String>[]}): _permisos = permisos;
  factory _Usuario.fromJson(Map<String, dynamic> json) => _$UsuarioFromJson(json);

@override final  int id;
@override final  String nombre;
@override final  String email;
@override final  String? telefono;
@override@JsonKey() final  bool activo;
@override final  int? rolId;
@override final  String? rolNombre;
 final  List<String> _permisos;
@override@JsonKey() List<String> get permisos {
  if (_permisos is EqualUnmodifiableListView) return _permisos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permisos);
}


/// Create a copy of Usuario
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsuarioCopyWith<_Usuario> get copyWith => __$UsuarioCopyWithImpl<_Usuario>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsuarioToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Usuario&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.email, email) || other.email == email)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.rolId, rolId) || other.rolId == rolId)&&(identical(other.rolNombre, rolNombre) || other.rolNombre == rolNombre)&&const DeepCollectionEquality().equals(other._permisos, _permisos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,email,telefono,activo,rolId,rolNombre,const DeepCollectionEquality().hash(_permisos));

@override
String toString() {
  return 'Usuario(id: $id, nombre: $nombre, email: $email, telefono: $telefono, activo: $activo, rolId: $rolId, rolNombre: $rolNombre, permisos: $permisos)';
}


}

/// @nodoc
abstract mixin class _$UsuarioCopyWith<$Res> implements $UsuarioCopyWith<$Res> {
  factory _$UsuarioCopyWith(_Usuario value, $Res Function(_Usuario) _then) = __$UsuarioCopyWithImpl;
@override @useResult
$Res call({
 int id, String nombre, String email, String? telefono, bool activo, int? rolId, String? rolNombre, List<String> permisos
});




}
/// @nodoc
class __$UsuarioCopyWithImpl<$Res>
    implements _$UsuarioCopyWith<$Res> {
  __$UsuarioCopyWithImpl(this._self, this._then);

  final _Usuario _self;
  final $Res Function(_Usuario) _then;

/// Create a copy of Usuario
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? email = null,Object? telefono = freezed,Object? activo = null,Object? rolId = freezed,Object? rolNombre = freezed,Object? permisos = null,}) {
  return _then(_Usuario(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,rolId: freezed == rolId ? _self.rolId : rolId // ignore: cast_nullable_to_non_nullable
as int?,rolNombre: freezed == rolNombre ? _self.rolNombre : rolNombre // ignore: cast_nullable_to_non_nullable
as String?,permisos: null == permisos ? _self._permisos : permisos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
