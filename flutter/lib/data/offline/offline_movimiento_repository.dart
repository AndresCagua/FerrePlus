import '../../core/errors/failure.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/commercial_repositories.dart';
import '../../domain/repositories/offline_repository.dart';
import 'adapters/movement_offline_adapter.dart' as adapter;

class OfflineMovimientoRepository implements MovimientoRepository {
  OfflineMovimientoRepository({
    required MovimientoRepository remote,
    required OfflineQueue queue,
    required OfflineCache<MovimientoStock> cache,
    int? Function()? currentUserId,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache,
       _currentUserId = currentUserId;
  final MovimientoRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<MovimientoStock> _cache;
  final int? Function()? _currentUserId;
  @override
  Future<List<MovimientoStock>> list({
    int? productoId,
    String? tipo,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    try {
      final List<MovimientoStock> r = await _remote.list(
        productoId: productoId,
        tipo: tipo,
        desde: desde,
        hasta: hasta,
      );
      await _cache.replace(r);
      return r;
    } on NetworkFailure {
      return _cache.read();
    }
  }

  @override
  Future<MovimientoStock> create(MovimientoStockRequest r) async {
    try {
      return await _remote.create(r);
    } on NetworkFailure {
      final MovimientoStockRequest offlineRequest = _requestWithSessionUser(r);
      final MovimientoStock local = MovimientoStock(
        id: -DateTime.now().microsecondsSinceEpoch,
        productoId: offlineRequest.productoId,
        cantidad: offlineRequest.cantidad,
        tipo: offlineRequest.tipo,
        referencia: offlineRequest.referencia,
        motivo: offlineRequest.motivo,
        precioUnitario: offlineRequest.precioUnitario,
        usuarioId: offlineRequest.usuarioId,
      );
      final operation = adapter
          .toOperation(offlineRequest)
          .copyWith(localRecordKey: local.id.toString());
      await _queue.enqueue(operation);
      if (_cache
          case final OptimisticOfflineCache<MovimientoStock> optimistic) {
        await optimistic.upsertOptimistic(
          local,
          idempotencyKey: operation.idempotencyKey,
        );
      }
      return local;
    }
  }

  MovimientoStockRequest _requestWithSessionUser(
    MovimientoStockRequest request,
  ) {
    if (request.usuarioId != null) return request;
    final int? userId = _currentUserId?.call();
    if (userId == null) {
      throw StateError('No hay una sesion activa para encolar la operacion.');
    }
    return request.copyWith(usuarioId: userId);
  }
}
