import '../../../domain/models/commercial_models.dart';
import '../../../domain/models/offline_models.dart';
import 'commercial_offline_adapter.dart';

Map<String, Object?> toCacheJson(Gasto value) => value.toJson();
Gasto fromCacheJson(Map<String, Object?> json) => Gasto.fromJson(json);
PendingOperation toOperation(GastoRequest request) => buildOperation(
  type: OfflineOperationType.expense,
  endpoint: '/api/gastos',
  method: 'POST',
  userId: request.usuarioId ?? 0,
  payload: request.toJson(),
);
