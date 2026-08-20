import '../../core/errors/failure.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/commercial_repositories.dart';
import '../../domain/repositories/offline_repository.dart';
import 'adapters/expense_offline_adapter.dart' as adapter;

class OfflineGastoRepository implements GastoRepository {
  OfflineGastoRepository({
    required GastoRepository remote,
    required OfflineQueue queue,
    required OfflineCache<Gasto> cache,
    int? Function()? currentUserId,
  }) : _remote = remote,
       _queue = queue,
       _cache = cache,
       _currentUserId = currentUserId;
  final GastoRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<Gasto> _cache;
  final int? Function()? _currentUserId;
  @override
  Future<List<Gasto>> list() async {
    try {
      final List<Gasto> r = await _remote.list();
      await _cache.replace(r);
      return r;
    } on NetworkFailure {
      return _cache.read();
    }
  }

  @override
  Future<Gasto> getById(int id) => _remote.getById(id);
  @override
  Future<Gasto> create(GastoRequest r) async {
    try {
      return await _remote.create(r);
    } on NetworkFailure {
      final GastoRequest offlineRequest = _requestWithSessionUser(r);
      final Gasto local = Gasto(
        id: -DateTime.now().microsecondsSinceEpoch,
        descripcion: offlineRequest.descripcion,
        monto: offlineRequest.monto,
        categoria: offlineRequest.categoria,
        metodoPago: offlineRequest.metodoPago,
        numeroComprobante: offlineRequest.numeroComprobante,
        fechaGasto: offlineRequest.fechaGasto,
        observaciones: offlineRequest.observaciones,
        usuarioId: offlineRequest.usuarioId,
      );
      final operation = adapter
          .toOperation(offlineRequest)
          .copyWith(localRecordKey: local.id.toString());
      await _queue.enqueue(operation);
      if (_cache case final OptimisticOfflineCache<Gasto> optimistic) {
        await optimistic.upsertOptimistic(
          local,
          idempotencyKey: operation.idempotencyKey,
        );
      }
      return local;
    }
  }

  @override
  Future<Gasto> update(int id, GastoRequest r) async {
    try {
      return await _remote.update(id, r);
    } on NetworkFailure {
      final GastoRequest offlineRequest = _requestWithSessionUser(r);
      final Gasto local = Gasto(
        id: id,
        descripcion: offlineRequest.descripcion,
        monto: offlineRequest.monto,
        categoria: offlineRequest.categoria,
        metodoPago: offlineRequest.metodoPago,
        numeroComprobante: offlineRequest.numeroComprobante,
        fechaGasto: offlineRequest.fechaGasto,
        observaciones: offlineRequest.observaciones,
        usuarioId: offlineRequest.usuarioId,
      );
      final operation = adapter.updateOperation(id, offlineRequest);
      await _queue.enqueue(operation);
      if (_cache case final OptimisticOfflineCache<Gasto> optimistic) {
        await optimistic.upsertOptimistic(
          local,
          idempotencyKey: operation.idempotencyKey,
        );
      }
      return local;
    }
  }

  @override
  Future<void> delete(int id) => _remote.delete(id);

  GastoRequest _requestWithSessionUser(GastoRequest request) {
    if (request.usuarioId != null) return request;
    final int? userId = _currentUserId?.call();
    if (userId == null) {
      throw StateError('No hay una sesion activa para encolar la operacion.');
    }
    return request.copyWith(usuarioId: userId);
  }
}
