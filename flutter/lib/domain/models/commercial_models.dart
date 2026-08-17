// ignore_for_file: constant_identifier_names
import 'package:freezed_annotation/freezed_annotation.dart';

part 'commercial_models.freezed.dart';
part 'commercial_models.g.dart';

enum StockMovementType { ENTRADA, SALIDA, AJUSTE, unknown }

enum CommercialStatus { COMPLETADA, ANULADA, PENDIENTE, unknown }

@freezed
abstract class DetalleVenta with _$DetalleVenta {
  const factory DetalleVenta({
    int? id,
    int? productoId,
    String? productoNombre,
    required int cantidad,
    required num precioUnitario,
    num? subtotal,
  }) = _DetalleVenta;
  factory DetalleVenta.fromJson(Map<String, Object?> json) =>
      _$DetalleVentaFromJson(json);
}

@freezed
abstract class Venta with _$Venta {
  const factory Venta({
    required int id,
    String? numeroFactura,
    int? clienteId,
    String? clienteNombre,
    required num subtotal,
    required num descuento,
    required num iva,
    required num total,
    String? metodoPago,
    String? estado,
    String? observaciones,
    int? usuarioId,
    DateTime? fechaCreacion,
    DateTime? fechaAnulacion,
    @Default(<DetalleVenta>[]) List<DetalleVenta> detalles,
  }) = _Venta;
  factory Venta.fromJson(Map<String, Object?> json) => _$VentaFromJson(json);
}

@freezed
abstract class VentaRequest with _$VentaRequest {
  const factory VentaRequest({
    String? numeroFactura,
    int? clienteId,
    required num subtotal,
    required num descuento,
    required num iva,
    required num total,
    String? metodoPago,
    String? estado,
    String? observaciones,
    required List<DetalleVenta> detalles,
  }) = _VentaRequest;
  factory VentaRequest.fromJson(Map<String, Object?> json) =>
      _$VentaRequestFromJson(json);
}

@freezed
abstract class DetalleCompra with _$DetalleCompra {
  const factory DetalleCompra({
    int? id,
    int? productoId,
    String? productoNombre,
    required int cantidad,
    required num precioUnitario,
    num? subtotal,
  }) = _DetalleCompra;
  factory DetalleCompra.fromJson(Map<String, Object?> json) =>
      _$DetalleCompraFromJson(json);
}

@freezed
abstract class Compra with _$Compra {
  const factory Compra({
    required int id,
    required String numeroFactura,
    int? proveedorId,
    String? proveedorNombre,
    required num subtotal,
    required num descuento,
    required num iva,
    required num total,
    String? estado,
    String? observaciones,
    DateTime? fechaFactura,
    int? usuarioId,
    DateTime? fechaCreacion,
    @Default(<DetalleCompra>[]) List<DetalleCompra> detalles,
  }) = _Compra;
  factory Compra.fromJson(Map<String, Object?> json) => _$CompraFromJson(json);
}

@freezed
abstract class CompraRequest with _$CompraRequest {
  const factory CompraRequest({
    required String numeroFactura,
    int? proveedorId,
    required num subtotal,
    required num descuento,
    required num iva,
    required num total,
    String? estado,
    String? observaciones,
    DateTime? fechaFactura,
    required List<DetalleCompra> detalles,
  }) = _CompraRequest;
  factory CompraRequest.fromJson(Map<String, Object?> json) =>
      _$CompraRequestFromJson(json);
}

@freezed
abstract class MovimientoStock with _$MovimientoStock {
  const factory MovimientoStock({
    required int id,
    int? productoId,
    String? productoNombre,
    required int cantidad,
    required String tipo,
    String? referencia,
    String? motivo,
    num? precioUnitario,
    int? stockAnterior,
    int? stockPosterior,
    int? usuarioId,
    String? usuarioNombre,
    DateTime? fecha,
  }) = _MovimientoStock;
  factory MovimientoStock.fromJson(Map<String, Object?> json) =>
      _$MovimientoStockFromJson(json);
}

@freezed
abstract class MovimientoStockRequest with _$MovimientoStockRequest {
  const factory MovimientoStockRequest({
    required int productoId,
    required int cantidad,
    required String tipo,
    String? referencia,
    String? motivo,
    num? precioUnitario,
  }) = _MovimientoStockRequest;
  factory MovimientoStockRequest.fromJson(Map<String, Object?> json) =>
      _$MovimientoStockRequestFromJson(json);
}

@freezed
abstract class Gasto with _$Gasto {
  const factory Gasto({
    required int id,
    required String descripcion,
    required num monto,
    String? categoria,
    String? metodoPago,
    String? numeroComprobante,
    DateTime? fechaGasto,
    String? observaciones,
    int? usuarioId,
    DateTime? fechaCreacion,
  }) = _Gasto;
  factory Gasto.fromJson(Map<String, Object?> json) => _$GastoFromJson(json);
}

@freezed
abstract class GastoRequest with _$GastoRequest {
  const factory GastoRequest({
    required String descripcion,
    required num monto,
    String? categoria,
    String? metodoPago,
    String? numeroComprobante,
    DateTime? fechaGasto,
    String? observaciones,
  }) = _GastoRequest;
  factory GastoRequest.fromJson(Map<String, Object?> json) =>
      _$GastoRequestFromJson(json);
}

String dateOnly(DateTime value) => value.toIso8601String().substring(0, 10);

Map<String, Object?> detailPayload(
  int? productoId,
  int cantidad,
  num precioUnitario,
  num subtotal,
) => <String, Object?>{
  'productoId': productoId,
  'cantidad': cantidad,
  'precioUnitario': precioUnitario,
  'subtotal': subtotal,
};
