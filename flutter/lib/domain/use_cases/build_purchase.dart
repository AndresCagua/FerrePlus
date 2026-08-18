// ignore_for_file: curly_braces_in_flow_control_structures
import '../models/commercial_models.dart';

class BuildPurchase {
  const BuildPurchase({this.ivaRate = 0.15});
  final num ivaRate;

  CompraRequest call({
    required String numeroFactura,
    required List<DetalleCompra> detalles,
    int? proveedorId,
    num descuento = 0,
    DateTime? fechaFactura,
    String? estado,
    String? observaciones,
    int? usuarioId,
  }) {
    if (numeroFactura.trim().isEmpty || detalles.isEmpty)
      throw ArgumentError('Factura y al menos un detalle son obligatorios.');
    for (final DetalleCompra detail in detalles) {
      if (detail.productoId == null ||
          detail.cantidad <= 0 ||
          detail.precioUnitario < 0)
        throw ArgumentError('Detalle de compra invalido.');
    }
    final num subtotal = detalles.fold<num>(
      0,
      (num total, DetalleCompra item) =>
          total + item.cantidad * item.precioUnitario,
    );
    final num iva = (subtotal - descuento) * ivaRate;
    return CompraRequest(
      numeroFactura: numeroFactura.trim(),
      proveedorId: proveedorId,
      subtotal: subtotal,
      descuento: descuento,
      iva: iva,
      total: subtotal - descuento + iva,
      fechaFactura: fechaFactura,
      estado: estado,
      observaciones: observaciones,
      usuarioId: usuarioId,
      detalles: detalles,
    );
  }
}
