import '../models/commercial_models.dart';

abstract class VentaRepository {
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  });
  Future<Venta> getById(int id);
  Future<Venta> create(VentaRequest request);
  Future<void> anular(int id);
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta);
}

abstract class CompraRepository {
  Future<List<Compra>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? proveedorId,
  });
  Future<Compra> getById(int id);
  Future<Compra> create(CompraRequest request);
  Future<Compra> update(int id, CompraRequest request);
  Future<void> anular(int id);
  Future<List<Compra>> reportePorFecha(DateTime desde, DateTime hasta);
}

abstract class MovimientoRepository {
  Future<List<MovimientoStock>> list({
    int? productoId,
    String? tipo,
    DateTime? desde,
    DateTime? hasta,
  });
  Future<MovimientoStock> create(MovimientoStockRequest request);
}

abstract class GastoRepository {
  Future<List<Gasto>> list();
  Future<Gasto> getById(int id);
  Future<Gasto> create(GastoRequest request);
  Future<Gasto> update(int id, GastoRequest request);
  Future<void> delete(int id);
}
