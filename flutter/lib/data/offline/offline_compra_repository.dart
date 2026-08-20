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
    int? Function()? currentUserId,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache,
       _currentUserId = currentUserId;
  final CompraRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<Compra> _cache;
  final int? Function()? _currentUserId;
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
      final CompraRequest offlineRequest = _requestWithSessionUser(request);
      final Compra local = _local(offlineRequest);
      final operation = adapter
          .toOperation(offlineRequest)
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
      final CompraRequest offlineRequest = _requestWithSessionUser(request);
      final Compra local = _local(offlineRequest, id: id);
      final operation = adapter
          .toOperation(offlineRequest)
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
      final operation = adapter.voidOperation(
        id,
        _requireCurrentUserId(current),
      );
      await _queue.enqueue(operation);
      if (current != null) {
        await _cacheOptimistically(
          current.copyWith(estado: 'ANULADA'),
          operation.idempotencyKey,
        );
      }
    }
  }

  int _requireCurrentUserId(Compra? cachedPurchase) {
    final int? userId = cachedPurchase?.usuarioId ?? _currentUserId?.call();
    if (userId == null) {
      throw StateError('No hay una sesion activa para encolar la anulacion.');
    }
    return userId;
  }

  CompraRequest _requestWithSessionUser(CompraRequest request) {
    if (request.usuarioId != null) return request;
    final int? userId = _currentUserId?.call();
    if (userId == null) {
      throw StateError('No hay una sesion activa para encolar la operacion.');
    }
    return request.copyWith(usuarioId: userId);
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
