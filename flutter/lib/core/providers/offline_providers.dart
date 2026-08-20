import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/daos/pending_operations_dao.dart';
import '../../data/local/daos/cached_sales_dao.dart';
import '../../data/local/daos/cached_purchases_dao.dart';
import '../../data/local/daos/cached_expenses_dao.dart';
import '../../data/local/daos/cached_movements_dao.dart';
import '../../data/offline/payload_codec.dart';
import '../../domain/models/commercial_models.dart';
import '../../data/services/connectivity_monitor.dart';
import '../../data/services/sync_engine.dart';
import '../../data/services/sync_notification_service.dart';
import '../../data/services/offline_coordinator.dart';
import '../../data/services/api_client.dart';
import '../../domain/repositories/offline_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final AppDatabase database = AppDatabase.persistent();
  ref.onDispose(database.close);
  return database;
});

final pendingOperationsDaoProvider = Provider<PendingOperationsDao>(
  (ref) => PendingOperationsDao(
    ref.watch(appDatabaseProvider),
    codec: ref.watch(payloadCodecProvider),
  ),
);

final payloadCodecProvider = Provider<PayloadCodec>((ref) => PayloadCodec());

final offlineQueueProvider = Provider<OfflineQueue>(
  (ref) => ref.watch(pendingOperationsDaoProvider) as OfflineQueue,
);
final salesCacheProvider = Provider<OfflineCache<Venta>>(
  (ref) => CachedSalesDao(
    ref.watch(appDatabaseProvider),
    codec: ref.watch(payloadCodecProvider),
  ),
);
final purchasesCacheProvider = Provider<OfflineCache<Compra>>(
  (ref) => CachedPurchasesDao(
    ref.watch(appDatabaseProvider),
    codec: ref.watch(payloadCodecProvider),
  ),
);
final expensesCacheProvider = Provider<OfflineCache<Gasto>>(
  (ref) => CachedExpensesDao(
    ref.watch(appDatabaseProvider),
    codec: ref.watch(payloadCodecProvider),
  ),
);
final movementsCacheProvider = Provider<OfflineCache<MovimientoStock>>(
  (ref) => CachedMovementsDao(
    ref.watch(appDatabaseProvider),
    codec: ref.watch(payloadCodecProvider),
  ),
);

final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  final ConnectivityMonitor monitor = ConnectivityMonitorImpl();
  ref.onDispose(monitor.dispose);
  return monitor;
});

final syncNotificationServiceProvider = Provider<SyncNotificationService>((
  ref,
) {
  final SyncNotificationService service = SyncNotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    queue: ref.watch(offlineQueueProvider),
    sender: ref.watch(offlineSenderProvider),
    notifications: ref.watch(syncNotificationServiceProvider),
  ),
);

final offlineCoordinatorProvider = Provider<OfflineCoordinator>((ref) {
  final OfflineCoordinator coordinator = OfflineCoordinator(
    monitor: ref.watch(connectivityMonitorProvider),
    engine: ref.watch(syncEngineProvider),
    notifications: ref.watch(syncNotificationServiceProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final offlineSyncEnabledProvider = Provider<bool>((ref) => true);

final offlineSenderProvider = Provider<DioPendingOperationSender>(
  (ref) => DioPendingOperationSender(dioReader: () => ApiClient.current!.dio),
);
