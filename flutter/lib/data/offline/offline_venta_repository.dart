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
      final Venta local = _local(request);
      final operation = adapter
          .toOperation(request)
          .copyWith(localRecordKey: local.id.toString());
      await _queue.enqueue(operation);
      await _cacheOptimistically(local, operation.idempotencyKey);
      return local;
    }
  }

  @override
  Future<void> anular(int id) async {
    try {
      await _remote.anular(id);
    } on NetworkFailure {
      final List<Venta> cached = await _cache.read();
      final Iterable<Venta> matches = cached.where(
        (Venta value) => value.id == id,
      );
      final Venta? current = matches.isEmpty ? null : matches.first;
      final operation = adapter.voidOperation(id, current?.usuarioId ?? 0);
      await _queue.enqueue(operation);
      if (current != null) {
        await _cacheOptimistically(
          current.copyWith(estado: 'ANULADA'),
          operation.idempotencyKey,
        );
      }
    }
  }

  Future<void> _cacheOptimistically(Venta value, String key) async {
    final OfflineCache<Venta> cache = _cache;
    if (cache case final OptimisticOfflineCache<Venta> optimistic) {
      await optimistic.upsertOptimistic(value, idempotencyKey: key);
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
