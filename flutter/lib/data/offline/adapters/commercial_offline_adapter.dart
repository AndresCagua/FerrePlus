import 'package:uuid/uuid.dart';

import '../../../domain/models/offline_models.dart';

int requireUserId(int? userId) {
  if (userId == null) {
    throw StateError('No hay una sesion activa para encolar la operacion.');
  }
  return userId;
}

PendingOperation buildOperation({
  required OfflineOperationType type,
  required String endpoint,
  required String method,
  required int userId,
  required Map<String, Object?> payload,
  String? localRecordKey,
}) => PendingOperation(
  operationType: type,
  endpoint: endpoint,
  httpMethod: method,
  userId: userId,
  idempotencyKey: const Uuid().v4(),
  payload: payload,
  createdAt: DateTime.now(),
  localRecordKey: localRecordKey,
);
