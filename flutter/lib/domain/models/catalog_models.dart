import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

@freezed
abstract class Categoria with _$Categoria {
  const factory Categoria({
    required int id,
    required String nombre,
    String? descripcion,
    DateTime? fechaCreacion,
  }) = _Categoria;
  factory Categoria.fromJson(Map<String, Object?> json) =>
      _$CategoriaFromJson(json);
}

@freezed
abstract class Proveedor with _$Proveedor {
  const factory Proveedor({
    required int id,
    required String nombre,
    String? ruc,
    String? contacto,
    String? telefono,
    String? email,
    String? direccion,
    @Default(true) bool activo,
    DateTime? fechaCreacion,
  }) = _Proveedor;
  factory Proveedor.fromJson(Map<String, Object?> json) =>
      _$ProveedorFromJson(json);
}

@freezed
abstract class Cliente with _$Cliente {
  const factory Cliente({
    required int id,
    required String nombre,
    String? ruc,
    String? telefono,
    String? email,
    String? direccion,
    @Default(0) double saldoPendiente,
    @Default(true) bool activo,
    DateTime? fechaCreacion,
  }) = _Cliente;
  factory Cliente.fromJson(Map<String, Object?> json) =>
      _$ClienteFromJson(json);
}

@freezed
abstract class Producto with _$Producto {
  const factory Producto({
    required int id,
    required String nombre,
    String? descripcion,
    String? codigoBarras,
    String? ubicacion,
    @Default(0) int stockActual,
    int? stockMinimo,
    int? stockMaximo,
    @Default(0) double precioCompra,
    @Default(0) double precioVenta,
    String? unidadMedida,
    String? imagen,
    Categoria? categoria,
    Proveedor? proveedor,
    @Default(true) bool activo,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) = _Producto;
  factory Producto.fromJson(Map<String, Object?> json) =>
      _$ProductoFromJson(json);
}
