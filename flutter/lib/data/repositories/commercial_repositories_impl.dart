import 'package:dio/dio.dart';

import '../../core/constants/api_paths.dart';
import '../../core/errors/failure_mapper.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/commercial_repositories.dart';

Map<String, Object?> _map(Object? value) =>
    Map<String, Object?>.from(value! as Map<Object?, Object?>);
List<Map<String, Object?>> _list(Object? value) =>
    (value! as List<Object?>).map(_map).toList(growable: false);

Map<String, Object?> _sale(Map<String, Object?> json) {
  final Map<String, Object?> result = Map<String, Object?>.from(json);
  final Object? client = result['cliente'];
  if (client is Map<Object?, Object?>) {
    final Map<String, Object?> nested = _map(client);
    result['clienteId'] ??= nested['id'];
    result['clienteNombre'] ??= nested['nombre'];
  }
  result['subtotal'] ??= 0;
  result['descuento'] ??= 0;
  result['iva'] ??= 0;
  result['total'] ??= 0;
  result['numeroFactura'] ??= '';
  return result;
}

Map<String, Object?> _purchase(Map<String, Object?> json) {
  final Map<String, Object?> result = Map<String, Object?>.from(json);
  final Object? supplier = result['proveedor'];
  if (supplier is Map<Object?, Object?>) {
    final Map<String, Object?> nested = _map(supplier);
    result['proveedorId'] ??= nested['id'];
    result['proveedorNombre'] ??= nested['nombre'];
  }
  result['subtotal'] ??= 0;
  result['descuento'] ??= 0;
  result['iva'] ??= 0;
  result['total'] ??= 0;
  result['numeroFactura'] ??= '';
  return result;
}

Venta _decodeSale(Map<String, Object?> json) => Venta.fromJson(_sale(json));
Compra _decodePurchase(Map<String, Object?> json) =>
    Compra.fromJson(_purchase(json));
MovimientoStock _decodeMovement(Map<String, Object?> json) =>
    MovimientoStock.fromJson(_movement(json));

class VentaRepositoryImpl implements VentaRepository {
  VentaRepositoryImpl(this.dio);
  final Dio dio;

