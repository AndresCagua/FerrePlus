import 'package:drift/drift.dart';

@TableIndex(
  name: 'pending_user_status_created',
  columns: {#userId, #status, #createdAt},
)
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text().named('operation_type')();
  TextColumn get endpoint => text()();
  TextColumn get httpMethod => text().named('http_method')();
  IntColumn get userId => integer().named('user_id')();
  TextColumn get idempotencyKey => text().named('idempotency_key').unique()();
  TextColumn get payloadJson => text().named('payload_json')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount =>
      integer().named('attempt_count').withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt =>
      dateTime().named('next_retry_at').nullable()();
  TextColumn get lastError => text().named('last_error').nullable()();
  TextColumn get responseJson => text().named('response_json').nullable()();
  TextColumn get localRecordKey =>
      text().named('local_record_key').nullable()();
}

abstract class CachedCommercialTable extends Table {
  TextColumn get localKey => text().named('local_key')();
  IntColumn get serverId => integer().named('server_id').nullable()();
  TextColumn get payloadJson => text().named('payload_json')();
  DateTimeColumn get serverUpdatedAt =>
      dateTime().named('server_updated_at').nullable()();
  DateTimeColumn get localUpdatedAt => dateTime().named('local_updated_at')();
  TextColumn get syncState =>
      text().named('sync_state').withDefault(const Constant('synced'))();
  TextColumn get idempotencyKey => text().named('idempotency_key').nullable()();
  @override
  Set<Column<Object>> get primaryKey => {localKey};
}

class CachedSales extends CachedCommercialTable {}

class CachedExpenses extends CachedCommercialTable {}

class CachedPurchases extends CachedCommercialTable {}

class CachedMovements extends CachedCommercialTable {}
