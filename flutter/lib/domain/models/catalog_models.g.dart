// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Categoria _$CategoriaFromJson(Map<String, dynamic> json) => _Categoria(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$CategoriaToJson(_Categoria instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'descripcion': instance.descripcion,
      'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
    };

_Proveedor _$ProveedorFromJson(Map<String, dynamic> json) => _Proveedor(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  ruc: json['ruc'] as String?,
  contacto: json['contacto'] as String?,
  telefono: json['telefono'] as String?,
  email: json['email'] as String?,
  direccion: json['direccion'] as String?,
  activo: json['activo'] as bool? ?? true,
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$ProveedorToJson(_Proveedor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'ruc': instance.ruc,
      'contacto': instance.contacto,
      'telefono': instance.telefono,
      'email': instance.email,
      'direccion': instance.direccion,
      'activo': instance.activo,
      'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
    };

_Cliente _$ClienteFromJson(Map<String, dynamic> json) => _Cliente(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  ruc: json['ruc'] as String?,
  telefono: json['telefono'] as String?,
  email: json['email'] as String?,
  direccion: json['direccion'] as String?,
  saldoPendiente: (json['saldoPendiente'] as num?)?.toDouble() ?? 0,
  activo: json['activo'] as bool? ?? true,
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
);

Map<String, dynamic> _$ClienteToJson(_Cliente instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'ruc': instance.ruc,
  'telefono': instance.telefono,
  'email': instance.email,
  'direccion': instance.direccion,
  'saldoPendiente': instance.saldoPendiente,
  'activo': instance.activo,
  'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
};

_Producto _$ProductoFromJson(Map<String, dynamic> json) => _Producto(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  descripcion: json['descripcion'] as String?,
  codigoBarras: json['codigoBarras'] as String?,
  ubicacion: json['ubicacion'] as String?,
  stockActual: (json['stockActual'] as num?)?.toInt() ?? 0,
  stockMinimo: (json['stockMinimo'] as num?)?.toInt(),
  stockMaximo: (json['stockMaximo'] as num?)?.toInt(),
  precioCompra: (json['precioCompra'] as num?)?.toDouble() ?? 0,
  precioVenta: (json['precioVenta'] as num?)?.toDouble() ?? 0,
  unidadMedida: json['unidadMedida'] as String?,
  imagen: json['imagen'] as String?,
  categoria: json['categoria'] == null
      ? null
      : Categoria.fromJson(json['categoria'] as Map<String, dynamic>),
  proveedor: json['proveedor'] == null
      ? null
      : Proveedor.fromJson(json['proveedor'] as Map<String, dynamic>),
  activo: json['activo'] as bool? ?? true,
  fechaCreacion: json['fechaCreacion'] == null
      ? null
      : DateTime.parse(json['fechaCreacion'] as String),
  fechaActualizacion: json['fechaActualizacion'] == null
      ? null
      : DateTime.parse(json['fechaActualizacion'] as String),
);

Map<String, dynamic> _$ProductoToJson(_Producto instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'descripcion': instance.descripcion,
  'codigoBarras': instance.codigoBarras,
  'ubicacion': instance.ubicacion,
  'stockActual': instance.stockActual,
  'stockMinimo': instance.stockMinimo,
  'stockMaximo': instance.stockMaximo,
  'precioCompra': instance.precioCompra,
  'precioVenta': instance.precioVenta,
  'unidadMedida': instance.unidadMedida,
  'imagen': instance.imagen,
  'categoria': instance.categoria,
  'proveedor': instance.proveedor,
  'activo': instance.activo,
  'fechaCreacion': instance.fechaCreacion?.toIso8601String(),
  'fechaActualizacion': instance.fechaActualizacion?.toIso8601String(),
};
