import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

import 'package:ferreplus/core/errors/failure.dart';
import 'package:ferreplus/data/offline/adapters/sale_offline_adapter.dart'
    as sale_adapter;
import 'package:ferreplus/data/local/app_database.dart' as local_db;
import 'package:ferreplus/data/local/daos/pending_operations_dao.dart';
import 'package:ferreplus/data/offline/offline_venta_repository.dart';
import 'package:ferreplus/data/services/sync_engine.dart';
import 'package:ferreplus/data/services/sync_notification_service.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';
import 'package:ferreplus/domain/models/offline_models.dart';
import 'package:ferreplus/domain/repositories/offline_repository.dart';
import 'package:ferreplus/domain/repositories/commercial_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sender respeta endpoint persistido para updates y creates', () async {
    final Dio dio = Dio();
    final List<String> paths = <String>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          paths.add(options.path);
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: <String, Object?>{'ok': true},
            ),
          );
        },
      ),
    );
    final DioPendingOperationSender sender = DioPendingOperationSender(
      dio: dio,
    );
    await sender.send(
      PendingOperationEnvelope(
        _operation(
          id: 1,
          userId: 7,
          endpoint: '/api/compras/42',
          method: 'PUT',
        ),
      ),
    );
    await sender.send(
      PendingOperationEnvelope(
        _operation(id: 2, userId: 7, endpoint: '/api/compras'),
      ),
    );
    expect(paths, <String>['/api/compras/42', '/api/compras']);
  });

  test('anulacion sin cache usa usuario activo y se sincroniza', () async {
    final FakeQueue queue = FakeQueue(<PendingOperation>[]);
    final OfflineVentaRepository repository = OfflineVentaRepository(
      remote: OfflineVentaRemote(),
      queue: queue,
      cache: EmptyVentaCache(),
      currentUserId: () => 7,
    );

    await repository.anular(42);

    final PendingOperation queued = queue.operation(1);
    expect(queued.userId, 7);
    expect(queued.userId, isNot(0));

    final List<int> sentIds = <int>[];
    final SyncEngine engine = _engine(
      queue: queue,
      activeUserId: 7,
      sender: (PendingOperationEnvelope envelope) async {
        sentIds.add(envelope.operation.userId);
        return <String, Object?>{};
      },
    );

    await engine.syncNow();

    expect(sentIds, <int>[7]);
    expect(queue.operation(1).status, PendingOperationStatus.completed);
  });

  test(
    'sincroniza exclusivamente las operaciones del usuario activo',
    () async {
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        _operation(id: 1, userId: 10),
        _operation(id: 2, userId: 20),
      ]);
      final List<int> sentIds = <int>[];
      final SyncEngine engine = _engine(
        queue: queue,
        activeUserId: 10,
        sender: (PendingOperationEnvelope envelope) async {
          sentIds.add(envelope.operation.id!);
          return <String, Object?>{};
        },
      );

      await engine.syncNow();

      expect(sentIds, <int>[1]);
      expect(queue.operation(2).status, PendingOperationStatus.pending);
    },
  );

  test(
    'resumeAfterLogin reactiva y sincroniza solo al usuario autenticado',
    () async {
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        _operation(
          id: 1,
          userId: 10,
          status: PendingOperationStatus.authRequired,
        ),
        _operation(
          id: 2,
          userId: 20,
          status: PendingOperationStatus.authRequired,
        ),
      ]);
      final List<int> sentIds = <int>[];
      final SyncEngine engine = _engine(
        queue: queue,
        sender: (PendingOperationEnvelope envelope) async {
          sentIds.add(envelope.operation.id!);
          return <String, Object?>{};
        },
      );

      await engine.resumeAfterLogin(userId: 10);

      expect(queue.resetUserIds, <int>[10]);
      expect(sentIds, <int>[1]);
      expect(queue.operation(2).status, PendingOperationStatus.authRequired);
    },
  );

  test(
    'anulacion de venta limpia cache aunque la respuesta no tenga id',
    () async {
      final PendingOperation operation = sale_adapter.voidOperation(42, 10);
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        operation.copyWith(id: 1),
      ]);
      final FakeCache cache = FakeCache();
      final SyncEngine engine = _engine(
        queue: queue,
        activeUserId: 10,
        cache: cache,
        sender: (_) async => <String, Object?>{},
      );

      await engine.syncNow();

      expect(operation.localRecordKey, '42');
      expect(cache.synchronizedWithoutServerIdKeys, <String>['42']);
      expect(cache.syncState, 'synced');
      expect(cache.idempotencyKey, isNull);
    },
  );

  test('no refresca cache si la sesion cambia durante el envio', () async {
    final FakeQueue queue = FakeQueue(<PendingOperation>[
      _operation(id: 1, userId: 10),
    ]);
    final FakeCache cache = FakeCache();
    late SyncEngine engine;
    engine = _engine(
      queue: queue,
      activeUserId: 10,
      cache: cache,
      sender: (_) async {
        engine.setActiveUserId(20);
        return <String, Object?>{'id': 42};
      },
    );

    await engine.syncNow();

    expect(cache.synchronizedKeys, isEmpty);
    expect(queue.operation(1).status, PendingOperationStatus.completed);
  });

  test(
    'no envia el batch cargado si la sesion cambia antes del envio',
    () async {
      final FakeQueue queue = FakeQueue(<PendingOperation>[
        _operation(id: 1, userId: 10),
      ]);
      late SyncEngine engine;
      queue.beforeNextBatchForUser = () async => engine.setActiveUserId(20);
      final List<int> sentIds = <int>[];
      engine = _engine(
        queue: queue,
        activeUserId: 10,
        sender: (PendingOperationEnvelope envelope) async {
          sentIds.add(envelope.operation.id!);
          return <String, Object?>{};
        },
      );

      await engine.syncNow();

      expect(sentIds, isEmpty);
      expect(queue.operation(1).status, PendingOperationStatus.pending);
    },
  );

  test(
    'recupera una operacion syncing y la procesa despues de un crash',
    () async {
      const MethodChannel storageChannel = MethodChannel(
        'plugins.it_nomads.com/flutter_secure_storage',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(storageChannel, (_) async => null);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(storageChannel, null),
      );
      final local_db.AppDatabase database = local_db.AppDatabase.memory();
      addTearDown(database.close);
      final PendingOperationsDao queue = PendingOperationsDao(database);
      final int operationId = await database
          .into(database.pendingOperations)
          .insert(
            local_db.PendingOperationsCompanion.insert(
              operationType: OfflineOperationType.sale.value,
              endpoint: '/api/ventas',
              httpMethod: 'POST',
              userId: 10,
              idempotencyKey: 'key-1',
              payloadJson: '{"id":1}',
              createdAt: DateTime(2026, 1, 1),
            ),
          );
      await queue.markSyncing(operationId);

      final List<int> sentIds = <int>[];
      final SyncEngine engine = _engine(
        queue: queue,
        activeUserId: 10,
        sender: (PendingOperationEnvelope envelope) async {
          sentIds.add(envelope.operation.id!);
          return <String, Object?>{};
        },
      );

      final List<PendingOperation> recovered = await queue.nextBatchForUser(10);
      expect(recovered.single.status, PendingOperationStatus.syncing);
      await engine.syncNow();

      expect(sentIds, <int>[operationId]);
      expect((await queue.nextBatchForUser(10)), isEmpty);
    },
  );
}

