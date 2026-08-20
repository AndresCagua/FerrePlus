import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/core/errors/failure.dart';
import 'package:ferreplus/data/offline/offline_compra_repository.dart';
import 'package:ferreplus/data/offline/offline_gasto_repository.dart';
import 'package:ferreplus/data/offline/offline_venta_repository.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/models/offline_models.dart';
import 'package:ferreplus/domain/repositories/commercial_repositories.dart';
import 'package:ferreplus/domain/repositories/offline_repository.dart';

void main() {
  test(
    'update offline de compra y gasto encola PUT sobre el recurso',
    () async {
      final _QueueFake queue = _QueueFake();
      final CompraRequest purchaseRequest = _purchaseRequest();
      final GastoRequest expenseRequest = _expenseRequest();

      await OfflineCompraRepository(
        remote: _FailingCompraRepository(),
        queue: queue,
        cache: _CacheFake<Compra>(),
        currentUserId: () => 7,
      ).update(42, purchaseRequest);
      await OfflineGastoRepository(
        remote: _FailingGastoRepository(),
        queue: queue,
        cache: _CacheFake<Gasto>(),
        currentUserId: () => 7,
      ).update(43, expenseRequest);

      expect(
        queue.operations.map(
          (PendingOperation operation) => operation.endpoint,
        ),
        <String>['/api/compras/42', '/api/gastos/43'],
      );
      expect(
        queue.operations.map(
          (PendingOperation operation) => operation.httpMethod,
        ),
        everyElement('PUT'),
      );
      expect(
        queue.operations.map(
          (PendingOperation operation) => operation.localRecordKey,
        ),
        <String>['42', '43'],
      );
    },
  );

  test(
    'anular venta offline pendiente solo cambia el cache y no encola id negativo',
    () async {
      final _QueueFake queue = _QueueFake();
      final _CacheFake<Venta> cache = _CacheFake<Venta>()
        ..values.add(_sale(-123));

      await OfflineVentaRepository(
        remote: _FailingVentaRepository(),
        queue: queue,
        cache: cache,
        currentUserId: () => 7,
      ).anular(-123);

      expect(queue.operations, isEmpty);
      expect(cache.values.single.estado, 'ANULADA');
    },
  );

  test('anular alta local elimina su POST pendiente', () async {
    final _QueueFake queue = _QueueFake();
    final _CacheFake<Venta> cache = _CacheFake<Venta>()
      ..values.add(_sale(-123));
    queue.operations.add(
      PendingOperation(
        operationType: OfflineOperationType.sale,
        endpoint: '/api/ventas',
        httpMethod: 'POST',
        userId: 7,
        idempotencyKey: 'sale-create',
        payload: <String, Object?>{},
        createdAt: DateTime(2026),
        localRecordKey: '-123',
      ),
    );

    await OfflineVentaRepository(
      remote: _FailingVentaRepository(),
      queue: queue,
      cache: cache,
      currentUserId: () => 7,
    ).anular(-123);

    expect(queue.operations, isEmpty);
    expect(cache.values.single.estado, 'ANULADA');
  });

  test(
    'anular compra offline pendiente tampoco envia el id provisional',
    () async {
      final _QueueFake queue = _QueueFake();
      final _CacheFake<Compra> cache = _CacheFake<Compra>()
        ..values.add(_purchase(-456));

      await OfflineCompraRepository(
        remote: _FailingCompraRepository(),
        queue: queue,
        cache: cache,
        currentUserId: () => 7,
      ).anular(-456);

      expect(queue.operations, isEmpty);
      expect(cache.values.single.estado, 'ANULADA');
    },
  );
}

class _QueueFake implements OfflineQueue {
  final List<PendingOperation> operations = <PendingOperation>[];

  @override
  Future<void> enqueue(PendingOperation operation) async =>
      operations.add(operation);
  @override
  Future<void> cancelByLocalRecordKey(String localRecordKey) async {
    operations.removeWhere(
      (PendingOperation operation) =>
          operation.localRecordKey == localRecordKey,
    );
  }

  @override
  Stream<int> watchPendingCount(int userId) => const Stream<int>.empty();
  @override
  Future<List<PendingOperation>> nextBatch({required int limit}) async =>
      operations;
  @override
  Future<void> markSyncing(int id) async {}
  @override
  Future<void> markCompleted(int id, Map<String, Object?> response) async {}
  @override
  Future<void> markAuthRequired(int id) async {}
  @override
  Future<void> markFailed(int id, String sanitizedError) async {}
  @override
  Future<void> cleanupCompleted({
    Duration olderThan = const Duration(days: 7),
  }) async {}
  @override
  Future<int> countAll(int userId) async => operations.length;
  @override
  Future<int> totalPayloadSize(int userId) async => 0;
}

class _CacheFake<T> implements OptimisticOfflineCache<T> {
  final List<T> values = <T>[];

  @override
  Future<void> replace(List<T> values) async {
    this.values
      ..clear()
      ..addAll(values);
  }

  @override
  Future<List<T>> read() async => values;
  @override
  Future<void> upsertOptimistic(T value, {String? idempotencyKey}) async {
    values
      ..removeWhere((T item) => _sameId(item, value))
      ..add(value);
  }
}

bool _sameId(Object? first, Object? second) => switch ((first, second)) {
  (Venta a, Venta b) => a.id == b.id,
  (Compra a, Compra b) => a.id == b.id,
  (Gasto a, Gasto b) => a.id == b.id,
  _ => false,
};

class _FailingVentaRepository implements VentaRepository {
  @override
  Future<void> anular(int id) => _fail();
  @override
  Future<Venta> create(VentaRequest request) => _fail();
  @override
  Future<Venta> getById(int id) => _fail();
  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) => _fail();
  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) =>
      _fail();
}

class _FailingCompraRepository implements CompraRepository {
  @override
  Future<void> anular(int id) => _fail();
  @override
  Future<Compra> create(CompraRequest request) => _fail();
  @override
  Future<Compra> getById(int id) => _fail();
  @override
  Future<List<Compra>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? proveedorId,
  }) => _fail();
  @override
  Future<List<Compra>> reportePorFecha(DateTime desde, DateTime hasta) =>
      _fail();
  @override
  Future<Compra> update(int id, CompraRequest request) => _fail();
}

class _FailingGastoRepository implements GastoRepository {
  @override
  Future<Gasto> create(GastoRequest request) => _fail();
  @override
  Future<void> delete(int id) => _fail();
  @override
  Future<Gasto> getById(int id) => _fail();
  @override
  Future<List<Gasto>> list() => _fail();
  @override
  Future<Gasto> update(int id, GastoRequest request) => _fail();
}

Future<T> _fail<T>() async => throw const NetworkFailure('offline');

CompraRequest _purchaseRequest() => const CompraRequest(
  numeroFactura: 'F-42',
  subtotal: 10,
  descuento: 0,
  iva: 1.6,
  total: 11.6,
  detalles: <DetalleCompra>[],
);

Compra _purchase(int id) => Compra(
  id: id,
  numeroFactura: 'F-$id',
  subtotal: 10,
  descuento: 0,
  iva: 1.6,
  total: 11.6,
  estado: 'PENDIENTE',
);

GastoRequest _expenseRequest() =>
    const GastoRequest(descripcion: 'Luz', monto: 10);

Venta _sale(int id) => Venta(
  id: id,
  subtotal: 10,
  descuento: 0,
  iva: 1.6,
  total: 11.6,
  estado: 'PENDIENTE',
);
