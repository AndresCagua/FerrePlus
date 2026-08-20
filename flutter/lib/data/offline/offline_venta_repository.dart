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
    int? Function()? currentUserId,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache,
       _currentUserId = currentUserId;
  final VentaRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<Venta> _cache;
  final int? Function()? _currentUserId;
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
      final VentaRequest offlineRequest = _requestWithSessionUser(request);
      final Venta local = _local(offlineRequest);
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
      final List<Venta> cached = await _cache.read();
      final Iterable<Venta> matches = cached.where(
        (Venta value) => value.id == id,
      );
      final Venta? current = matches.isEmpty ? null : matches.first;
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

  int _requireCurrentUserId(Venta? cachedSale) {
    final int? userId = cachedSale?.usuarioId ?? _currentUserId?.call();
    if (userId == null) {
      throw StateError('No hay una sesion activa para encolar la anulacion.');
    }
    return userId;
  }

  VentaRequest _requestWithSessionUser(VentaRequest request) {
    if (request.usuarioId != null) return request;
    final int? userId = _currentUserId?.call();
    if (userId == null) {
      throw StateError('No hay una sesion activa para encolar la operacion.');
    }
    return request.copyWith(usuarioId: userId);
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
