import '../../../domain/models/commercial_models.dart';
import '../../../domain/models/offline_models.dart';
import 'commercial_offline_adapter.dart';

Map<String, Object?> toCacheJson(Compra value) => value.toJson();
Compra fromCacheJson(Map<String, Object?> json) => Compra.fromJson(json);
PendingOperation toOperation(CompraRequest request) => buildOperation(
  type: OfflineOperationType.purchase,
  endpoint: '/api/compras',
  method: 'POST',
  userId: requireUserId(request.usuarioId),
  payload: request.toJson(),
);
PendingOperation updateOperation(int id, CompraRequest request) =>
    buildOperation(
      type: OfflineOperationType.purchase,
      endpoint: '/api/compras/$id',
      method: 'PUT',
      userId: requireUserId(request.usuarioId),
      payload: request.toJson(),
      localRecordKey: id.toString(),
    );
PendingOperation voidOperation(int id, int userId) => buildOperation(
  type: OfflineOperationType.purchaseVoid,
  endpoint: '/api/compras/$id/anular',
  method: 'PUT',
  userId: userId,
  payload: <String, Object?>{'id': id, 'usuarioId': userId},
  localRecordKey: id.toString(),
);
