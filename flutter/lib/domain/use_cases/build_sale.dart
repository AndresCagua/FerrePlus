// ignore_for_file: curly_braces_in_flow_control_structures
import '../models/commercial_models.dart';

class BuildSale {
  const BuildSale({this.ivaRate = 0.15});
  final num ivaRate;

  VentaRequest call({
    required List<DetalleVenta> detalles,
    int? clienteId,
    num descuento = 0,
    String? metodoPago,
    String? observaciones,
    String? numeroFactura,
    Map<int, int>? stockByProduct,
  }) {
    if (detalles.isEmpty)
      throw ArgumentError('Debe agregar al menos un detalle.');
    for (final DetalleVenta detail in detalles) {
      if (detail.productoId == null ||
          detail.cantidad <= 0 ||
          detail.precioUnitario < 0) {
        throw ArgumentError(
          'Cada detalle debe tener producto, cantidad positiva y precio valido.',
        );
      }
      final int? stock = stockByProduct?[detail.productoId];
      if (stock != null && detail.cantidad > stock)
        throw ArgumentError(
          'Stock insuficiente para ${detail.productoNombre ?? 'el producto'}.',
        );
    }
    final num subtotal = detalles.fold<num>(
      0,
      (num total, DetalleVenta item) =>
          total + item.cantidad * item.precioUnitario,
    );
    final num taxable = subtotal - descuento;
    final num iva = taxable * ivaRate;
    return VentaRequest(
      clienteId: clienteId,
      numeroFactura: numeroFactura,
      subtotal: subtotal,
      descuento: descuento,
      iva: iva,
      total: taxable + iva,
      metodoPago: metodoPago,
      observaciones: observaciones,
      detalles: detalles,
    );
  }
}