SyncEngine _engine({
  required OfflineQueue queue,
  required PendingOperationSender sender,
  int? activeUserId,
  FakeCache? cache,
}) => SyncEngine(
  queue: queue,
  sender: DioPendingOperationSender(send: sender),
  notifications: SyncNotificationService(),
  activeUserId: activeUserId,
  caches: cache == null
      ? null
      : <OfflineOperationType, SynchronizableOfflineCache>{
          OfflineOperationType.sale: cache,
        },
);

PendingOperation _operation({
  required int id,
  required int userId,
  String endpoint = '/api/ventas',
  String method = 'POST',
  PendingOperationStatus status = PendingOperationStatus.pending,
}) => PendingOperation(
  id: id,
  operationType: OfflineOperationType.sale,
  endpoint: endpoint,
  httpMethod: method,
  userId: userId,
  idempotencyKey: 'key-$id',
  payload: <String, Object?>{'id': id},
  createdAt: DateTime(2026, 1, id),
  status: status,
);

class FakeQueue
    implements OfflineQueue, UserScopedOfflineQueue, AuthResumableOfflineQueue {
  FakeQueue(List<PendingOperation> operations)
    : _operations = <int, PendingOperation>{
        for (final PendingOperation operation in operations)
          operation.id!: operation,
      };

  final Map<int, PendingOperation> _operations;
  final List<int> resetUserIds = <int>[];
  Future<void> Function()? beforeNextBatchForUser;

  PendingOperation operation(int id) => _operations[id]!;

  @override
  Future<void> enqueue(PendingOperation operation) async {
    final int id = operation.id ?? (_operations.length + 1);
    _operations[id] = operation.copyWith(id: id);
  }

  @override
  Future<void> cancelByLocalRecordKey(String localRecordKey) async {
    _operations.removeWhere(
      (_, PendingOperation operation) =>
          operation.localRecordKey == localRecordKey,
    );
  }

  @override
  Stream<int> watchPendingCount(int userId) => const Stream<int>.empty();

  @override
  Future<List<PendingOperation>> nextBatch({required int limit}) async =>
      _pending(limit: limit);

  @override
  Future<List<PendingOperation>> nextBatchForUser(
    int userId, {
    int limit = 10,
  }) async {
    await beforeNextBatchForUser?.call();
    return _pending(limit: limit, userId: userId);
  }

  List<PendingOperation> _pending({required int limit, int? userId}) =>
      _operations.values
          .where(
            (PendingOperation operation) =>
                operation.status == PendingOperationStatus.pending &&
                (userId == null || operation.userId == userId),
          )
          .take(limit)
          .toList();

  @override
  Future<void> markSyncing(int id) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.syncing,
    );
  }

  @override
  Future<void> markCompleted(int id, Map<String, Object?> response) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.completed,
      response: response,
    );
  }

  @override
  Future<void> markAuthRequired(int id) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.authRequired,
    );
  }

  @override
  Future<void> markFailed(int id, String sanitizedError) async {
    _operations[id] = _operations[id]!.copyWith(
      status: PendingOperationStatus.failed,
      lastError: sanitizedError,
    );
  }

  @override
  Future<void> cleanupCompleted({
    Duration olderThan = const Duration(days: 7),
  }) async {}

  @override
  Future<int> countAll(int userId) async => _operations.values
      .where((PendingOperation item) => item.userId == userId)
      .length;

  @override
  Future<int> totalPayloadSize(int userId) async => 0;

  @override
  Future<void> resetAuthRequiredToPending({int? userId}) async {
    if (userId != null) resetUserIds.add(userId);
    for (final MapEntry<int, PendingOperation> entry in _operations.entries) {
      final PendingOperation operation = entry.value;
      if (operation.status == PendingOperationStatus.authRequired &&
          operation.userId == userId) {
        _operations[entry.key] = operation.copyWith(
          status: PendingOperationStatus.pending,
        );
      }
    }
  }
}

