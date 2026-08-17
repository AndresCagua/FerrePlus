// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Categoria {

 int get id; String get nombre; String? get descripcion; DateTime? get fechaCreacion;
/// Create a copy of Categoria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoriaCopyWith<Categoria> get copyWith => _$CategoriaCopyWithImpl<Categoria>(this as Categoria, _$identity);

  /// Serializes this Categoria to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Categoria&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,descripcion,fechaCreacion);

@override
String toString() {
  return 'Categoria(id: $id, nombre: $nombre, descripcion: $descripcion, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class $CategoriaCopyWith<$Res>  {
  factory $CategoriaCopyWith(Categoria value, $Res Function(Categoria) _then) = _$CategoriaCopyWithImpl;
@useResult
$Res call({
 int id, String nombre, String? descripcion, DateTime? fechaCreacion
});




}
/// @nodoc
class _$CategoriaCopyWithImpl<$Res>
    implements $CategoriaCopyWith<$Res> {
  _$CategoriaCopyWithImpl(this._self, this._then);

  final Categoria _self;
  final $Res Function(Categoria) _then;

/// Create a copy of Categoria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? descripcion = freezed,Object? fechaCreacion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Categoria].
extension CategoriaPatterns on Categoria {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Categoria value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Categoria() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Categoria value)  $default,){
final _that = this;
switch (_that) {
case _Categoria():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Categoria value)?  $default,){
final _that = this;
switch (_that) {
case _Categoria() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nombre,  String? descripcion,  DateTime? fechaCreacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Categoria() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nombre,  String? descripcion,  DateTime? fechaCreacion)  $default,) {final _that = this;
switch (_that) {
case _Categoria():
return $default(_that.id,_that.nombre,_that.descripcion,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nombre,  String? descripcion,  DateTime? fechaCreacion)?  $default,) {final _that = this;
switch (_that) {
case _Categoria() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.fechaCreacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Categoria implements Categoria {
  const _Categoria({required this.id, required this.nombre, this.descripcion, this.fechaCreacion});
  factory _Categoria.fromJson(Map<String, dynamic> json) => _$CategoriaFromJson(json);

@override final  int id;
@override final  String nombre;
@override final  String? descripcion;
@override final  DateTime? fechaCreacion;

/// Create a copy of Categoria
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoriaCopyWith<_Categoria> get copyWith => __$CategoriaCopyWithImpl<_Categoria>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoriaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Categoria&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,descripcion,fechaCreacion);

@override
String toString() {
  return 'Categoria(id: $id, nombre: $nombre, descripcion: $descripcion, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class _$CategoriaCopyWith<$Res> implements $CategoriaCopyWith<$Res> {
  factory _$CategoriaCopyWith(_Categoria value, $Res Function(_Categoria) _then) = __$CategoriaCopyWithImpl;
@override @useResult
$Res call({
 int id, String nombre, String? descripcion, DateTime? fechaCreacion
});




}
/// @nodoc
class __$CategoriaCopyWithImpl<$Res>
    implements _$CategoriaCopyWith<$Res> {
  __$CategoriaCopyWithImpl(this._self, this._then);

  final _Categoria _self;
  final $Res Function(_Categoria) _then;

/// Create a copy of Categoria
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? descripcion = freezed,Object? fechaCreacion = freezed,}) {
  return _then(_Categoria(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Proveedor {

 int get id; String get nombre; String? get ruc; String? get contacto; String? get telefono; String? get email; String? get direccion; bool get activo; DateTime? get fechaCreacion;
/// Create a copy of Proveedor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProveedorCopyWith<Proveedor> get copyWith => _$ProveedorCopyWithImpl<Proveedor>(this as Proveedor, _$identity);

  /// Serializes this Proveedor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Proveedor&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.ruc, ruc) || other.ruc == ruc)&&(identical(other.contacto, contacto) || other.contacto == contacto)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.email, email) || other.email == email)&&(identical(other.direccion, direccion) || other.direccion == direccion)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,ruc,contacto,telefono,email,direccion,activo,fechaCreacion);

@override
String toString() {
  return 'Proveedor(id: $id, nombre: $nombre, ruc: $ruc, contacto: $contacto, telefono: $telefono, email: $email, direccion: $direccion, activo: $activo, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class $ProveedorCopyWith<$Res>  {
  factory $ProveedorCopyWith(Proveedor value, $Res Function(Proveedor) _then) = _$ProveedorCopyWithImpl;
@useResult
$Res call({
 int id, String nombre, String? ruc, String? contacto, String? telefono, String? email, String? direccion, bool activo, DateTime? fechaCreacion
});




}
/// @nodoc
class _$ProveedorCopyWithImpl<$Res>
    implements $ProveedorCopyWith<$Res> {
  _$ProveedorCopyWithImpl(this._self, this._then);

  final Proveedor _self;
  final $Res Function(Proveedor) _then;

/// Create a copy of Proveedor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? ruc = freezed,Object? contacto = freezed,Object? telefono = freezed,Object? email = freezed,Object? direccion = freezed,Object? activo = null,Object? fechaCreacion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,ruc: freezed == ruc ? _self.ruc : ruc // ignore: cast_nullable_to_non_nullable
as String?,contacto: freezed == contacto ? _self.contacto : contacto // ignore: cast_nullable_to_non_nullable
as String?,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,direccion: freezed == direccion ? _self.direccion : direccion // ignore: cast_nullable_to_non_nullable
as String?,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Proveedor].
extension ProveedorPatterns on Proveedor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Proveedor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Proveedor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Proveedor value)  $default,){
final _that = this;
switch (_that) {
case _Proveedor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Proveedor value)?  $default,){
final _that = this;
switch (_that) {
case _Proveedor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nombre,  String? ruc,  String? contacto,  String? telefono,  String? email,  String? direccion,  bool activo,  DateTime? fechaCreacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Proveedor() when $default != null:
return $default(_that.id,_that.nombre,_that.ruc,_that.contacto,_that.telefono,_that.email,_that.direccion,_that.activo,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nombre,  String? ruc,  String? contacto,  String? telefono,  String? email,  String? direccion,  bool activo,  DateTime? fechaCreacion)  $default,) {final _that = this;
switch (_that) {
case _Proveedor():
return $default(_that.id,_that.nombre,_that.ruc,_that.contacto,_that.telefono,_that.email,_that.direccion,_that.activo,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nombre,  String? ruc,  String? contacto,  String? telefono,  String? email,  String? direccion,  bool activo,  DateTime? fechaCreacion)?  $default,) {final _that = this;
switch (_that) {
case _Proveedor() when $default != null:
return $default(_that.id,_that.nombre,_that.ruc,_that.contacto,_that.telefono,_that.email,_that.direccion,_that.activo,_that.fechaCreacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Proveedor implements Proveedor {
  const _Proveedor({required this.id, required this.nombre, this.ruc, this.contacto, this.telefono, this.email, this.direccion, this.activo = true, this.fechaCreacion});
  factory _Proveedor.fromJson(Map<String, dynamic> json) => _$ProveedorFromJson(json);

@override final  int id;
@override final  String nombre;
@override final  String? ruc;
@override final  String? contacto;
@override final  String? telefono;
@override final  String? email;
@override final  String? direccion;
@override@JsonKey() final  bool activo;
@override final  DateTime? fechaCreacion;

/// Create a copy of Proveedor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProveedorCopyWith<_Proveedor> get copyWith => __$ProveedorCopyWithImpl<_Proveedor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProveedorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Proveedor&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.ruc, ruc) || other.ruc == ruc)&&(identical(other.contacto, contacto) || other.contacto == contacto)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.email, email) || other.email == email)&&(identical(other.direccion, direccion) || other.direccion == direccion)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,ruc,contacto,telefono,email,direccion,activo,fechaCreacion);

@override
String toString() {
  return 'Proveedor(id: $id, nombre: $nombre, ruc: $ruc, contacto: $contacto, telefono: $telefono, email: $email, direccion: $direccion, activo: $activo, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class _$ProveedorCopyWith<$Res> implements $ProveedorCopyWith<$Res> {
  factory _$ProveedorCopyWith(_Proveedor value, $Res Function(_Proveedor) _then) = __$ProveedorCopyWithImpl;
@override @useResult
$Res call({
 int id, String nombre, String? ruc, String? contacto, String? telefono, String? email, String? direccion, bool activo, DateTime? fechaCreacion
});




}
/// @nodoc
class __$ProveedorCopyWithImpl<$Res>
    implements _$ProveedorCopyWith<$Res> {
  __$ProveedorCopyWithImpl(this._self, this._then);

  final _Proveedor _self;
  final $Res Function(_Proveedor) _then;

/// Create a copy of Proveedor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? ruc = freezed,Object? contacto = freezed,Object? telefono = freezed,Object? email = freezed,Object? direccion = freezed,Object? activo = null,Object? fechaCreacion = freezed,}) {
  return _then(_Proveedor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,ruc: freezed == ruc ? _self.ruc : ruc // ignore: cast_nullable_to_non_nullable
as String?,contacto: freezed == contacto ? _self.contacto : contacto // ignore: cast_nullable_to_non_nullable
as String?,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,direccion: freezed == direccion ? _self.direccion : direccion // ignore: cast_nullable_to_non_nullable
as String?,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Cliente {

 int get id; String get nombre; String? get ruc; String? get telefono; String? get email; String? get direccion; double get saldoPendiente; bool get activo; DateTime? get fechaCreacion;
/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClienteCopyWith<Cliente> get copyWith => _$ClienteCopyWithImpl<Cliente>(this as Cliente, _$identity);

  /// Serializes this Cliente to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Cliente&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.ruc, ruc) || other.ruc == ruc)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.email, email) || other.email == email)&&(identical(other.direccion, direccion) || other.direccion == direccion)&&(identical(other.saldoPendiente, saldoPendiente) || other.saldoPendiente == saldoPendiente)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,ruc,telefono,email,direccion,saldoPendiente,activo,fechaCreacion);

@override
String toString() {
  return 'Cliente(id: $id, nombre: $nombre, ruc: $ruc, telefono: $telefono, email: $email, direccion: $direccion, saldoPendiente: $saldoPendiente, activo: $activo, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class $ClienteCopyWith<$Res>  {
  factory $ClienteCopyWith(Cliente value, $Res Function(Cliente) _then) = _$ClienteCopyWithImpl;
@useResult
$Res call({
 int id, String nombre, String? ruc, String? telefono, String? email, String? direccion, double saldoPendiente, bool activo, DateTime? fechaCreacion
});




}
/// @nodoc
class _$ClienteCopyWithImpl<$Res>
    implements $ClienteCopyWith<$Res> {
  _$ClienteCopyWithImpl(this._self, this._then);

  final Cliente _self;
  final $Res Function(Cliente) _then;

/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? ruc = freezed,Object? telefono = freezed,Object? email = freezed,Object? direccion = freezed,Object? saldoPendiente = null,Object? activo = null,Object? fechaCreacion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,ruc: freezed == ruc ? _self.ruc : ruc // ignore: cast_nullable_to_non_nullable
as String?,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,direccion: freezed == direccion ? _self.direccion : direccion // ignore: cast_nullable_to_non_nullable
as String?,saldoPendiente: null == saldoPendiente ? _self.saldoPendiente : saldoPendiente // ignore: cast_nullable_to_non_nullable
as double,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Cliente].
extension ClientePatterns on Cliente {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Cliente value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Cliente() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Cliente value)  $default,){
final _that = this;
switch (_that) {
case _Cliente():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Cliente value)?  $default,){
final _that = this;
switch (_that) {
case _Cliente() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nombre,  String? ruc,  String? telefono,  String? email,  String? direccion,  double saldoPendiente,  bool activo,  DateTime? fechaCreacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Cliente() when $default != null:
return $default(_that.id,_that.nombre,_that.ruc,_that.telefono,_that.email,_that.direccion,_that.saldoPendiente,_that.activo,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nombre,  String? ruc,  String? telefono,  String? email,  String? direccion,  double saldoPendiente,  bool activo,  DateTime? fechaCreacion)  $default,) {final _that = this;
switch (_that) {
case _Cliente():
return $default(_that.id,_that.nombre,_that.ruc,_that.telefono,_that.email,_that.direccion,_that.saldoPendiente,_that.activo,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nombre,  String? ruc,  String? telefono,  String? email,  String? direccion,  double saldoPendiente,  bool activo,  DateTime? fechaCreacion)?  $default,) {final _that = this;
switch (_that) {
case _Cliente() when $default != null:
return $default(_that.id,_that.nombre,_that.ruc,_that.telefono,_that.email,_that.direccion,_that.saldoPendiente,_that.activo,_that.fechaCreacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Cliente implements Cliente {
  const _Cliente({required this.id, required this.nombre, this.ruc, this.telefono, this.email, this.direccion, this.saldoPendiente = 0, this.activo = true, this.fechaCreacion});
  factory _Cliente.fromJson(Map<String, dynamic> json) => _$ClienteFromJson(json);

@override final  int id;
@override final  String nombre;
@override final  String? ruc;
@override final  String? telefono;
@override final  String? email;
@override final  String? direccion;
@override@JsonKey() final  double saldoPendiente;
@override@JsonKey() final  bool activo;
@override final  DateTime? fechaCreacion;

/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClienteCopyWith<_Cliente> get copyWith => __$ClienteCopyWithImpl<_Cliente>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClienteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Cliente&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.ruc, ruc) || other.ruc == ruc)&&(identical(other.telefono, telefono) || other.telefono == telefono)&&(identical(other.email, email) || other.email == email)&&(identical(other.direccion, direccion) || other.direccion == direccion)&&(identical(other.saldoPendiente, saldoPendiente) || other.saldoPendiente == saldoPendiente)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,ruc,telefono,email,direccion,saldoPendiente,activo,fechaCreacion);

@override
String toString() {
  return 'Cliente(id: $id, nombre: $nombre, ruc: $ruc, telefono: $telefono, email: $email, direccion: $direccion, saldoPendiente: $saldoPendiente, activo: $activo, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class _$ClienteCopyWith<$Res> implements $ClienteCopyWith<$Res> {
  factory _$ClienteCopyWith(_Cliente value, $Res Function(_Cliente) _then) = __$ClienteCopyWithImpl;
@override @useResult
$Res call({
 int id, String nombre, String? ruc, String? telefono, String? email, String? direccion, double saldoPendiente, bool activo, DateTime? fechaCreacion
});




}
/// @nodoc
class __$ClienteCopyWithImpl<$Res>
    implements _$ClienteCopyWith<$Res> {
  __$ClienteCopyWithImpl(this._self, this._then);

  final _Cliente _self;
  final $Res Function(_Cliente) _then;

/// Create a copy of Cliente
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? ruc = freezed,Object? telefono = freezed,Object? email = freezed,Object? direccion = freezed,Object? saldoPendiente = null,Object? activo = null,Object? fechaCreacion = freezed,}) {
  return _then(_Cliente(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,ruc: freezed == ruc ? _self.ruc : ruc // ignore: cast_nullable_to_non_nullable
as String?,telefono: freezed == telefono ? _self.telefono : telefono // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,direccion: freezed == direccion ? _self.direccion : direccion // ignore: cast_nullable_to_non_nullable
as String?,saldoPendiente: null == saldoPendiente ? _self.saldoPendiente : saldoPendiente // ignore: cast_nullable_to_non_nullable
as double,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$Producto {

 int get id; String get nombre; String? get descripcion; String? get codigoBarras; String? get ubicacion; int get stockActual; int? get stockMinimo; int? get stockMaximo; double get precioCompra; double get precioVenta; String? get unidadMedida; String? get imagen; Categoria? get categoria; Proveedor? get proveedor; bool get activo; DateTime? get fechaCreacion; DateTime? get fechaActualizacion;
/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductoCopyWith<Producto> get copyWith => _$ProductoCopyWithImpl<Producto>(this as Producto, _$identity);

  /// Serializes this Producto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Producto&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.codigoBarras, codigoBarras) || other.codigoBarras == codigoBarras)&&(identical(other.ubicacion, ubicacion) || other.ubicacion == ubicacion)&&(identical(other.stockActual, stockActual) || other.stockActual == stockActual)&&(identical(other.stockMinimo, stockMinimo) || other.stockMinimo == stockMinimo)&&(identical(other.stockMaximo, stockMaximo) || other.stockMaximo == stockMaximo)&&(identical(other.precioCompra, precioCompra) || other.precioCompra == precioCompra)&&(identical(other.precioVenta, precioVenta) || other.precioVenta == precioVenta)&&(identical(other.unidadMedida, unidadMedida) || other.unidadMedida == unidadMedida)&&(identical(other.imagen, imagen) || other.imagen == imagen)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.proveedor, proveedor) || other.proveedor == proveedor)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.fechaActualizacion, fechaActualizacion) || other.fechaActualizacion == fechaActualizacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,descripcion,codigoBarras,ubicacion,stockActual,stockMinimo,stockMaximo,precioCompra,precioVenta,unidadMedida,imagen,categoria,proveedor,activo,fechaCreacion,fechaActualizacion);

@override
String toString() {
  return 'Producto(id: $id, nombre: $nombre, descripcion: $descripcion, codigoBarras: $codigoBarras, ubicacion: $ubicacion, stockActual: $stockActual, stockMinimo: $stockMinimo, stockMaximo: $stockMaximo, precioCompra: $precioCompra, precioVenta: $precioVenta, unidadMedida: $unidadMedida, imagen: $imagen, categoria: $categoria, proveedor: $proveedor, activo: $activo, fechaCreacion: $fechaCreacion, fechaActualizacion: $fechaActualizacion)';
}


}

/// @nodoc
abstract mixin class $ProductoCopyWith<$Res>  {
  factory $ProductoCopyWith(Producto value, $Res Function(Producto) _then) = _$ProductoCopyWithImpl;
@useResult
$Res call({
 int id, String nombre, String? descripcion, String? codigoBarras, String? ubicacion, int stockActual, int? stockMinimo, int? stockMaximo, double precioCompra, double precioVenta, String? unidadMedida, String? imagen, Categoria? categoria, Proveedor? proveedor, bool activo, DateTime? fechaCreacion, DateTime? fechaActualizacion
});


$CategoriaCopyWith<$Res>? get categoria;$ProveedorCopyWith<$Res>? get proveedor;

}
/// @nodoc
class _$ProductoCopyWithImpl<$Res>
    implements $ProductoCopyWith<$Res> {
  _$ProductoCopyWithImpl(this._self, this._then);

  final Producto _self;
  final $Res Function(Producto) _then;

/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? descripcion = freezed,Object? codigoBarras = freezed,Object? ubicacion = freezed,Object? stockActual = null,Object? stockMinimo = freezed,Object? stockMaximo = freezed,Object? precioCompra = null,Object? precioVenta = null,Object? unidadMedida = freezed,Object? imagen = freezed,Object? categoria = freezed,Object? proveedor = freezed,Object? activo = null,Object? fechaCreacion = freezed,Object? fechaActualizacion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,codigoBarras: freezed == codigoBarras ? _self.codigoBarras : codigoBarras // ignore: cast_nullable_to_non_nullable
as String?,ubicacion: freezed == ubicacion ? _self.ubicacion : ubicacion // ignore: cast_nullable_to_non_nullable
as String?,stockActual: null == stockActual ? _self.stockActual : stockActual // ignore: cast_nullable_to_non_nullable
as int,stockMinimo: freezed == stockMinimo ? _self.stockMinimo : stockMinimo // ignore: cast_nullable_to_non_nullable
as int?,stockMaximo: freezed == stockMaximo ? _self.stockMaximo : stockMaximo // ignore: cast_nullable_to_non_nullable
as int?,precioCompra: null == precioCompra ? _self.precioCompra : precioCompra // ignore: cast_nullable_to_non_nullable
as double,precioVenta: null == precioVenta ? _self.precioVenta : precioVenta // ignore: cast_nullable_to_non_nullable
as double,unidadMedida: freezed == unidadMedida ? _self.unidadMedida : unidadMedida // ignore: cast_nullable_to_non_nullable
as String?,imagen: freezed == imagen ? _self.imagen : imagen // ignore: cast_nullable_to_non_nullable
as String?,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as Categoria?,proveedor: freezed == proveedor ? _self.proveedor : proveedor // ignore: cast_nullable_to_non_nullable
as Proveedor?,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaActualizacion: freezed == fechaActualizacion ? _self.fechaActualizacion : fechaActualizacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoriaCopyWith<$Res>? get categoria {
    if (_self.categoria == null) {
    return null;
  }

  return $CategoriaCopyWith<$Res>(_self.categoria!, (value) {
    return _then(_self.copyWith(categoria: value));
  });
}/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProveedorCopyWith<$Res>? get proveedor {
    if (_self.proveedor == null) {
    return null;
  }

  return $ProveedorCopyWith<$Res>(_self.proveedor!, (value) {
    return _then(_self.copyWith(proveedor: value));
  });
}
}


/// Adds pattern-matching-related methods to [Producto].
extension ProductoPatterns on Producto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Producto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Producto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Producto value)  $default,){
final _that = this;
switch (_that) {
case _Producto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Producto value)?  $default,){
final _that = this;
switch (_that) {
case _Producto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String nombre,  String? descripcion,  String? codigoBarras,  String? ubicacion,  int stockActual,  int? stockMinimo,  int? stockMaximo,  double precioCompra,  double precioVenta,  String? unidadMedida,  String? imagen,  Categoria? categoria,  Proveedor? proveedor,  bool activo,  DateTime? fechaCreacion,  DateTime? fechaActualizacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Producto() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.codigoBarras,_that.ubicacion,_that.stockActual,_that.stockMinimo,_that.stockMaximo,_that.precioCompra,_that.precioVenta,_that.unidadMedida,_that.imagen,_that.categoria,_that.proveedor,_that.activo,_that.fechaCreacion,_that.fechaActualizacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String nombre,  String? descripcion,  String? codigoBarras,  String? ubicacion,  int stockActual,  int? stockMinimo,  int? stockMaximo,  double precioCompra,  double precioVenta,  String? unidadMedida,  String? imagen,  Categoria? categoria,  Proveedor? proveedor,  bool activo,  DateTime? fechaCreacion,  DateTime? fechaActualizacion)  $default,) {final _that = this;
switch (_that) {
case _Producto():
return $default(_that.id,_that.nombre,_that.descripcion,_that.codigoBarras,_that.ubicacion,_that.stockActual,_that.stockMinimo,_that.stockMaximo,_that.precioCompra,_that.precioVenta,_that.unidadMedida,_that.imagen,_that.categoria,_that.proveedor,_that.activo,_that.fechaCreacion,_that.fechaActualizacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String nombre,  String? descripcion,  String? codigoBarras,  String? ubicacion,  int stockActual,  int? stockMinimo,  int? stockMaximo,  double precioCompra,  double precioVenta,  String? unidadMedida,  String? imagen,  Categoria? categoria,  Proveedor? proveedor,  bool activo,  DateTime? fechaCreacion,  DateTime? fechaActualizacion)?  $default,) {final _that = this;
switch (_that) {
case _Producto() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.codigoBarras,_that.ubicacion,_that.stockActual,_that.stockMinimo,_that.stockMaximo,_that.precioCompra,_that.precioVenta,_that.unidadMedida,_that.imagen,_that.categoria,_that.proveedor,_that.activo,_that.fechaCreacion,_that.fechaActualizacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Producto implements Producto {
  const _Producto({required this.id, required this.nombre, this.descripcion, this.codigoBarras, this.ubicacion, this.stockActual = 0, this.stockMinimo, this.stockMaximo, this.precioCompra = 0, this.precioVenta = 0, this.unidadMedida, this.imagen, this.categoria, this.proveedor, this.activo = true, this.fechaCreacion, this.fechaActualizacion});
  factory _Producto.fromJson(Map<String, dynamic> json) => _$ProductoFromJson(json);

@override final  int id;
@override final  String nombre;
@override final  String? descripcion;
@override final  String? codigoBarras;
@override final  String? ubicacion;
@override@JsonKey() final  int stockActual;
@override final  int? stockMinimo;
@override final  int? stockMaximo;
@override@JsonKey() final  double precioCompra;
@override@JsonKey() final  double precioVenta;
@override final  String? unidadMedida;
@override final  String? imagen;
@override final  Categoria? categoria;
@override final  Proveedor? proveedor;
@override@JsonKey() final  bool activo;
@override final  DateTime? fechaCreacion;
@override final  DateTime? fechaActualizacion;

/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductoCopyWith<_Producto> get copyWith => __$ProductoCopyWithImpl<_Producto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Producto&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.codigoBarras, codigoBarras) || other.codigoBarras == codigoBarras)&&(identical(other.ubicacion, ubicacion) || other.ubicacion == ubicacion)&&(identical(other.stockActual, stockActual) || other.stockActual == stockActual)&&(identical(other.stockMinimo, stockMinimo) || other.stockMinimo == stockMinimo)&&(identical(other.stockMaximo, stockMaximo) || other.stockMaximo == stockMaximo)&&(identical(other.precioCompra, precioCompra) || other.precioCompra == precioCompra)&&(identical(other.precioVenta, precioVenta) || other.precioVenta == precioVenta)&&(identical(other.unidadMedida, unidadMedida) || other.unidadMedida == unidadMedida)&&(identical(other.imagen, imagen) || other.imagen == imagen)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.proveedor, proveedor) || other.proveedor == proveedor)&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.fechaActualizacion, fechaActualizacion) || other.fechaActualizacion == fechaActualizacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,descripcion,codigoBarras,ubicacion,stockActual,stockMinimo,stockMaximo,precioCompra,precioVenta,unidadMedida,imagen,categoria,proveedor,activo,fechaCreacion,fechaActualizacion);

@override
String toString() {
  return 'Producto(id: $id, nombre: $nombre, descripcion: $descripcion, codigoBarras: $codigoBarras, ubicacion: $ubicacion, stockActual: $stockActual, stockMinimo: $stockMinimo, stockMaximo: $stockMaximo, precioCompra: $precioCompra, precioVenta: $precioVenta, unidadMedida: $unidadMedida, imagen: $imagen, categoria: $categoria, proveedor: $proveedor, activo: $activo, fechaCreacion: $fechaCreacion, fechaActualizacion: $fechaActualizacion)';
}


}

/// @nodoc
abstract mixin class _$ProductoCopyWith<$Res> implements $ProductoCopyWith<$Res> {
  factory _$ProductoCopyWith(_Producto value, $Res Function(_Producto) _then) = __$ProductoCopyWithImpl;
@override @useResult
$Res call({
 int id, String nombre, String? descripcion, String? codigoBarras, String? ubicacion, int stockActual, int? stockMinimo, int? stockMaximo, double precioCompra, double precioVenta, String? unidadMedida, String? imagen, Categoria? categoria, Proveedor? proveedor, bool activo, DateTime? fechaCreacion, DateTime? fechaActualizacion
});


@override $CategoriaCopyWith<$Res>? get categoria;@override $ProveedorCopyWith<$Res>? get proveedor;

}
/// @nodoc
class __$ProductoCopyWithImpl<$Res>
    implements _$ProductoCopyWith<$Res> {
  __$ProductoCopyWithImpl(this._self, this._then);

  final _Producto _self;
  final $Res Function(_Producto) _then;

/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? descripcion = freezed,Object? codigoBarras = freezed,Object? ubicacion = freezed,Object? stockActual = null,Object? stockMinimo = freezed,Object? stockMaximo = freezed,Object? precioCompra = null,Object? precioVenta = null,Object? unidadMedida = freezed,Object? imagen = freezed,Object? categoria = freezed,Object? proveedor = freezed,Object? activo = null,Object? fechaCreacion = freezed,Object? fechaActualizacion = freezed,}) {
  return _then(_Producto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,codigoBarras: freezed == codigoBarras ? _self.codigoBarras : codigoBarras // ignore: cast_nullable_to_non_nullable
as String?,ubicacion: freezed == ubicacion ? _self.ubicacion : ubicacion // ignore: cast_nullable_to_non_nullable
as String?,stockActual: null == stockActual ? _self.stockActual : stockActual // ignore: cast_nullable_to_non_nullable
as int,stockMinimo: freezed == stockMinimo ? _self.stockMinimo : stockMinimo // ignore: cast_nullable_to_non_nullable
as int?,stockMaximo: freezed == stockMaximo ? _self.stockMaximo : stockMaximo // ignore: cast_nullable_to_non_nullable
as int?,precioCompra: null == precioCompra ? _self.precioCompra : precioCompra // ignore: cast_nullable_to_non_nullable
as double,precioVenta: null == precioVenta ? _self.precioVenta : precioVenta // ignore: cast_nullable_to_non_nullable
as double,unidadMedida: freezed == unidadMedida ? _self.unidadMedida : unidadMedida // ignore: cast_nullable_to_non_nullable
as String?,imagen: freezed == imagen ? _self.imagen : imagen // ignore: cast_nullable_to_non_nullable
as String?,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as Categoria?,proveedor: freezed == proveedor ? _self.proveedor : proveedor // ignore: cast_nullable_to_non_nullable
as Proveedor?,activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaActualizacion: freezed == fechaActualizacion ? _self.fechaActualizacion : fechaActualizacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoriaCopyWith<$Res>? get categoria {
    if (_self.categoria == null) {
    return null;
  }

  return $CategoriaCopyWith<$Res>(_self.categoria!, (value) {
    return _then(_self.copyWith(categoria: value));
  });
}/// Create a copy of Producto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProveedorCopyWith<$Res>? get proveedor {
    if (_self.proveedor == null) {
    return null;
  }

  return $ProveedorCopyWith<$Res>(_self.proveedor!, (value) {
    return _then(_self.copyWith(proveedor: value));
  });
}
}

// dart format on