  @override
  Future<List<Venta>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? clienteId,
  }) async => _runList(
    dio,
    ApiPaths.ventas,
    _decodeSale,
    query: _dateAndStatusQuery(desde, hasta, estado, clienteId, 'clienteId'),
  );

  @override
  Future<Venta> getById(int id) async =>
      _runOne(dio, '${ApiPaths.ventas}/$id', _decodeSale);

  @override
  Future<Venta> create(VentaRequest request) async =>
      _runCreate(dio, ApiPaths.ventas, _saleRequest(request), _decodeSale);

  @override
  Future<void> anular(int id) async {
    try {
      await dio.put<Object?>('${ApiPaths.ventas}/$id/anular');
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<List<Venta>> reportePorFecha(DateTime desde, DateTime hasta) async =>
      _runList(
        dio,
        ApiPaths.ventasReporte,
        _decodeSale,
        query: <String, Object?>{
          'desde': dateOnly(desde),
          'hasta': dateOnly(hasta),
        },
      );
}

class CompraRepositoryImpl implements CompraRepository {
  CompraRepositoryImpl(this.dio);
  final Dio dio;
  @override
  Future<List<Compra>> list({
    DateTime? desde,
    DateTime? hasta,
    String? estado,
    int? proveedorId,
  }) async => _runList(
    dio,
    ApiPaths.compras,
    _decodePurchase,
    query: _dateAndStatusQuery(
      desde,
      hasta,
      estado,
      proveedorId,
      'proveedorId',
    ),
  );
  @override
  Future<Compra> getById(int id) async =>
      _runOne(dio, '${ApiPaths.compras}/$id', _decodePurchase);
  @override
  Future<Compra> create(CompraRequest request) async => _runCreate(
    dio,
    ApiPaths.compras,
    _purchaseRequest(request),
    _decodePurchase,
  );
  @override
  Future<Compra> update(int id, CompraRequest request) async => _runCreate(
    dio,
    '${ApiPaths.compras}/$id',
    _purchaseRequest(request),
    _decodePurchase,
    put: true,
  );
  @override
  Future<void> anular(int id) async {
    try {
      await dio.put<Object?>('${ApiPaths.compras}/$id/anular');
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<List<Compra>> reportePorFecha(DateTime desde, DateTime hasta) async =>
      _runList(
        dio,
        ApiPaths.comprasReporte,
        _decodePurchase,
        query: <String, Object?>{
          'desde': dateOnly(desde),
          'hasta': dateOnly(hasta),
        },
      );
}

class MovimientoRepositoryImpl implements MovimientoRepository {
  MovimientoRepositoryImpl(this.dio);
  final Dio dio;
  @override
  Future<List<MovimientoStock>> list({
    int? productoId,
    String? tipo,
    DateTime? desde,
    DateTime? hasta,
  }) async => _runList(
    dio,
    ApiPaths.movimientosStock,
    _decodeMovement,
    query: <String, Object?>{
      'productoId': productoId,
      'tipo': tipo,
      'desde': desde == null ? null : dateOnly(desde),
      'hasta': hasta == null ? null : dateOnly(hasta),
    }..removeWhere((String key, Object? value) => value == null),
  );
  @override
  Future<MovimientoStock> create(MovimientoStockRequest request) async =>
      _runCreate(dio, ApiPaths.movimientosStock, <String, Object?>{
        'productoId': request.productoId,
        'cantidad': request.cantidad,
        'tipo': request.tipo,
        'referencia': request.referencia,
        'motivo': request.motivo,
        'precioUnitario': request.precioUnitario,
      }, _decodeMovement);
}

class GastoRepositoryImpl implements GastoRepository {
  GastoRepositoryImpl(this.dio);
  final Dio dio;
  @override
  Future<List<Gasto>> list() async =>
      _runList(dio, ApiPaths.gastos, _decodeExpense);
  @override
  Future<Gasto> getById(int id) async =>
      _runOne(dio, '${ApiPaths.gastos}/$id', _decodeExpense);
  @override
  Future<Gasto> create(GastoRequest request) async => _runCreate(
    dio,
    ApiPaths.gastos,
    _expenseRequest(request),
    _decodeExpense,
  );
  @override
  Future<Gasto> update(int id, GastoRequest request) async => _runCreate(
    dio,
    '${ApiPaths.gastos}/$id',
    _expenseRequest(request),
    _decodeExpense,
    put: true,
  );
  @override
  Future<void> delete(int id) async {
    try {
      await dio.delete<Object?>('${ApiPaths.gastos}/$id');
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}

Map<String, Object?> _saleRequest(VentaRequest request) => <String, Object?>{
  'numeroFactura': request.numeroFactura,
  'clienteId': request.clienteId,
  'subtotal': request.subtotal,
  'descuento': request.descuento,
  'iva': request.iva,
  'total': request.total,
  'metodoPago': request.metodoPago,
  'estado': request.estado,
  'observaciones': request.observaciones,
  'detalles': request.detalles
      .map(
        (DetalleVenta item) => detailPayload(
          item.productoId,
          item.cantidad,
          item.precioUnitario,
          item.subtotal ?? item.cantidad * item.precioUnitario,
        ),
      )
      .toList(growable: false),
};
Map<String, Object?> _purchaseRequest(CompraRequest request) =>
    <String, Object?>{
      'numeroFactura': request.numeroFactura,
      'proveedorId': request.proveedorId,
      'subtotal': request.subtotal,
      'descuento': request.descuento,
      'iva': request.iva,
      'total': request.total,
      'estado': request.estado,
      'observaciones': request.observaciones,
      'fechaFactura': request.fechaFactura == null
          ? null
          : dateOnly(request.fechaFactura!),
      'detalles': request.detalles
          .map(
            (DetalleCompra item) => detailPayload(
              item.productoId,
              item.cantidad,
              item.precioUnitario,
              item.subtotal ?? item.cantidad * item.precioUnitario,
            ),
          )
          .toList(growable: false),
    };
Map<String, Object?> _expenseRequest(GastoRequest request) => <String, Object?>{
  'descripcion': request.descripcion,
  'monto': request.monto,
  'categoria': request.categoria,
  'metodoPago': request.metodoPago,
  'numeroComprobante': request.numeroComprobante,
  'fechaGasto': request.fechaGasto == null
      ? null
      : dateOnly(request.fechaGasto!),
  'observaciones': request.observaciones,
};

Map<String, Object?> _dateAndStatusQuery(
  DateTime? desde,
  DateTime? hasta,
  String? estado,
  int? relationId,
  String relationKey,
) => <String, Object?>{
  'desde': desde == null ? null : dateOnly(desde),
  'hasta': hasta == null ? null : dateOnly(hasta),
  'estado': estado,
  relationKey: relationId,
}..removeWhere((String key, Object? value) => value == null);
Map<String, Object?> _movement(Map<String, Object?> json) {
  final Map<String, Object?> result = Map<String, Object?>.from(json);
  final Object? product = result['producto'];
  if (product is Map<Object?, Object?>) {
    final Map<String, Object?> nested = _map(product);
    result['productoId'] ??= nested['id'];
    result['productoNombre'] ??= nested['nombre'];
  }
  result['cantidad'] ??= 0;
  result['tipo'] ??= 'unknown';
  return result;
}

Gasto _decodeExpense(Map<String, Object?> json) {
  final Map<String, Object?> result = Map<String, Object?>.from(json);
  result['descripcion'] ??= '';
  result['monto'] ??= 0;
  result['id'] ??= 0;
  return Gasto.fromJson(result);
}

Future<List<T>> _runList<T>(
  Dio dio,
  String path,
  T Function(Map<String, Object?>) decode, {
  Map<String, Object?>? query,
}) async {
  try {
    final Response<Object?> response = await dio.get<Object?>(
      path,
      queryParameters: query,
    );
    return _list(response.data).map(decode).toList(growable: false);
  } on DioException catch (error) {
    throw mapDioFailure(error);
  }
}

Future<T> _runOne<T>(
  Dio dio,
  String path,
  T Function(Map<String, Object?>) normalize,
) async {
  try {
    final Response<Object?> response = await dio.get<Object?>(path);
    return normalize(_map(response.data));
  } on DioException catch (error) {
    throw mapDioFailure(error);
  }
}

Future<T> _runCreate<T>(
  Dio dio,
  String path,
  Map<String, Object?> body,
  T Function(Map<String, Object?>) normalize, {
  bool put = false,
}) async {
  try {
    final Response<Object?> response = put
        ? await dio.put<Object?>(path, data: body)
        : await dio.post<Object?>(path, data: body);
    return normalize(_map(response.data));
  } on DioException catch (error) {
    throw mapDioFailure(error);
  }
}