class FakeCache
    implements SynchronizableOfflineCache, EmptyResponseOfflineCache {
  final List<String> synchronizedWithoutServerIdKeys = <String>[];
  final List<String> synchronizedKeys = <String>[];
  String syncState = 'pending';
  String? idempotencyKey = 'local-key';

  @override
  Future<void> markSynchronized({
    required String localRecordKey,
    required int serverId,
    required DateTime serverUpdatedAt,
    required Map<String, Object?> response,
  }) async {
    synchronizedKeys.add(localRecordKey);
    syncState = 'synced';
    idempotencyKey = null;
  }

  @override
  Future<void> markSynchronizedWithoutServerId({
    required String localRecordKey,
  }) async {
    synchronizedWithoutServerIdKeys.add(localRecordKey);
    syncState = 'synced';
    idempotencyKey = null;
  }
}

class EmptyVentaCache implements OfflineCache<Venta> {
  @override
  Future<List<Venta>> read() async => <Venta>[];

  @override
  Future<void> replace(List<Venta> values) async {}
}

class OfflineVentaRemote implements VentaRepository {
  @override
  Future<void> anular(int id) async {
    throw const NetworkFailure('offline');
  }

  @override
  Future<Venta> create(VentaRequest request) => throw UnimplementedError();

  @override
  Future<Venta> getById(int id) => throw UnimplementedError();

  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) => throw UnimplementedError();

  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) =>
      throw UnimplementedError();
}
