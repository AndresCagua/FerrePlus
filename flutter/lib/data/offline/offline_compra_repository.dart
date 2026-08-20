import '../../core/errors/failure.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/commercial_repositories.dart';
import '../../domain/repositories/offline_repository.dart';
import 'adapters/purchase_offline_adapter.dart' as adapter;

class OfflineCompraRepository implements CompraRepository {
  OfflineCompraRepository({
    required CompraRepository remote,
    required OfflineQueue queue,
    required OfflineCache<Compra> cache,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;
  final CompraRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<Compra> _cache;
  @override
  Future<List<Compra>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? proveedorId,
  }) async {
    try {
      final List<Compra> r = await _remote.list(
        desde: desde,
        hasta: hasta,
        estado: estado,
        proveedorId: proveedorId,
      );
      await _cache.replace(r);
      return r;
    } on NetworkFailure {
      return _cache.read();
    }
  }

  @override
  Future<Compra> getById(int id) => _remote.getById(id);
  @override
  Future<List<Compra>> reportePorFecha(DateTime desde, DateTime hasta) =>
      _remote.reportePorFecha(desde, hasta);
  @override
  Future<Compra> create(CompraRequest request) async {
    try {
      return await _remote.create(request);
    } on NetworkFailure {
      final Compra local = _local(request);
      final operation = adapter
          .toOperation(request)
          .copyWith(localRecordKey: local.id.toString());
      await _queue.enqueue(operation);
      await _cacheOptimistically(local, operation.idempotencyKey);
      return local;
    }
  }

  @override
  Future<Compra> update(int id, CompraRequest request) async {
    try {
      return await _remote.update(id, request);
    } on NetworkFailure {
      final Compra local = _local(request, id: id);
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
      final List<Compra> cached = await _cache.read();
      final Iterable<Compra> matches = cached.where(
        (Compra value) => value.id == id,
      );
      final Compra? current = matches.isEmpty ? null : matches.first;
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

  Future<void> _cacheOptimistically(Compra value, String key) async {
    if (_cache case final OptimisticOfflineCache<Compra> optimistic) {
      await optimistic.upsertOptimistic(value, idempotencyKey: key);
    }
  }

  Compra _local(CompraRequest r, {int id = -1}) => Compra(
    id: id == -1 ? -DateTime.now().microsecondsSinceEpoch : id,
    numeroFactura: r.numeroFactura,
    proveedorId: r.proveedorId,
    subtotal: r.subtotal,
    descuento: r.descuento,
    iva: r.iva,
    total: r.total,
    estado: r.estado,
    observaciones: r.observaciones,
    fechaFactura: r.fechaFactura,
    usuarioId: r.usuarioId,
    detalles: r.detalles,
  );
}
