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
  }) : _remote = remote,
       _queue = queue,
       _cache = cache;
  final MovimientoRepository _remote;
  final OfflineQueue _queue;
  final OfflineCache<MovimientoStock> _cache;
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
      await _queue.enqueue(adapter.toOperation(r));
      return MovimientoStock(
        id: -DateTime.now().microsecondsSinceEpoch,
        productoId: r.productoId,
        cantidad: r.cantidad,
        tipo: r.tipo,
        referencia: r.referencia,
        motivo: r.motivo,
        precioUnitario: r.precioUnitario,
        usuarioId: r.usuarioId,
      );
    }
  }
}
