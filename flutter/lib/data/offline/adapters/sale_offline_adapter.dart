import '../../../domain/models/commercial_models.dart';
import '../../../domain/models/offline_models.dart';
import 'commercial_offline_adapter.dart';

Map<String, Object?> toCacheJson(Venta sale) => sale.toJson();
Venta fromCacheJson(Map<String, Object?> json) => Venta.fromJson(json);
Map<String, Object?> salePayload(VentaRequest request) => request.toJson();
PendingOperation toOperation(VentaRequest request) => buildOperation(
  type: OfflineOperationType.sale,
  endpoint: '/api/ventas',
  method: 'POST',
  userId: requireUserId(request.usuarioId),
  payload: salePayload(request),
);
PendingOperation voidOperation(int id, int userId) => buildOperation(
  type: OfflineOperationType.saleVoid,
  endpoint: '/api/ventas/$id/anular',
  method: 'PUT',
  userId: userId,
  payload: <String, Object?>{'id': id, 'usuarioId': userId},
  localRecordKey: id.toString(),
);
