import '../../../domain/models/commercial_models.dart';
import '../../../domain/models/offline_models.dart';
import 'commercial_offline_adapter.dart';

Map<String, Object?> toCacheJson(MovimientoStock value) => value.toJson();
MovimientoStock fromCacheJson(Map<String, Object?> json) =>
    MovimientoStock.fromJson(json);
PendingOperation toOperation(MovimientoStockRequest request) => buildOperation(
  type: OfflineOperationType.movement,
  endpoint: '/api/movimientos-stock',
  method: 'POST',
  userId: requireUserId(request.usuarioId),
  payload: request.toJson(),
);
