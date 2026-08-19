import '../../core/errors/failure.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/commercial_repositories.dart';
import '../../domain/repositories/offline_repository.dart';
import 'adapters/sale_offline_adapter.dart' as adapter;

class OfflineVentaRepository implements VentaRepository {
  OfflineVentaRepository({
    required VentaRepository remote,
    required OfflineQueue queue,
    required OfflineCache<Venta> cache,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;
  final VentaRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<Venta> _cache;
  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) async {
    try {
      final List<Venta> result = await _remote.list(
        desde: desde,
        hasta: hasta,
        estado: estado,
        clienteId: clienteId,
      );
      await _cache.replace(result);
      return result;
    } on NetworkFailure {
      return _cache.read();
    }
  }

  @override
  Future<Venta> getById(int id) => _remote.getById(id);
  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) =>
      _remote.reportePorFecha(desde, hasta);
  @override
  Future<Venta> create(VentaRequest request) async {
    try {
      final Venta result = await _remote.create(request);
      return result;
    } on NetworkFailure {
      await _queue.enqueue(adapter.toOperation(request));
      return _local(request);
    }
  }

  @override
  Future<void> anular(int id) async {
    try {
      await _remote.anular(id);
    } on NetworkFailure {
      await _queue.enqueue(adapter.voidOperation(id, 0));
    }
  }

  Venta _local(VentaRequest request) => Venta(
    id: -DateTime.now().microsecondsSinceEpoch,
    numeroFactura: request.numeroFactura,
    clienteId: request.clienteId,
    subtotal: request.subtotal,
    descuento: request.descuento,
    iva: request.iva,
    total: request.total,
    metodoPago: request.metodoPago,
    estado: request.estado,
    observaciones: request.observaciones,
    usuarioId: request.usuarioId,
    detalles: request.detalles,
  );
}
