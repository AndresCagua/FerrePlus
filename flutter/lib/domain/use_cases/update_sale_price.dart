import '../models/admin_models.dart';
import '../repositories/admin_repositories.dart';

class UpdateSalePrice {
  const UpdateSalePrice(this.repository);
  final PrecioRepository repository;
  Future<void> byPrice(int id, double price, {String? reference}) =>
      repository.actualizarVenta(
        id,
        ActualizarPrecioVentaRequest(nuevoPrecio: price, referencia: reference),
      );
  Future<void> byMargin(int id, double margin, {String? reference}) =>
      repository.actualizarVenta(
        id,
        ActualizarPrecioVentaRequest(
          margenPorcentaje: margin,
          referencia: reference,
        ),
      );
}
