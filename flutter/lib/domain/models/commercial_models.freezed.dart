// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commercial_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DetalleVenta {

 int? get id; int? get productoId; String? get productoNombre; int get cantidad; num get precioUnitario; num? get subtotal;
/// Create a copy of DetalleVenta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetalleVentaCopyWith<DetalleVenta> get copyWith => _$DetalleVentaCopyWithImpl<DetalleVenta>(this as DetalleVenta, _$identity);

  /// Serializes this DetalleVenta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetalleVenta&&(identical(other.id, id) || other.id == id)&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.productoNombre, productoNombre) || other.productoNombre == productoNombre)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productoId,productoNombre,cantidad,precioUnitario,subtotal);

@override
String toString() {
  return 'DetalleVenta(id: $id, productoId: $productoId, productoNombre: $productoNombre, cantidad: $cantidad, precioUnitario: $precioUnitario, subtotal: $subtotal)';
}


}

/// @nodoc
abstract mixin class $DetalleVentaCopyWith<$Res>  {
  factory $DetalleVentaCopyWith(DetalleVenta value, $Res Function(DetalleVenta) _then) = _$DetalleVentaCopyWithImpl;
@useResult
$Res call({
 int? id, int? productoId, String? productoNombre, int cantidad, num precioUnitario, num? subtotal
});




}
/// @nodoc
class _$DetalleVentaCopyWithImpl<$Res>
    implements $DetalleVentaCopyWith<$Res> {
  _$DetalleVentaCopyWithImpl(this._self, this._then);

  final DetalleVenta _self;
  final $Res Function(DetalleVenta) _then;

/// Create a copy of DetalleVenta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? productoId = freezed,Object? productoNombre = freezed,Object? cantidad = null,Object? precioUnitario = null,Object? subtotal = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,productoId: freezed == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int?,productoNombre: freezed == productoNombre ? _self.productoNombre : productoNombre // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,precioUnitario: null == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num,subtotal: freezed == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [DetalleVenta].
extension DetalleVentaPatterns on DetalleVenta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetalleVenta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetalleVenta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetalleVenta value)  $default,){
final _that = this;
switch (_that) {
case _DetalleVenta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetalleVenta value)?  $default,){
final _that = this;
switch (_that) {
case _DetalleVenta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  int? productoId,  String? productoNombre,  int cantidad,  num precioUnitario,  num? subtotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetalleVenta() when $default != null:
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.precioUnitario,_that.subtotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  int? productoId,  String? productoNombre,  int cantidad,  num precioUnitario,  num? subtotal)  $default,) {final _that = this;
switch (_that) {
case _DetalleVenta():
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.precioUnitario,_that.subtotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  int? productoId,  String? productoNombre,  int cantidad,  num precioUnitario,  num? subtotal)?  $default,) {final _that = this;
switch (_that) {
case _DetalleVenta() when $default != null:
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.precioUnitario,_that.subtotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetalleVenta implements DetalleVenta {
  const _DetalleVenta({this.id, this.productoId, this.productoNombre, required this.cantidad, required this.precioUnitario, this.subtotal});
  factory _DetalleVenta.fromJson(Map<String, dynamic> json) => _$DetalleVentaFromJson(json);

@override final  int? id;
@override final  int? productoId;
@override final  String? productoNombre;
@override final  int cantidad;
@override final  num precioUnitario;
@override final  num? subtotal;

/// Create a copy of DetalleVenta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetalleVentaCopyWith<_DetalleVenta> get copyWith => __$DetalleVentaCopyWithImpl<_DetalleVenta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetalleVentaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetalleVenta&&(identical(other.id, id) || other.id == id)&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.productoNombre, productoNombre) || other.productoNombre == productoNombre)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productoId,productoNombre,cantidad,precioUnitario,subtotal);

@override
String toString() {
  return 'DetalleVenta(id: $id, productoId: $productoId, productoNombre: $productoNombre, cantidad: $cantidad, precioUnitario: $precioUnitario, subtotal: $subtotal)';
}


}

/// @nodoc
abstract mixin class _$DetalleVentaCopyWith<$Res> implements $DetalleVentaCopyWith<$Res> {
  factory _$DetalleVentaCopyWith(_DetalleVenta value, $Res Function(_DetalleVenta) _then) = __$DetalleVentaCopyWithImpl;
@override @useResult
$Res call({
 int? id, int? productoId, String? productoNombre, int cantidad, num precioUnitario, num? subtotal
});




}
/// @nodoc
class __$DetalleVentaCopyWithImpl<$Res>
    implements _$DetalleVentaCopyWith<$Res> {
  __$DetalleVentaCopyWithImpl(this._self, this._then);

  final _DetalleVenta _self;
  final $Res Function(_DetalleVenta) _then;

/// Create a copy of DetalleVenta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? productoId = freezed,Object? productoNombre = freezed,Object? cantidad = null,Object? precioUnitario = null,Object? subtotal = freezed,}) {
  return _then(_DetalleVenta(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,productoId: freezed == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int?,productoNombre: freezed == productoNombre ? _self.productoNombre : productoNombre // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,precioUnitario: null == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num,subtotal: freezed == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}


/// @nodoc
mixin _$Venta {

 int get id; String? get numeroFactura; int? get clienteId; String? get clienteNombre; num get subtotal; num get descuento; num get iva; num get total; String? get metodoPago; String? get estado; String? get observaciones; int? get usuarioId; DateTime? get fechaCreacion; DateTime? get fechaAnulacion; List<DetalleVenta> get detalles;
/// Create a copy of Venta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VentaCopyWith<Venta> get copyWith => _$VentaCopyWithImpl<Venta>(this as Venta, _$identity);

  /// Serializes this Venta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Venta&&(identical(other.id, id) || other.id == id)&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.clienteNombre, clienteNombre) || other.clienteNombre == clienteNombre)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.fechaAnulacion, fechaAnulacion) || other.fechaAnulacion == fechaAnulacion)&&const DeepCollectionEquality().equals(other.detalles, detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,numeroFactura,clienteId,clienteNombre,subtotal,descuento,iva,total,metodoPago,estado,observaciones,usuarioId,fechaCreacion,fechaAnulacion,const DeepCollectionEquality().hash(detalles));

@override
String toString() {
  return 'Venta(id: $id, numeroFactura: $numeroFactura, clienteId: $clienteId, clienteNombre: $clienteNombre, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, metodoPago: $metodoPago, estado: $estado, observaciones: $observaciones, usuarioId: $usuarioId, fechaCreacion: $fechaCreacion, fechaAnulacion: $fechaAnulacion, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class $VentaCopyWith<$Res>  {
  factory $VentaCopyWith(Venta value, $Res Function(Venta) _then) = _$VentaCopyWithImpl;
@useResult
$Res call({
 int id, String? numeroFactura, int? clienteId, String? clienteNombre, num subtotal, num descuento, num iva, num total, String? metodoPago, String? estado, String? observaciones, int? usuarioId, DateTime? fechaCreacion, DateTime? fechaAnulacion, List<DetalleVenta> detalles
});




}
/// @nodoc
class _$VentaCopyWithImpl<$Res>
    implements $VentaCopyWith<$Res> {
  _$VentaCopyWithImpl(this._self, this._then);

  final Venta _self;
  final $Res Function(Venta) _then;

/// Create a copy of Venta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? numeroFactura = freezed,Object? clienteId = freezed,Object? clienteNombre = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? metodoPago = freezed,Object? estado = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,Object? fechaCreacion = freezed,Object? fechaAnulacion = freezed,Object? detalles = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,numeroFactura: freezed == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String?,clienteId: freezed == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as int?,clienteNombre: freezed == clienteNombre ? _self.clienteNombre : clienteNombre // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaAnulacion: freezed == fechaAnulacion ? _self.fechaAnulacion : fechaAnulacion // ignore: cast_nullable_to_non_nullable
as DateTime?,detalles: null == detalles ? _self.detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleVenta>,
  ));
}

}


/// Adds pattern-matching-related methods to [Venta].
extension VentaPatterns on Venta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Venta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Venta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Venta value)  $default,){
final _that = this;
switch (_that) {
case _Venta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Venta value)?  $default,){
final _that = this;
switch (_that) {
case _Venta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? numeroFactura,  int? clienteId,  String? clienteNombre,  num subtotal,  num descuento,  num iva,  num total,  String? metodoPago,  String? estado,  String? observaciones,  int? usuarioId,  DateTime? fechaCreacion,  DateTime? fechaAnulacion,  List<DetalleVenta> detalles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Venta() when $default != null:
return $default(_that.id,_that.numeroFactura,_that.clienteId,_that.clienteNombre,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.metodoPago,_that.estado,_that.observaciones,_that.usuarioId,_that.fechaCreacion,_that.fechaAnulacion,_that.detalles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? numeroFactura,  int? clienteId,  String? clienteNombre,  num subtotal,  num descuento,  num iva,  num total,  String? metodoPago,  String? estado,  String? observaciones,  int? usuarioId,  DateTime? fechaCreacion,  DateTime? fechaAnulacion,  List<DetalleVenta> detalles)  $default,) {final _that = this;
switch (_that) {
case _Venta():
return $default(_that.id,_that.numeroFactura,_that.clienteId,_that.clienteNombre,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.metodoPago,_that.estado,_that.observaciones,_that.usuarioId,_that.fechaCreacion,_that.fechaAnulacion,_that.detalles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? numeroFactura,  int? clienteId,  String? clienteNombre,  num subtotal,  num descuento,  num iva,  num total,  String? metodoPago,  String? estado,  String? observaciones,  int? usuarioId,  DateTime? fechaCreacion,  DateTime? fechaAnulacion,  List<DetalleVenta> detalles)?  $default,) {final _that = this;
switch (_that) {
case _Venta() when $default != null:
return $default(_that.id,_that.numeroFactura,_that.clienteId,_that.clienteNombre,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.metodoPago,_that.estado,_that.observaciones,_that.usuarioId,_that.fechaCreacion,_that.fechaAnulacion,_that.detalles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Venta implements Venta {
  const _Venta({required this.id, this.numeroFactura, this.clienteId, this.clienteNombre, required this.subtotal, required this.descuento, required this.iva, required this.total, this.metodoPago, this.estado, this.observaciones, this.usuarioId, this.fechaCreacion, this.fechaAnulacion, final  List<DetalleVenta> detalles = const <DetalleVenta>[]}): _detalles = detalles;
  factory _Venta.fromJson(Map<String, dynamic> json) => _$VentaFromJson(json);

@override final  int id;
@override final  String? numeroFactura;
@override final  int? clienteId;
@override final  String? clienteNombre;
@override final  num subtotal;
@override final  num descuento;
@override final  num iva;
@override final  num total;
@override final  String? metodoPago;
@override final  String? estado;
@override final  String? observaciones;
@override final  int? usuarioId;
@override final  DateTime? fechaCreacion;
@override final  DateTime? fechaAnulacion;
 final  List<DetalleVenta> _detalles;
@override@JsonKey() List<DetalleVenta> get detalles {
  if (_detalles is EqualUnmodifiableListView) return _detalles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detalles);
}


/// Create a copy of Venta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VentaCopyWith<_Venta> get copyWith => __$VentaCopyWithImpl<_Venta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VentaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Venta&&(identical(other.id, id) || other.id == id)&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.clienteNombre, clienteNombre) || other.clienteNombre == clienteNombre)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&(identical(other.fechaAnulacion, fechaAnulacion) || other.fechaAnulacion == fechaAnulacion)&&const DeepCollectionEquality().equals(other._detalles, _detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,numeroFactura,clienteId,clienteNombre,subtotal,descuento,iva,total,metodoPago,estado,observaciones,usuarioId,fechaCreacion,fechaAnulacion,const DeepCollectionEquality().hash(_detalles));

@override
String toString() {
  return 'Venta(id: $id, numeroFactura: $numeroFactura, clienteId: $clienteId, clienteNombre: $clienteNombre, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, metodoPago: $metodoPago, estado: $estado, observaciones: $observaciones, usuarioId: $usuarioId, fechaCreacion: $fechaCreacion, fechaAnulacion: $fechaAnulacion, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class _$VentaCopyWith<$Res> implements $VentaCopyWith<$Res> {
  factory _$VentaCopyWith(_Venta value, $Res Function(_Venta) _then) = __$VentaCopyWithImpl;
@override @useResult
$Res call({
 int id, String? numeroFactura, int? clienteId, String? clienteNombre, num subtotal, num descuento, num iva, num total, String? metodoPago, String? estado, String? observaciones, int? usuarioId, DateTime? fechaCreacion, DateTime? fechaAnulacion, List<DetalleVenta> detalles
});




}
/// @nodoc
class __$VentaCopyWithImpl<$Res>
    implements _$VentaCopyWith<$Res> {
  __$VentaCopyWithImpl(this._self, this._then);

  final _Venta _self;
  final $Res Function(_Venta) _then;

/// Create a copy of Venta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? numeroFactura = freezed,Object? clienteId = freezed,Object? clienteNombre = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? metodoPago = freezed,Object? estado = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,Object? fechaCreacion = freezed,Object? fechaAnulacion = freezed,Object? detalles = null,}) {
  return _then(_Venta(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,numeroFactura: freezed == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String?,clienteId: freezed == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as int?,clienteNombre: freezed == clienteNombre ? _self.clienteNombre : clienteNombre // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaAnulacion: freezed == fechaAnulacion ? _self.fechaAnulacion : fechaAnulacion // ignore: cast_nullable_to_non_nullable
as DateTime?,detalles: null == detalles ? _self._detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleVenta>,
  ));
}


}


/// @nodoc
mixin _$VentaRequest {

 String? get numeroFactura; int? get clienteId; num get subtotal; num get descuento; num get iva; num get total; String? get metodoPago; String? get estado; String? get observaciones; int? get usuarioId; List<DetalleVenta> get detalles;
/// Create a copy of VentaRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VentaRequestCopyWith<VentaRequest> get copyWith => _$VentaRequestCopyWithImpl<VentaRequest>(this as VentaRequest, _$identity);

  /// Serializes this VentaRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VentaRequest&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&const DeepCollectionEquality().equals(other.detalles, detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,numeroFactura,clienteId,subtotal,descuento,iva,total,metodoPago,estado,observaciones,usuarioId,const DeepCollectionEquality().hash(detalles));

@override
String toString() {
  return 'VentaRequest(numeroFactura: $numeroFactura, clienteId: $clienteId, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, metodoPago: $metodoPago, estado: $estado, observaciones: $observaciones, usuarioId: $usuarioId, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class $VentaRequestCopyWith<$Res>  {
  factory $VentaRequestCopyWith(VentaRequest value, $Res Function(VentaRequest) _then) = _$VentaRequestCopyWithImpl;
@useResult
$Res call({
 String? numeroFactura, int? clienteId, num subtotal, num descuento, num iva, num total, String? metodoPago, String? estado, String? observaciones, int? usuarioId, List<DetalleVenta> detalles
});




}
/// @nodoc
class _$VentaRequestCopyWithImpl<$Res>
    implements $VentaRequestCopyWith<$Res> {
  _$VentaRequestCopyWithImpl(this._self, this._then);

  final VentaRequest _self;
  final $Res Function(VentaRequest) _then;

/// Create a copy of VentaRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? numeroFactura = freezed,Object? clienteId = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? metodoPago = freezed,Object? estado = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,Object? detalles = null,}) {
  return _then(_self.copyWith(
numeroFactura: freezed == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String?,clienteId: freezed == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as int?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,detalles: null == detalles ? _self.detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleVenta>,
  ));
}

}


/// Adds pattern-matching-related methods to [VentaRequest].
extension VentaRequestPatterns on VentaRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VentaRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VentaRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VentaRequest value)  $default,){
final _that = this;
switch (_that) {
case _VentaRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VentaRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VentaRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? numeroFactura,  int? clienteId,  num subtotal,  num descuento,  num iva,  num total,  String? metodoPago,  String? estado,  String? observaciones,  int? usuarioId,  List<DetalleVenta> detalles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VentaRequest() when $default != null:
return $default(_that.numeroFactura,_that.clienteId,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.metodoPago,_that.estado,_that.observaciones,_that.usuarioId,_that.detalles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? numeroFactura,  int? clienteId,  num subtotal,  num descuento,  num iva,  num total,  String? metodoPago,  String? estado,  String? observaciones,  int? usuarioId,  List<DetalleVenta> detalles)  $default,) {final _that = this;
switch (_that) {
case _VentaRequest():
return $default(_that.numeroFactura,_that.clienteId,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.metodoPago,_that.estado,_that.observaciones,_that.usuarioId,_that.detalles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? numeroFactura,  int? clienteId,  num subtotal,  num descuento,  num iva,  num total,  String? metodoPago,  String? estado,  String? observaciones,  int? usuarioId,  List<DetalleVenta> detalles)?  $default,) {final _that = this;
switch (_that) {
case _VentaRequest() when $default != null:
return $default(_that.numeroFactura,_that.clienteId,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.metodoPago,_that.estado,_that.observaciones,_that.usuarioId,_that.detalles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VentaRequest implements VentaRequest {
  const _VentaRequest({this.numeroFactura, this.clienteId, required this.subtotal, required this.descuento, required this.iva, required this.total, this.metodoPago, this.estado, this.observaciones, this.usuarioId, required final  List<DetalleVenta> detalles}): _detalles = detalles;
  factory _VentaRequest.fromJson(Map<String, dynamic> json) => _$VentaRequestFromJson(json);

@override final  String? numeroFactura;
@override final  int? clienteId;
@override final  num subtotal;
@override final  num descuento;
@override final  num iva;
@override final  num total;
@override final  String? metodoPago;
@override final  String? estado;
@override final  String? observaciones;
@override final  int? usuarioId;
 final  List<DetalleVenta> _detalles;
@override List<DetalleVenta> get detalles {
  if (_detalles is EqualUnmodifiableListView) return _detalles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detalles);
}


/// Create a copy of VentaRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VentaRequestCopyWith<_VentaRequest> get copyWith => __$VentaRequestCopyWithImpl<_VentaRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VentaRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VentaRequest&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&const DeepCollectionEquality().equals(other._detalles, _detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,numeroFactura,clienteId,subtotal,descuento,iva,total,metodoPago,estado,observaciones,usuarioId,const DeepCollectionEquality().hash(_detalles));

@override
String toString() {
  return 'VentaRequest(numeroFactura: $numeroFactura, clienteId: $clienteId, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, metodoPago: $metodoPago, estado: $estado, observaciones: $observaciones, usuarioId: $usuarioId, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class _$VentaRequestCopyWith<$Res> implements $VentaRequestCopyWith<$Res> {
  factory _$VentaRequestCopyWith(_VentaRequest value, $Res Function(_VentaRequest) _then) = __$VentaRequestCopyWithImpl;
@override @useResult
$Res call({
 String? numeroFactura, int? clienteId, num subtotal, num descuento, num iva, num total, String? metodoPago, String? estado, String? observaciones, int? usuarioId, List<DetalleVenta> detalles
});




}
/// @nodoc
class __$VentaRequestCopyWithImpl<$Res>
    implements _$VentaRequestCopyWith<$Res> {
  __$VentaRequestCopyWithImpl(this._self, this._then);

  final _VentaRequest _self;
  final $Res Function(_VentaRequest) _then;

/// Create a copy of VentaRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? numeroFactura = freezed,Object? clienteId = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? metodoPago = freezed,Object? estado = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,Object? detalles = null,}) {
  return _then(_VentaRequest(
numeroFactura: freezed == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String?,clienteId: freezed == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as int?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,detalles: null == detalles ? _self._detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleVenta>,
  ));
}


}


/// @nodoc
mixin _$DetalleCompra {

 int? get id; int? get productoId; String? get productoNombre; int get cantidad; num get precioUnitario; num? get subtotal;
/// Create a copy of DetalleCompra
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetalleCompraCopyWith<DetalleCompra> get copyWith => _$DetalleCompraCopyWithImpl<DetalleCompra>(this as DetalleCompra, _$identity);

  /// Serializes this DetalleCompra to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetalleCompra&&(identical(other.id, id) || other.id == id)&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.productoNombre, productoNombre) || other.productoNombre == productoNombre)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productoId,productoNombre,cantidad,precioUnitario,subtotal);

@override
String toString() {
  return 'DetalleCompra(id: $id, productoId: $productoId, productoNombre: $productoNombre, cantidad: $cantidad, precioUnitario: $precioUnitario, subtotal: $subtotal)';
}


}

/// @nodoc
abstract mixin class $DetalleCompraCopyWith<$Res>  {
  factory $DetalleCompraCopyWith(DetalleCompra value, $Res Function(DetalleCompra) _then) = _$DetalleCompraCopyWithImpl;
@useResult
$Res call({
 int? id, int? productoId, String? productoNombre, int cantidad, num precioUnitario, num? subtotal
});




}
/// @nodoc
class _$DetalleCompraCopyWithImpl<$Res>
    implements $DetalleCompraCopyWith<$Res> {
  _$DetalleCompraCopyWithImpl(this._self, this._then);

  final DetalleCompra _self;
  final $Res Function(DetalleCompra) _then;

/// Create a copy of DetalleCompra
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? productoId = freezed,Object? productoNombre = freezed,Object? cantidad = null,Object? precioUnitario = null,Object? subtotal = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,productoId: freezed == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int?,productoNombre: freezed == productoNombre ? _self.productoNombre : productoNombre // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,precioUnitario: null == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num,subtotal: freezed == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [DetalleCompra].
extension DetalleCompraPatterns on DetalleCompra {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetalleCompra value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetalleCompra() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetalleCompra value)  $default,){
final _that = this;
switch (_that) {
case _DetalleCompra():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetalleCompra value)?  $default,){
final _that = this;
switch (_that) {
case _DetalleCompra() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? id,  int? productoId,  String? productoNombre,  int cantidad,  num precioUnitario,  num? subtotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetalleCompra() when $default != null:
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.precioUnitario,_that.subtotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? id,  int? productoId,  String? productoNombre,  int cantidad,  num precioUnitario,  num? subtotal)  $default,) {final _that = this;
switch (_that) {
case _DetalleCompra():
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.precioUnitario,_that.subtotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? id,  int? productoId,  String? productoNombre,  int cantidad,  num precioUnitario,  num? subtotal)?  $default,) {final _that = this;
switch (_that) {
case _DetalleCompra() when $default != null:
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.precioUnitario,_that.subtotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetalleCompra implements DetalleCompra {
  const _DetalleCompra({this.id, this.productoId, this.productoNombre, required this.cantidad, required this.precioUnitario, this.subtotal});
  factory _DetalleCompra.fromJson(Map<String, dynamic> json) => _$DetalleCompraFromJson(json);

@override final  int? id;
@override final  int? productoId;
@override final  String? productoNombre;
@override final  int cantidad;
@override final  num precioUnitario;
@override final  num? subtotal;

/// Create a copy of DetalleCompra
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetalleCompraCopyWith<_DetalleCompra> get copyWith => __$DetalleCompraCopyWithImpl<_DetalleCompra>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetalleCompraToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetalleCompra&&(identical(other.id, id) || other.id == id)&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.productoNombre, productoNombre) || other.productoNombre == productoNombre)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productoId,productoNombre,cantidad,precioUnitario,subtotal);

@override
String toString() {
  return 'DetalleCompra(id: $id, productoId: $productoId, productoNombre: $productoNombre, cantidad: $cantidad, precioUnitario: $precioUnitario, subtotal: $subtotal)';
}


}

/// @nodoc
abstract mixin class _$DetalleCompraCopyWith<$Res> implements $DetalleCompraCopyWith<$Res> {
  factory _$DetalleCompraCopyWith(_DetalleCompra value, $Res Function(_DetalleCompra) _then) = __$DetalleCompraCopyWithImpl;
@override @useResult
$Res call({
 int? id, int? productoId, String? productoNombre, int cantidad, num precioUnitario, num? subtotal
});




}
/// @nodoc
class __$DetalleCompraCopyWithImpl<$Res>
    implements _$DetalleCompraCopyWith<$Res> {
  __$DetalleCompraCopyWithImpl(this._self, this._then);

  final _DetalleCompra _self;
  final $Res Function(_DetalleCompra) _then;

/// Create a copy of DetalleCompra
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? productoId = freezed,Object? productoNombre = freezed,Object? cantidad = null,Object? precioUnitario = null,Object? subtotal = freezed,}) {
  return _then(_DetalleCompra(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,productoId: freezed == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int?,productoNombre: freezed == productoNombre ? _self.productoNombre : productoNombre // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,precioUnitario: null == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num,subtotal: freezed == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}


/// @nodoc
mixin _$Compra {

 int get id; String get numeroFactura; int? get proveedorId; String? get proveedorNombre; num get subtotal; num get descuento; num get iva; num get total; String? get estado; String? get observaciones; DateTime? get fechaFactura; int? get usuarioId; DateTime? get fechaCreacion; List<DetalleCompra> get detalles;
/// Create a copy of Compra
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompraCopyWith<Compra> get copyWith => _$CompraCopyWithImpl<Compra>(this as Compra, _$identity);

  /// Serializes this Compra to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Compra&&(identical(other.id, id) || other.id == id)&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.proveedorId, proveedorId) || other.proveedorId == proveedorId)&&(identical(other.proveedorNombre, proveedorNombre) || other.proveedorNombre == proveedorNombre)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.fechaFactura, fechaFactura) || other.fechaFactura == fechaFactura)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&const DeepCollectionEquality().equals(other.detalles, detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,numeroFactura,proveedorId,proveedorNombre,subtotal,descuento,iva,total,estado,observaciones,fechaFactura,usuarioId,fechaCreacion,const DeepCollectionEquality().hash(detalles));

@override
String toString() {
  return 'Compra(id: $id, numeroFactura: $numeroFactura, proveedorId: $proveedorId, proveedorNombre: $proveedorNombre, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, estado: $estado, observaciones: $observaciones, fechaFactura: $fechaFactura, usuarioId: $usuarioId, fechaCreacion: $fechaCreacion, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class $CompraCopyWith<$Res>  {
  factory $CompraCopyWith(Compra value, $Res Function(Compra) _then) = _$CompraCopyWithImpl;
@useResult
$Res call({
 int id, String numeroFactura, int? proveedorId, String? proveedorNombre, num subtotal, num descuento, num iva, num total, String? estado, String? observaciones, DateTime? fechaFactura, int? usuarioId, DateTime? fechaCreacion, List<DetalleCompra> detalles
});




}
/// @nodoc
class _$CompraCopyWithImpl<$Res>
    implements $CompraCopyWith<$Res> {
  _$CompraCopyWithImpl(this._self, this._then);

  final Compra _self;
  final $Res Function(Compra) _then;

/// Create a copy of Compra
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? numeroFactura = null,Object? proveedorId = freezed,Object? proveedorNombre = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? estado = freezed,Object? observaciones = freezed,Object? fechaFactura = freezed,Object? usuarioId = freezed,Object? fechaCreacion = freezed,Object? detalles = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,numeroFactura: null == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String,proveedorId: freezed == proveedorId ? _self.proveedorId : proveedorId // ignore: cast_nullable_to_non_nullable
as int?,proveedorNombre: freezed == proveedorNombre ? _self.proveedorNombre : proveedorNombre // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,fechaFactura: freezed == fechaFactura ? _self.fechaFactura : fechaFactura // ignore: cast_nullable_to_non_nullable
as DateTime?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,detalles: null == detalles ? _self.detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleCompra>,
  ));
}

}


/// Adds pattern-matching-related methods to [Compra].
extension CompraPatterns on Compra {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Compra value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Compra() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Compra value)  $default,){
final _that = this;
switch (_that) {
case _Compra():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Compra value)?  $default,){
final _that = this;
switch (_that) {
case _Compra() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String numeroFactura,  int? proveedorId,  String? proveedorNombre,  num subtotal,  num descuento,  num iva,  num total,  String? estado,  String? observaciones,  DateTime? fechaFactura,  int? usuarioId,  DateTime? fechaCreacion,  List<DetalleCompra> detalles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Compra() when $default != null:
return $default(_that.id,_that.numeroFactura,_that.proveedorId,_that.proveedorNombre,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.estado,_that.observaciones,_that.fechaFactura,_that.usuarioId,_that.fechaCreacion,_that.detalles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String numeroFactura,  int? proveedorId,  String? proveedorNombre,  num subtotal,  num descuento,  num iva,  num total,  String? estado,  String? observaciones,  DateTime? fechaFactura,  int? usuarioId,  DateTime? fechaCreacion,  List<DetalleCompra> detalles)  $default,) {final _that = this;
switch (_that) {
case _Compra():
return $default(_that.id,_that.numeroFactura,_that.proveedorId,_that.proveedorNombre,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.estado,_that.observaciones,_that.fechaFactura,_that.usuarioId,_that.fechaCreacion,_that.detalles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String numeroFactura,  int? proveedorId,  String? proveedorNombre,  num subtotal,  num descuento,  num iva,  num total,  String? estado,  String? observaciones,  DateTime? fechaFactura,  int? usuarioId,  DateTime? fechaCreacion,  List<DetalleCompra> detalles)?  $default,) {final _that = this;
switch (_that) {
case _Compra() when $default != null:
return $default(_that.id,_that.numeroFactura,_that.proveedorId,_that.proveedorNombre,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.estado,_that.observaciones,_that.fechaFactura,_that.usuarioId,_that.fechaCreacion,_that.detalles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Compra implements Compra {
  const _Compra({required this.id, required this.numeroFactura, this.proveedorId, this.proveedorNombre, required this.subtotal, required this.descuento, required this.iva, required this.total, this.estado, this.observaciones, this.fechaFactura, this.usuarioId, this.fechaCreacion, final  List<DetalleCompra> detalles = const <DetalleCompra>[]}): _detalles = detalles;
  factory _Compra.fromJson(Map<String, dynamic> json) => _$CompraFromJson(json);

@override final  int id;
@override final  String numeroFactura;
@override final  int? proveedorId;
@override final  String? proveedorNombre;
@override final  num subtotal;
@override final  num descuento;
@override final  num iva;
@override final  num total;
@override final  String? estado;
@override final  String? observaciones;
@override final  DateTime? fechaFactura;
@override final  int? usuarioId;
@override final  DateTime? fechaCreacion;
 final  List<DetalleCompra> _detalles;
@override@JsonKey() List<DetalleCompra> get detalles {
  if (_detalles is EqualUnmodifiableListView) return _detalles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detalles);
}


/// Create a copy of Compra
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompraCopyWith<_Compra> get copyWith => __$CompraCopyWithImpl<_Compra>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompraToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Compra&&(identical(other.id, id) || other.id == id)&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.proveedorId, proveedorId) || other.proveedorId == proveedorId)&&(identical(other.proveedorNombre, proveedorNombre) || other.proveedorNombre == proveedorNombre)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.fechaFactura, fechaFactura) || other.fechaFactura == fechaFactura)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion)&&const DeepCollectionEquality().equals(other._detalles, _detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,numeroFactura,proveedorId,proveedorNombre,subtotal,descuento,iva,total,estado,observaciones,fechaFactura,usuarioId,fechaCreacion,const DeepCollectionEquality().hash(_detalles));

@override
String toString() {
  return 'Compra(id: $id, numeroFactura: $numeroFactura, proveedorId: $proveedorId, proveedorNombre: $proveedorNombre, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, estado: $estado, observaciones: $observaciones, fechaFactura: $fechaFactura, usuarioId: $usuarioId, fechaCreacion: $fechaCreacion, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class _$CompraCopyWith<$Res> implements $CompraCopyWith<$Res> {
  factory _$CompraCopyWith(_Compra value, $Res Function(_Compra) _then) = __$CompraCopyWithImpl;
@override @useResult
$Res call({
 int id, String numeroFactura, int? proveedorId, String? proveedorNombre, num subtotal, num descuento, num iva, num total, String? estado, String? observaciones, DateTime? fechaFactura, int? usuarioId, DateTime? fechaCreacion, List<DetalleCompra> detalles
});




}
/// @nodoc
class __$CompraCopyWithImpl<$Res>
    implements _$CompraCopyWith<$Res> {
  __$CompraCopyWithImpl(this._self, this._then);

  final _Compra _self;
  final $Res Function(_Compra) _then;

/// Create a copy of Compra
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? numeroFactura = null,Object? proveedorId = freezed,Object? proveedorNombre = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? estado = freezed,Object? observaciones = freezed,Object? fechaFactura = freezed,Object? usuarioId = freezed,Object? fechaCreacion = freezed,Object? detalles = null,}) {
  return _then(_Compra(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,numeroFactura: null == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String,proveedorId: freezed == proveedorId ? _self.proveedorId : proveedorId // ignore: cast_nullable_to_non_nullable
as int?,proveedorNombre: freezed == proveedorNombre ? _self.proveedorNombre : proveedorNombre // ignore: cast_nullable_to_non_nullable
as String?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,fechaFactura: freezed == fechaFactura ? _self.fechaFactura : fechaFactura // ignore: cast_nullable_to_non_nullable
as DateTime?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,detalles: null == detalles ? _self._detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleCompra>,
  ));
}


}


/// @nodoc
mixin _$CompraRequest {

 String get numeroFactura; int? get proveedorId; num get subtotal; num get descuento; num get iva; num get total; String? get estado; String? get observaciones; DateTime? get fechaFactura; int? get usuarioId; List<DetalleCompra> get detalles;
/// Create a copy of CompraRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompraRequestCopyWith<CompraRequest> get copyWith => _$CompraRequestCopyWithImpl<CompraRequest>(this as CompraRequest, _$identity);

  /// Serializes this CompraRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompraRequest&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.proveedorId, proveedorId) || other.proveedorId == proveedorId)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.fechaFactura, fechaFactura) || other.fechaFactura == fechaFactura)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&const DeepCollectionEquality().equals(other.detalles, detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,numeroFactura,proveedorId,subtotal,descuento,iva,total,estado,observaciones,fechaFactura,usuarioId,const DeepCollectionEquality().hash(detalles));

@override
String toString() {
  return 'CompraRequest(numeroFactura: $numeroFactura, proveedorId: $proveedorId, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, estado: $estado, observaciones: $observaciones, fechaFactura: $fechaFactura, usuarioId: $usuarioId, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class $CompraRequestCopyWith<$Res>  {
  factory $CompraRequestCopyWith(CompraRequest value, $Res Function(CompraRequest) _then) = _$CompraRequestCopyWithImpl;
@useResult
$Res call({
 String numeroFactura, int? proveedorId, num subtotal, num descuento, num iva, num total, String? estado, String? observaciones, DateTime? fechaFactura, int? usuarioId, List<DetalleCompra> detalles
});




}
/// @nodoc
class _$CompraRequestCopyWithImpl<$Res>
    implements $CompraRequestCopyWith<$Res> {
  _$CompraRequestCopyWithImpl(this._self, this._then);

  final CompraRequest _self;
  final $Res Function(CompraRequest) _then;

/// Create a copy of CompraRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? numeroFactura = null,Object? proveedorId = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? estado = freezed,Object? observaciones = freezed,Object? fechaFactura = freezed,Object? usuarioId = freezed,Object? detalles = null,}) {
  return _then(_self.copyWith(
numeroFactura: null == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String,proveedorId: freezed == proveedorId ? _self.proveedorId : proveedorId // ignore: cast_nullable_to_non_nullable
as int?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,fechaFactura: freezed == fechaFactura ? _self.fechaFactura : fechaFactura // ignore: cast_nullable_to_non_nullable
as DateTime?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,detalles: null == detalles ? _self.detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleCompra>,
  ));
}

}


/// Adds pattern-matching-related methods to [CompraRequest].
extension CompraRequestPatterns on CompraRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompraRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompraRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompraRequest value)  $default,){
final _that = this;
switch (_that) {
case _CompraRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompraRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CompraRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String numeroFactura,  int? proveedorId,  num subtotal,  num descuento,  num iva,  num total,  String? estado,  String? observaciones,  DateTime? fechaFactura,  int? usuarioId,  List<DetalleCompra> detalles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompraRequest() when $default != null:
return $default(_that.numeroFactura,_that.proveedorId,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.estado,_that.observaciones,_that.fechaFactura,_that.usuarioId,_that.detalles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String numeroFactura,  int? proveedorId,  num subtotal,  num descuento,  num iva,  num total,  String? estado,  String? observaciones,  DateTime? fechaFactura,  int? usuarioId,  List<DetalleCompra> detalles)  $default,) {final _that = this;
switch (_that) {
case _CompraRequest():
return $default(_that.numeroFactura,_that.proveedorId,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.estado,_that.observaciones,_that.fechaFactura,_that.usuarioId,_that.detalles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String numeroFactura,  int? proveedorId,  num subtotal,  num descuento,  num iva,  num total,  String? estado,  String? observaciones,  DateTime? fechaFactura,  int? usuarioId,  List<DetalleCompra> detalles)?  $default,) {final _that = this;
switch (_that) {
case _CompraRequest() when $default != null:
return $default(_that.numeroFactura,_that.proveedorId,_that.subtotal,_that.descuento,_that.iva,_that.total,_that.estado,_that.observaciones,_that.fechaFactura,_that.usuarioId,_that.detalles);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompraRequest implements CompraRequest {
  const _CompraRequest({required this.numeroFactura, this.proveedorId, required this.subtotal, required this.descuento, required this.iva, required this.total, this.estado, this.observaciones, this.fechaFactura, this.usuarioId, required final  List<DetalleCompra> detalles}): _detalles = detalles;
  factory _CompraRequest.fromJson(Map<String, dynamic> json) => _$CompraRequestFromJson(json);

@override final  String numeroFactura;
@override final  int? proveedorId;
@override final  num subtotal;
@override final  num descuento;
@override final  num iva;
@override final  num total;
@override final  String? estado;
@override final  String? observaciones;
@override final  DateTime? fechaFactura;
@override final  int? usuarioId;
 final  List<DetalleCompra> _detalles;
@override List<DetalleCompra> get detalles {
  if (_detalles is EqualUnmodifiableListView) return _detalles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_detalles);
}


/// Create a copy of CompraRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompraRequestCopyWith<_CompraRequest> get copyWith => __$CompraRequestCopyWithImpl<_CompraRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompraRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompraRequest&&(identical(other.numeroFactura, numeroFactura) || other.numeroFactura == numeroFactura)&&(identical(other.proveedorId, proveedorId) || other.proveedorId == proveedorId)&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.descuento, descuento) || other.descuento == descuento)&&(identical(other.iva, iva) || other.iva == iva)&&(identical(other.total, total) || other.total == total)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.fechaFactura, fechaFactura) || other.fechaFactura == fechaFactura)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&const DeepCollectionEquality().equals(other._detalles, _detalles));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,numeroFactura,proveedorId,subtotal,descuento,iva,total,estado,observaciones,fechaFactura,usuarioId,const DeepCollectionEquality().hash(_detalles));

@override
String toString() {
  return 'CompraRequest(numeroFactura: $numeroFactura, proveedorId: $proveedorId, subtotal: $subtotal, descuento: $descuento, iva: $iva, total: $total, estado: $estado, observaciones: $observaciones, fechaFactura: $fechaFactura, usuarioId: $usuarioId, detalles: $detalles)';
}


}

/// @nodoc
abstract mixin class _$CompraRequestCopyWith<$Res> implements $CompraRequestCopyWith<$Res> {
  factory _$CompraRequestCopyWith(_CompraRequest value, $Res Function(_CompraRequest) _then) = __$CompraRequestCopyWithImpl;
@override @useResult
$Res call({
 String numeroFactura, int? proveedorId, num subtotal, num descuento, num iva, num total, String? estado, String? observaciones, DateTime? fechaFactura, int? usuarioId, List<DetalleCompra> detalles
});




}
/// @nodoc
class __$CompraRequestCopyWithImpl<$Res>
    implements _$CompraRequestCopyWith<$Res> {
  __$CompraRequestCopyWithImpl(this._self, this._then);

  final _CompraRequest _self;
  final $Res Function(_CompraRequest) _then;

/// Create a copy of CompraRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? numeroFactura = null,Object? proveedorId = freezed,Object? subtotal = null,Object? descuento = null,Object? iva = null,Object? total = null,Object? estado = freezed,Object? observaciones = freezed,Object? fechaFactura = freezed,Object? usuarioId = freezed,Object? detalles = null,}) {
  return _then(_CompraRequest(
numeroFactura: null == numeroFactura ? _self.numeroFactura : numeroFactura // ignore: cast_nullable_to_non_nullable
as String,proveedorId: freezed == proveedorId ? _self.proveedorId : proveedorId // ignore: cast_nullable_to_non_nullable
as int?,subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,descuento: null == descuento ? _self.descuento : descuento // ignore: cast_nullable_to_non_nullable
as num,iva: null == iva ? _self.iva : iva // ignore: cast_nullable_to_non_nullable
as num,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as num,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,fechaFactura: freezed == fechaFactura ? _self.fechaFactura : fechaFactura // ignore: cast_nullable_to_non_nullable
as DateTime?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,detalles: null == detalles ? _self._detalles : detalles // ignore: cast_nullable_to_non_nullable
as List<DetalleCompra>,
  ));
}


}


/// @nodoc
mixin _$MovimientoStock {

 int get id; int? get productoId; String? get productoNombre; int get cantidad; String get tipo; String? get referencia; String? get motivo; num? get precioUnitario; int? get stockAnterior; int? get stockPosterior; int? get usuarioId; String? get usuarioNombre; DateTime? get fecha;
/// Create a copy of MovimientoStock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovimientoStockCopyWith<MovimientoStock> get copyWith => _$MovimientoStockCopyWithImpl<MovimientoStock>(this as MovimientoStock, _$identity);

  /// Serializes this MovimientoStock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovimientoStock&&(identical(other.id, id) || other.id == id)&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.productoNombre, productoNombre) || other.productoNombre == productoNombre)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.referencia, referencia) || other.referencia == referencia)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.stockAnterior, stockAnterior) || other.stockAnterior == stockAnterior)&&(identical(other.stockPosterior, stockPosterior) || other.stockPosterior == stockPosterior)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.usuarioNombre, usuarioNombre) || other.usuarioNombre == usuarioNombre)&&(identical(other.fecha, fecha) || other.fecha == fecha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productoId,productoNombre,cantidad,tipo,referencia,motivo,precioUnitario,stockAnterior,stockPosterior,usuarioId,usuarioNombre,fecha);

@override
String toString() {
  return 'MovimientoStock(id: $id, productoId: $productoId, productoNombre: $productoNombre, cantidad: $cantidad, tipo: $tipo, referencia: $referencia, motivo: $motivo, precioUnitario: $precioUnitario, stockAnterior: $stockAnterior, stockPosterior: $stockPosterior, usuarioId: $usuarioId, usuarioNombre: $usuarioNombre, fecha: $fecha)';
}


}

/// @nodoc
abstract mixin class $MovimientoStockCopyWith<$Res>  {
  factory $MovimientoStockCopyWith(MovimientoStock value, $Res Function(MovimientoStock) _then) = _$MovimientoStockCopyWithImpl;
@useResult
$Res call({
 int id, int? productoId, String? productoNombre, int cantidad, String tipo, String? referencia, String? motivo, num? precioUnitario, int? stockAnterior, int? stockPosterior, int? usuarioId, String? usuarioNombre, DateTime? fecha
});




}
/// @nodoc
class _$MovimientoStockCopyWithImpl<$Res>
    implements $MovimientoStockCopyWith<$Res> {
  _$MovimientoStockCopyWithImpl(this._self, this._then);

  final MovimientoStock _self;
  final $Res Function(MovimientoStock) _then;

/// Create a copy of MovimientoStock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productoId = freezed,Object? productoNombre = freezed,Object? cantidad = null,Object? tipo = null,Object? referencia = freezed,Object? motivo = freezed,Object? precioUnitario = freezed,Object? stockAnterior = freezed,Object? stockPosterior = freezed,Object? usuarioId = freezed,Object? usuarioNombre = freezed,Object? fecha = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productoId: freezed == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int?,productoNombre: freezed == productoNombre ? _self.productoNombre : productoNombre // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referencia: freezed == referencia ? _self.referencia : referencia // ignore: cast_nullable_to_non_nullable
as String?,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,precioUnitario: freezed == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num?,stockAnterior: freezed == stockAnterior ? _self.stockAnterior : stockAnterior // ignore: cast_nullable_to_non_nullable
as int?,stockPosterior: freezed == stockPosterior ? _self.stockPosterior : stockPosterior // ignore: cast_nullable_to_non_nullable
as int?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,usuarioNombre: freezed == usuarioNombre ? _self.usuarioNombre : usuarioNombre // ignore: cast_nullable_to_non_nullable
as String?,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MovimientoStock].
extension MovimientoStockPatterns on MovimientoStock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovimientoStock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovimientoStock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovimientoStock value)  $default,){
final _that = this;
switch (_that) {
case _MovimientoStock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovimientoStock value)?  $default,){
final _that = this;
switch (_that) {
case _MovimientoStock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int? productoId,  String? productoNombre,  int cantidad,  String tipo,  String? referencia,  String? motivo,  num? precioUnitario,  int? stockAnterior,  int? stockPosterior,  int? usuarioId,  String? usuarioNombre,  DateTime? fecha)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovimientoStock() when $default != null:
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.tipo,_that.referencia,_that.motivo,_that.precioUnitario,_that.stockAnterior,_that.stockPosterior,_that.usuarioId,_that.usuarioNombre,_that.fecha);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int? productoId,  String? productoNombre,  int cantidad,  String tipo,  String? referencia,  String? motivo,  num? precioUnitario,  int? stockAnterior,  int? stockPosterior,  int? usuarioId,  String? usuarioNombre,  DateTime? fecha)  $default,) {final _that = this;
switch (_that) {
case _MovimientoStock():
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.tipo,_that.referencia,_that.motivo,_that.precioUnitario,_that.stockAnterior,_that.stockPosterior,_that.usuarioId,_that.usuarioNombre,_that.fecha);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int? productoId,  String? productoNombre,  int cantidad,  String tipo,  String? referencia,  String? motivo,  num? precioUnitario,  int? stockAnterior,  int? stockPosterior,  int? usuarioId,  String? usuarioNombre,  DateTime? fecha)?  $default,) {final _that = this;
switch (_that) {
case _MovimientoStock() when $default != null:
return $default(_that.id,_that.productoId,_that.productoNombre,_that.cantidad,_that.tipo,_that.referencia,_that.motivo,_that.precioUnitario,_that.stockAnterior,_that.stockPosterior,_that.usuarioId,_that.usuarioNombre,_that.fecha);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MovimientoStock implements MovimientoStock {
  const _MovimientoStock({required this.id, this.productoId, this.productoNombre, required this.cantidad, required this.tipo, this.referencia, this.motivo, this.precioUnitario, this.stockAnterior, this.stockPosterior, this.usuarioId, this.usuarioNombre, this.fecha});
  factory _MovimientoStock.fromJson(Map<String, dynamic> json) => _$MovimientoStockFromJson(json);

@override final  int id;
@override final  int? productoId;
@override final  String? productoNombre;
@override final  int cantidad;
@override final  String tipo;
@override final  String? referencia;
@override final  String? motivo;
@override final  num? precioUnitario;
@override final  int? stockAnterior;
@override final  int? stockPosterior;
@override final  int? usuarioId;
@override final  String? usuarioNombre;
@override final  DateTime? fecha;

/// Create a copy of MovimientoStock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovimientoStockCopyWith<_MovimientoStock> get copyWith => __$MovimientoStockCopyWithImpl<_MovimientoStock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovimientoStockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovimientoStock&&(identical(other.id, id) || other.id == id)&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.productoNombre, productoNombre) || other.productoNombre == productoNombre)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.referencia, referencia) || other.referencia == referencia)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.stockAnterior, stockAnterior) || other.stockAnterior == stockAnterior)&&(identical(other.stockPosterior, stockPosterior) || other.stockPosterior == stockPosterior)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.usuarioNombre, usuarioNombre) || other.usuarioNombre == usuarioNombre)&&(identical(other.fecha, fecha) || other.fecha == fecha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productoId,productoNombre,cantidad,tipo,referencia,motivo,precioUnitario,stockAnterior,stockPosterior,usuarioId,usuarioNombre,fecha);

@override
String toString() {
  return 'MovimientoStock(id: $id, productoId: $productoId, productoNombre: $productoNombre, cantidad: $cantidad, tipo: $tipo, referencia: $referencia, motivo: $motivo, precioUnitario: $precioUnitario, stockAnterior: $stockAnterior, stockPosterior: $stockPosterior, usuarioId: $usuarioId, usuarioNombre: $usuarioNombre, fecha: $fecha)';
}


}

/// @nodoc
abstract mixin class _$MovimientoStockCopyWith<$Res> implements $MovimientoStockCopyWith<$Res> {
  factory _$MovimientoStockCopyWith(_MovimientoStock value, $Res Function(_MovimientoStock) _then) = __$MovimientoStockCopyWithImpl;
@override @useResult
$Res call({
 int id, int? productoId, String? productoNombre, int cantidad, String tipo, String? referencia, String? motivo, num? precioUnitario, int? stockAnterior, int? stockPosterior, int? usuarioId, String? usuarioNombre, DateTime? fecha
});




}
/// @nodoc
class __$MovimientoStockCopyWithImpl<$Res>
    implements _$MovimientoStockCopyWith<$Res> {
  __$MovimientoStockCopyWithImpl(this._self, this._then);

  final _MovimientoStock _self;
  final $Res Function(_MovimientoStock) _then;

/// Create a copy of MovimientoStock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productoId = freezed,Object? productoNombre = freezed,Object? cantidad = null,Object? tipo = null,Object? referencia = freezed,Object? motivo = freezed,Object? precioUnitario = freezed,Object? stockAnterior = freezed,Object? stockPosterior = freezed,Object? usuarioId = freezed,Object? usuarioNombre = freezed,Object? fecha = freezed,}) {
  return _then(_MovimientoStock(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productoId: freezed == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int?,productoNombre: freezed == productoNombre ? _self.productoNombre : productoNombre // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referencia: freezed == referencia ? _self.referencia : referencia // ignore: cast_nullable_to_non_nullable
as String?,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,precioUnitario: freezed == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num?,stockAnterior: freezed == stockAnterior ? _self.stockAnterior : stockAnterior // ignore: cast_nullable_to_non_nullable
as int?,stockPosterior: freezed == stockPosterior ? _self.stockPosterior : stockPosterior // ignore: cast_nullable_to_non_nullable
as int?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,usuarioNombre: freezed == usuarioNombre ? _self.usuarioNombre : usuarioNombre // ignore: cast_nullable_to_non_nullable
as String?,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$MovimientoStockRequest {

 int get productoId; int get cantidad; String get tipo; String? get referencia; String? get motivo; num? get precioUnitario; int? get usuarioId;
/// Create a copy of MovimientoStockRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovimientoStockRequestCopyWith<MovimientoStockRequest> get copyWith => _$MovimientoStockRequestCopyWithImpl<MovimientoStockRequest>(this as MovimientoStockRequest, _$identity);

  /// Serializes this MovimientoStockRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovimientoStockRequest&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.referencia, referencia) || other.referencia == referencia)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productoId,cantidad,tipo,referencia,motivo,precioUnitario,usuarioId);

@override
String toString() {
  return 'MovimientoStockRequest(productoId: $productoId, cantidad: $cantidad, tipo: $tipo, referencia: $referencia, motivo: $motivo, precioUnitario: $precioUnitario, usuarioId: $usuarioId)';
}


}

/// @nodoc
abstract mixin class $MovimientoStockRequestCopyWith<$Res>  {
  factory $MovimientoStockRequestCopyWith(MovimientoStockRequest value, $Res Function(MovimientoStockRequest) _then) = _$MovimientoStockRequestCopyWithImpl;
@useResult
$Res call({
 int productoId, int cantidad, String tipo, String? referencia, String? motivo, num? precioUnitario, int? usuarioId
});




}
/// @nodoc
class _$MovimientoStockRequestCopyWithImpl<$Res>
    implements $MovimientoStockRequestCopyWith<$Res> {
  _$MovimientoStockRequestCopyWithImpl(this._self, this._then);

  final MovimientoStockRequest _self;
  final $Res Function(MovimientoStockRequest) _then;

/// Create a copy of MovimientoStockRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productoId = null,Object? cantidad = null,Object? tipo = null,Object? referencia = freezed,Object? motivo = freezed,Object? precioUnitario = freezed,Object? usuarioId = freezed,}) {
  return _then(_self.copyWith(
productoId: null == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referencia: freezed == referencia ? _self.referencia : referencia // ignore: cast_nullable_to_non_nullable
as String?,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,precioUnitario: freezed == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [MovimientoStockRequest].
extension MovimientoStockRequestPatterns on MovimientoStockRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovimientoStockRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovimientoStockRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovimientoStockRequest value)  $default,){
final _that = this;
switch (_that) {
case _MovimientoStockRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovimientoStockRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MovimientoStockRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int productoId,  int cantidad,  String tipo,  String? referencia,  String? motivo,  num? precioUnitario,  int? usuarioId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovimientoStockRequest() when $default != null:
return $default(_that.productoId,_that.cantidad,_that.tipo,_that.referencia,_that.motivo,_that.precioUnitario,_that.usuarioId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int productoId,  int cantidad,  String tipo,  String? referencia,  String? motivo,  num? precioUnitario,  int? usuarioId)  $default,) {final _that = this;
switch (_that) {
case _MovimientoStockRequest():
return $default(_that.productoId,_that.cantidad,_that.tipo,_that.referencia,_that.motivo,_that.precioUnitario,_that.usuarioId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int productoId,  int cantidad,  String tipo,  String? referencia,  String? motivo,  num? precioUnitario,  int? usuarioId)?  $default,) {final _that = this;
switch (_that) {
case _MovimientoStockRequest() when $default != null:
return $default(_that.productoId,_that.cantidad,_that.tipo,_that.referencia,_that.motivo,_that.precioUnitario,_that.usuarioId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MovimientoStockRequest implements MovimientoStockRequest {
  const _MovimientoStockRequest({required this.productoId, required this.cantidad, required this.tipo, this.referencia, this.motivo, this.precioUnitario, this.usuarioId});
  factory _MovimientoStockRequest.fromJson(Map<String, dynamic> json) => _$MovimientoStockRequestFromJson(json);

@override final  int productoId;
@override final  int cantidad;
@override final  String tipo;
@override final  String? referencia;
@override final  String? motivo;
@override final  num? precioUnitario;
@override final  int? usuarioId;

/// Create a copy of MovimientoStockRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovimientoStockRequestCopyWith<_MovimientoStockRequest> get copyWith => __$MovimientoStockRequestCopyWithImpl<_MovimientoStockRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovimientoStockRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovimientoStockRequest&&(identical(other.productoId, productoId) || other.productoId == productoId)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.referencia, referencia) || other.referencia == referencia)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.precioUnitario, precioUnitario) || other.precioUnitario == precioUnitario)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productoId,cantidad,tipo,referencia,motivo,precioUnitario,usuarioId);

@override
String toString() {
  return 'MovimientoStockRequest(productoId: $productoId, cantidad: $cantidad, tipo: $tipo, referencia: $referencia, motivo: $motivo, precioUnitario: $precioUnitario, usuarioId: $usuarioId)';
}


}

/// @nodoc
abstract mixin class _$MovimientoStockRequestCopyWith<$Res> implements $MovimientoStockRequestCopyWith<$Res> {
  factory _$MovimientoStockRequestCopyWith(_MovimientoStockRequest value, $Res Function(_MovimientoStockRequest) _then) = __$MovimientoStockRequestCopyWithImpl;
@override @useResult
$Res call({
 int productoId, int cantidad, String tipo, String? referencia, String? motivo, num? precioUnitario, int? usuarioId
});




}
/// @nodoc
class __$MovimientoStockRequestCopyWithImpl<$Res>
    implements _$MovimientoStockRequestCopyWith<$Res> {
  __$MovimientoStockRequestCopyWithImpl(this._self, this._then);

  final _MovimientoStockRequest _self;
  final $Res Function(_MovimientoStockRequest) _then;

/// Create a copy of MovimientoStockRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productoId = null,Object? cantidad = null,Object? tipo = null,Object? referencia = freezed,Object? motivo = freezed,Object? precioUnitario = freezed,Object? usuarioId = freezed,}) {
  return _then(_MovimientoStockRequest(
productoId: null == productoId ? _self.productoId : productoId // ignore: cast_nullable_to_non_nullable
as int,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referencia: freezed == referencia ? _self.referencia : referencia // ignore: cast_nullable_to_non_nullable
as String?,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,precioUnitario: freezed == precioUnitario ? _self.precioUnitario : precioUnitario // ignore: cast_nullable_to_non_nullable
as num?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$Gasto {

 int get id; String get descripcion; num get monto; String? get categoria; String? get metodoPago; String? get numeroComprobante; DateTime? get fechaGasto; String? get observaciones; int? get usuarioId; DateTime? get fechaCreacion;
/// Create a copy of Gasto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GastoCopyWith<Gasto> get copyWith => _$GastoCopyWithImpl<Gasto>(this as Gasto, _$identity);

  /// Serializes this Gasto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Gasto&&(identical(other.id, id) || other.id == id)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.numeroComprobante, numeroComprobante) || other.numeroComprobante == numeroComprobante)&&(identical(other.fechaGasto, fechaGasto) || other.fechaGasto == fechaGasto)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,descripcion,monto,categoria,metodoPago,numeroComprobante,fechaGasto,observaciones,usuarioId,fechaCreacion);

@override
String toString() {
  return 'Gasto(id: $id, descripcion: $descripcion, monto: $monto, categoria: $categoria, metodoPago: $metodoPago, numeroComprobante: $numeroComprobante, fechaGasto: $fechaGasto, observaciones: $observaciones, usuarioId: $usuarioId, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class $GastoCopyWith<$Res>  {
  factory $GastoCopyWith(Gasto value, $Res Function(Gasto) _then) = _$GastoCopyWithImpl;
@useResult
$Res call({
 int id, String descripcion, num monto, String? categoria, String? metodoPago, String? numeroComprobante, DateTime? fechaGasto, String? observaciones, int? usuarioId, DateTime? fechaCreacion
});




}
/// @nodoc
class _$GastoCopyWithImpl<$Res>
    implements $GastoCopyWith<$Res> {
  _$GastoCopyWithImpl(this._self, this._then);

  final Gasto _self;
  final $Res Function(Gasto) _then;

/// Create a copy of Gasto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? descripcion = null,Object? monto = null,Object? categoria = freezed,Object? metodoPago = freezed,Object? numeroComprobante = freezed,Object? fechaGasto = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,Object? fechaCreacion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as num,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,numeroComprobante: freezed == numeroComprobante ? _self.numeroComprobante : numeroComprobante // ignore: cast_nullable_to_non_nullable
as String?,fechaGasto: freezed == fechaGasto ? _self.fechaGasto : fechaGasto // ignore: cast_nullable_to_non_nullable
as DateTime?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Gasto].
extension GastoPatterns on Gasto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Gasto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Gasto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Gasto value)  $default,){
final _that = this;
switch (_that) {
case _Gasto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Gasto value)?  $default,){
final _that = this;
switch (_that) {
case _Gasto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String descripcion,  num monto,  String? categoria,  String? metodoPago,  String? numeroComprobante,  DateTime? fechaGasto,  String? observaciones,  int? usuarioId,  DateTime? fechaCreacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Gasto() when $default != null:
return $default(_that.id,_that.descripcion,_that.monto,_that.categoria,_that.metodoPago,_that.numeroComprobante,_that.fechaGasto,_that.observaciones,_that.usuarioId,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String descripcion,  num monto,  String? categoria,  String? metodoPago,  String? numeroComprobante,  DateTime? fechaGasto,  String? observaciones,  int? usuarioId,  DateTime? fechaCreacion)  $default,) {final _that = this;
switch (_that) {
case _Gasto():
return $default(_that.id,_that.descripcion,_that.monto,_that.categoria,_that.metodoPago,_that.numeroComprobante,_that.fechaGasto,_that.observaciones,_that.usuarioId,_that.fechaCreacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String descripcion,  num monto,  String? categoria,  String? metodoPago,  String? numeroComprobante,  DateTime? fechaGasto,  String? observaciones,  int? usuarioId,  DateTime? fechaCreacion)?  $default,) {final _that = this;
switch (_that) {
case _Gasto() when $default != null:
return $default(_that.id,_that.descripcion,_that.monto,_that.categoria,_that.metodoPago,_that.numeroComprobante,_that.fechaGasto,_that.observaciones,_that.usuarioId,_that.fechaCreacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Gasto implements Gasto {
  const _Gasto({required this.id, required this.descripcion, required this.monto, this.categoria, this.metodoPago, this.numeroComprobante, this.fechaGasto, this.observaciones, this.usuarioId, this.fechaCreacion});
  factory _Gasto.fromJson(Map<String, dynamic> json) => _$GastoFromJson(json);

@override final  int id;
@override final  String descripcion;
@override final  num monto;
@override final  String? categoria;
@override final  String? metodoPago;
@override final  String? numeroComprobante;
@override final  DateTime? fechaGasto;
@override final  String? observaciones;
@override final  int? usuarioId;
@override final  DateTime? fechaCreacion;

/// Create a copy of Gasto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GastoCopyWith<_Gasto> get copyWith => __$GastoCopyWithImpl<_Gasto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GastoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Gasto&&(identical(other.id, id) || other.id == id)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.numeroComprobante, numeroComprobante) || other.numeroComprobante == numeroComprobante)&&(identical(other.fechaGasto, fechaGasto) || other.fechaGasto == fechaGasto)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.fechaCreacion, fechaCreacion) || other.fechaCreacion == fechaCreacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,descripcion,monto,categoria,metodoPago,numeroComprobante,fechaGasto,observaciones,usuarioId,fechaCreacion);

@override
String toString() {
  return 'Gasto(id: $id, descripcion: $descripcion, monto: $monto, categoria: $categoria, metodoPago: $metodoPago, numeroComprobante: $numeroComprobante, fechaGasto: $fechaGasto, observaciones: $observaciones, usuarioId: $usuarioId, fechaCreacion: $fechaCreacion)';
}


}

/// @nodoc
abstract mixin class _$GastoCopyWith<$Res> implements $GastoCopyWith<$Res> {
  factory _$GastoCopyWith(_Gasto value, $Res Function(_Gasto) _then) = __$GastoCopyWithImpl;
@override @useResult
$Res call({
 int id, String descripcion, num monto, String? categoria, String? metodoPago, String? numeroComprobante, DateTime? fechaGasto, String? observaciones, int? usuarioId, DateTime? fechaCreacion
});




}
/// @nodoc
class __$GastoCopyWithImpl<$Res>
    implements _$GastoCopyWith<$Res> {
  __$GastoCopyWithImpl(this._self, this._then);

  final _Gasto _self;
  final $Res Function(_Gasto) _then;

/// Create a copy of Gasto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? descripcion = null,Object? monto = null,Object? categoria = freezed,Object? metodoPago = freezed,Object? numeroComprobante = freezed,Object? fechaGasto = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,Object? fechaCreacion = freezed,}) {
  return _then(_Gasto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as num,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,numeroComprobante: freezed == numeroComprobante ? _self.numeroComprobante : numeroComprobante // ignore: cast_nullable_to_non_nullable
as String?,fechaGasto: freezed == fechaGasto ? _self.fechaGasto : fechaGasto // ignore: cast_nullable_to_non_nullable
as DateTime?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,fechaCreacion: freezed == fechaCreacion ? _self.fechaCreacion : fechaCreacion // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$GastoRequest {

 String get descripcion; num get monto; String? get categoria; String? get metodoPago; String? get numeroComprobante; DateTime? get fechaGasto; String? get observaciones; int? get usuarioId;
/// Create a copy of GastoRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GastoRequestCopyWith<GastoRequest> get copyWith => _$GastoRequestCopyWithImpl<GastoRequest>(this as GastoRequest, _$identity);

  /// Serializes this GastoRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GastoRequest&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.numeroComprobante, numeroComprobante) || other.numeroComprobante == numeroComprobante)&&(identical(other.fechaGasto, fechaGasto) || other.fechaGasto == fechaGasto)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,descripcion,monto,categoria,metodoPago,numeroComprobante,fechaGasto,observaciones,usuarioId);

@override
String toString() {
  return 'GastoRequest(descripcion: $descripcion, monto: $monto, categoria: $categoria, metodoPago: $metodoPago, numeroComprobante: $numeroComprobante, fechaGasto: $fechaGasto, observaciones: $observaciones, usuarioId: $usuarioId)';
}


}

/// @nodoc
abstract mixin class $GastoRequestCopyWith<$Res>  {
  factory $GastoRequestCopyWith(GastoRequest value, $Res Function(GastoRequest) _then) = _$GastoRequestCopyWithImpl;
@useResult
$Res call({
 String descripcion, num monto, String? categoria, String? metodoPago, String? numeroComprobante, DateTime? fechaGasto, String? observaciones, int? usuarioId
});




}
/// @nodoc
class _$GastoRequestCopyWithImpl<$Res>
    implements $GastoRequestCopyWith<$Res> {
  _$GastoRequestCopyWithImpl(this._self, this._then);

  final GastoRequest _self;
  final $Res Function(GastoRequest) _then;

/// Create a copy of GastoRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? descripcion = null,Object? monto = null,Object? categoria = freezed,Object? metodoPago = freezed,Object? numeroComprobante = freezed,Object? fechaGasto = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,}) {
  return _then(_self.copyWith(
descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as num,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,numeroComprobante: freezed == numeroComprobante ? _self.numeroComprobante : numeroComprobante // ignore: cast_nullable_to_non_nullable
as String?,fechaGasto: freezed == fechaGasto ? _self.fechaGasto : fechaGasto // ignore: cast_nullable_to_non_nullable
as DateTime?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [GastoRequest].
extension GastoRequestPatterns on GastoRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GastoRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GastoRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GastoRequest value)  $default,){
final _that = this;
switch (_that) {
case _GastoRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GastoRequest value)?  $default,){
final _that = this;
switch (_that) {
case _GastoRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String descripcion,  num monto,  String? categoria,  String? metodoPago,  String? numeroComprobante,  DateTime? fechaGasto,  String? observaciones,  int? usuarioId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GastoRequest() when $default != null:
return $default(_that.descripcion,_that.monto,_that.categoria,_that.metodoPago,_that.numeroComprobante,_that.fechaGasto,_that.observaciones,_that.usuarioId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String descripcion,  num monto,  String? categoria,  String? metodoPago,  String? numeroComprobante,  DateTime? fechaGasto,  String? observaciones,  int? usuarioId)  $default,) {final _that = this;
switch (_that) {
case _GastoRequest():
return $default(_that.descripcion,_that.monto,_that.categoria,_that.metodoPago,_that.numeroComprobante,_that.fechaGasto,_that.observaciones,_that.usuarioId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String descripcion,  num monto,  String? categoria,  String? metodoPago,  String? numeroComprobante,  DateTime? fechaGasto,  String? observaciones,  int? usuarioId)?  $default,) {final _that = this;
switch (_that) {
case _GastoRequest() when $default != null:
return $default(_that.descripcion,_that.monto,_that.categoria,_that.metodoPago,_that.numeroComprobante,_that.fechaGasto,_that.observaciones,_that.usuarioId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GastoRequest implements GastoRequest {
  const _GastoRequest({required this.descripcion, required this.monto, this.categoria, this.metodoPago, this.numeroComprobante, this.fechaGasto, this.observaciones, this.usuarioId});
  factory _GastoRequest.fromJson(Map<String, dynamic> json) => _$GastoRequestFromJson(json);

@override final  String descripcion;
@override final  num monto;
@override final  String? categoria;
@override final  String? metodoPago;
@override final  String? numeroComprobante;
@override final  DateTime? fechaGasto;
@override final  String? observaciones;
@override final  int? usuarioId;

/// Create a copy of GastoRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GastoRequestCopyWith<_GastoRequest> get copyWith => __$GastoRequestCopyWithImpl<_GastoRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GastoRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GastoRequest&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.monto, monto) || other.monto == monto)&&(identical(other.categoria, categoria) || other.categoria == categoria)&&(identical(other.metodoPago, metodoPago) || other.metodoPago == metodoPago)&&(identical(other.numeroComprobante, numeroComprobante) || other.numeroComprobante == numeroComprobante)&&(identical(other.fechaGasto, fechaGasto) || other.fechaGasto == fechaGasto)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,descripcion,monto,categoria,metodoPago,numeroComprobante,fechaGasto,observaciones,usuarioId);

@override
String toString() {
  return 'GastoRequest(descripcion: $descripcion, monto: $monto, categoria: $categoria, metodoPago: $metodoPago, numeroComprobante: $numeroComprobante, fechaGasto: $fechaGasto, observaciones: $observaciones, usuarioId: $usuarioId)';
}


}

/// @nodoc
abstract mixin class _$GastoRequestCopyWith<$Res> implements $GastoRequestCopyWith<$Res> {
  factory _$GastoRequestCopyWith(_GastoRequest value, $Res Function(_GastoRequest) _then) = __$GastoRequestCopyWithImpl;
@override @useResult
$Res call({
 String descripcion, num monto, String? categoria, String? metodoPago, String? numeroComprobante, DateTime? fechaGasto, String? observaciones, int? usuarioId
});




}
/// @nodoc
class __$GastoRequestCopyWithImpl<$Res>
    implements _$GastoRequestCopyWith<$Res> {
  __$GastoRequestCopyWithImpl(this._self, this._then);

  final _GastoRequest _self;
  final $Res Function(_GastoRequest) _then;

/// Create a copy of GastoRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? descripcion = null,Object? monto = null,Object? categoria = freezed,Object? metodoPago = freezed,Object? numeroComprobante = freezed,Object? fechaGasto = freezed,Object? observaciones = freezed,Object? usuarioId = freezed,}) {
  return _then(_GastoRequest(
descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,monto: null == monto ? _self.monto : monto // ignore: cast_nullable_to_non_nullable
as num,categoria: freezed == categoria ? _self.categoria : categoria // ignore: cast_nullable_to_non_nullable
as String?,metodoPago: freezed == metodoPago ? _self.metodoPago : metodoPago // ignore: cast_nullable_to_non_nullable
as String?,numeroComprobante: freezed == numeroComprobante ? _self.numeroComprobante : numeroComprobante // ignore: cast_nullable_to_non_nullable
as String?,fechaGasto: freezed == fechaGasto ? _self.fechaGasto : fechaGasto // ignore: cast_nullable_to_non_nullable
as DateTime?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,usuarioId: freezed == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
