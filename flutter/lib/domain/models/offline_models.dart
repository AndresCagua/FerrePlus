import 'dart:convert';

enum OfflineOperationType {
  sale,
  expense,
  purchase,
  movement,
  saleVoid,
  purchaseVoid,
}

enum PendingOperationStatus {
  pending,
  syncing,
  completed,
  authRequired,
  failed,
}

extension OfflineOperationTypeCodec on OfflineOperationType {
  String get value => switch (this) {
    OfflineOperationType.sale => 'sale',
    OfflineOperationType.expense => 'expense',
    OfflineOperationType.purchase => 'purchase',
    OfflineOperationType.movement => 'movement',
    OfflineOperationType.saleVoid => 'sale_void',
    OfflineOperationType.purchaseVoid => 'purchase_void',
  };

  static OfflineOperationType parse(String value) => OfflineOperationType.values
      .firstWhere((OfflineOperationType item) => item.value == value);
}

extension PendingOperationStatusCodec on PendingOperationStatus {
  String get value => switch (this) {
    PendingOperationStatus.pending => 'pending',
    PendingOperationStatus.syncing => 'syncing',
    PendingOperationStatus.completed => 'completed',
    PendingOperationStatus.authRequired => 'auth_required',
    PendingOperationStatus.failed => 'failed',
  };

  static PendingOperationStatus parse(String value) => PendingOperationStatus
      .values
      .firstWhere((PendingOperationStatus item) => item.value == value);
}

class PendingOperation {
  const PendingOperation({
    this.id,
    required this.operationType,
    required this.endpoint,
    required this.httpMethod,
    required this.userId,
    required this.idempotencyKey,
    required this.payload,
    required this.createdAt,
    this.status = PendingOperationStatus.pending,
    this.attemptCount = 0,
    this.nextRetryAt,
    this.lastError,
    this.response,
    this.localRecordKey,
  });

  final int? id;
  final OfflineOperationType operationType;
  final String endpoint;
  final String httpMethod;
  final int userId;
  final String idempotencyKey;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final PendingOperationStatus status;
  final int attemptCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final Map<String, Object?>? response;
  final String? localRecordKey;

  String get payloadJson => jsonEncode(payload);

  PendingOperation copyWith({
    int? id,
    String? localRecordKey,
    PendingOperationStatus? status,
    int? attemptCount,
    DateTime? nextRetryAt,
    String? lastError,
    Map<String, Object?>? response,
  }) => PendingOperation(
    id: id ?? this.id,
    operationType: operationType,
    endpoint: endpoint,
    httpMethod: httpMethod,
    userId: userId,
    idempotencyKey: idempotencyKey,
    payload: payload,
    createdAt: createdAt,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    lastError: lastError ?? this.lastError,
    response: response ?? this.response,
    localRecordKey: localRecordKey ?? this.localRecordKey,
  );
}

class OfflineList<T> {
  const OfflineList({required this.items, required this.fromCache});
  final List<T> items;
  final bool fromCache;
}

class OfflineSyncResult {
  const OfflineSyncResult({
    this.completed = 0,
    this.failed = 0,
    this.authRequired = false,
  });
  final int completed;
  final int failed;
  final bool authRequired;
}
