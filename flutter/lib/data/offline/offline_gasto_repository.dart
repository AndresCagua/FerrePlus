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
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;
  final GastoRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<Gasto> _cache;
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
      final Gasto local = Gasto(
        id: -DateTime.now().microsecondsSinceEpoch,
        descripcion: r.descripcion,
        monto: r.monto,
        categoria: r.categoria,
        metodoPago: r.metodoPago,
        numeroComprobante: r.numeroComprobante,
        fechaGasto: r.fechaGasto,
        observaciones: r.observaciones,
        usuarioId: r.usuarioId,
      );
      final operation = adapter
          .toOperation(r)
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
      final Gasto local = Gasto(
        id: id,
        descripcion: r.descripcion,
        monto: r.monto,
        categoria: r.categoria,
        metodoPago: r.metodoPago,
        numeroComprobante: r.numeroComprobante,
        fechaGasto: r.fechaGasto,
        observaciones: r.observaciones,
        usuarioId: r.usuarioId,
      );
      final operation = adapter
          .toOperation(r)
          .copyWith(localRecordKey: id.toString());
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
}
