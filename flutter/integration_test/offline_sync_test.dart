import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/data/local/app_database.dart';
import 'package:ferreplus/data/local/daos/pending_operations_dao.dart';
import 'package:ferreplus/domain/models/offline_models.dart' as domain;

void main() {
  testWidgets('offline sale remains queued until authentication is restored', (
    WidgetTester tester,
  ) async {
    final AppDatabase database = AppDatabase.memory();
    addTearDown(database.close);
    final PendingOperationsDao queue = PendingOperationsDao(database);
    final DateTime createdAt = DateTime(2026, 1, 1);

    await queue.enqueue(
      domain.PendingOperation(
        operationType: domain.OfflineOperationType.sale,
        endpoint: '/api/ventas',
        httpMethod: 'POST',
        userId: 7,
        idempotencyKey: 'sale-local-1',
        payload: const <String, Object?>{'total': 115.0},
        createdAt: createdAt,
      ),
    );

    final List<domain.PendingOperation> pending = await queue.nextBatch();
    expect(pending, hasLength(1));
    expect(pending.single.endpoint, '/api/ventas');
    expect(pending.single.status, domain.PendingOperationStatus.pending);

    await queue.markAuthRequired(pending.single.id!);
    final int total = await queue.countAll(7);
    expect(total, 1);
  });
}
