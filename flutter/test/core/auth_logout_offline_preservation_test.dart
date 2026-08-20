import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/data/local/app_database.dart';
import 'package:ferreplus/data/local/daos/cached_sales_dao.dart';
import 'package:ferreplus/data/local/daos/pending_operations_dao.dart';
import 'package:ferreplus/data/repositories/auth_repository_impl.dart';
import 'package:ferreplus/data/services/token_storage.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/models/offline_models.dart' as domain;

void main() {
  test('logout conserva la cola offline y la cache comercial', () async {
    final AppDatabase database = AppDatabase.memory();
    addTearDown(database.close);

    final PendingOperationsDao pendingOperations = PendingOperationsDao(
      database,
    );
    final CachedSalesDao salesCache = CachedSalesDao(database);
    await pendingOperations.enqueue(
      domain.PendingOperation(
        operationType: domain.OfflineOperationType.sale,
        endpoint: '/api/ventas',
        httpMethod: 'POST',
        userId: 7,
        idempotencyKey: 'logout-preservation-operation',
        payload: <String, Object?>{'total': 125.50},
        createdAt: DateTime(2026, 8, 19),
      ),
    );
    const Venta cachedSale = Venta(
      id: 42,
      subtotal: 100,
      descuento: 0,
      iva: 25.50,
      total: 125.50,
      estado: 'PENDIENTE',
    );
    await salesCache.replace(<Venta>[cachedSale]);

    final FakeTokenStorage storage = FakeTokenStorage();
    final AuthRepositoryImpl repository = AuthRepositoryImpl(
      dio: Dio(),
      storage: storage,
    );

    await repository.logout();

    expect(storage.clearCalls, 1);
    expect(await pendingOperations.countAll(7), 1);
    expect((await pendingOperations.nextBatch()).single.idempotencyKey,
        'logout-preservation-operation');
    expect((await salesCache.read()).single.id, 42);
    expect((await salesCache.read()).single.total, 125.50);
  });
}

class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage() : super(const FlutterSecureStorage());

  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
  }
}
