import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ferreplus/data/repositories/commercial_repositories_impl.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';

class MockCommercialDio extends Mock implements Dio {}

Response<Object?> _response(Object? data) => Response<Object?>(
  requestOptions: RequestOptions(path: '/api/test'),
  statusCode: 200,
  data: data,
);

void main() {
  late MockCommercialDio dio;
  setUp(() {
    dio = MockCommercialDio();
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((invocation) async {
      final String path = invocation.positionalArguments.first as String;
      final Map<String, Object?> item = <String, Object?>{
        'id': 1,
        'numeroFactura': 'F-1',
        'subtotal': 10,
        'descuento': 0,
        'iva': 1.5,
        'total': 11.5,
        'estado': 'COMPLETADA',
      };
      return _response(
        path.endsWith('/1') ? item : <Map<String, Object?>>[item],
      );
    });
    when(() => dio.post<Object?>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => _response(<String, Object?>{
        'id': 1,
        'subtotal': 10,
        'descuento': 0,
        'iva': 1.5,
        'total': 11.5,
      }),
    );
    when(() => dio.put<Object?>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => _response(<String, Object?>{
        'id': 1,
        'subtotal': 10,
        'descuento': 0,
        'iva': 1.5,
        'total': 11.5,
      }),
    );
    when(
      () => dio.put<Object?>(any()),
    ).thenAnswer((_) async => _response(null));
    when(
      () => dio.delete<Object?>(any()),
    ).thenAnswer((_) async => _response(null));
  });

  test('ventas ejecuta filtros, detalle, crear, anular y reporte', () async {
    final VentaRepositoryImpl repository = VentaRepositoryImpl(dio);
    await repository.list(
      desde: DateTime(2026, 1, 1),
      estado: 'COMPLETADA',
      clienteId: 4,
    );
    await repository.getById(1);
    await repository.create(
      const VentaRequest(
        subtotal: 10,
        descuento: 0,
        iva: 1.5,
        total: 11.5,
        detalles: <DetalleVenta>[],
      ),
    );
    await repository.anular(1);
    await repository.reportePorFecha(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 31),
    );
    verify(
      () => dio.get<Object?>(
        '/api/ventas',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).called(1);
    verify(
      () => dio.post<Object?>('/api/ventas', data: any(named: 'data')),
    ).called(1);
    verify(() => dio.put<Object?>('/api/ventas/1/anular')).called(1);
    verify(
      () => dio.get<Object?>(
        '/api/ventas/reportes/por-fecha',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).called(1);
  });

  test('compras, movimientos y gastos ejecutan sus operaciones', () async {
    final CompraRepositoryImpl purchases = CompraRepositoryImpl(dio);
    await purchases.list(estado: 'PENDIENTE');
    await purchases.create(
      const CompraRequest(
        numeroFactura: 'F-1',
        subtotal: 10,
        descuento: 0,
        iva: 1.5,
        total: 11.5,
        detalles: <DetalleCompra>[],
      ),
    );
    await purchases.update(
      1,
      const CompraRequest(
        numeroFactura: 'F-1',
        subtotal: 10,
        descuento: 0,
        iva: 1.5,
        total: 11.5,
        detalles: <DetalleCompra>[],
      ),
    );
    await purchases.anular(1);
    await MovimientoRepositoryImpl(dio).list(tipo: 'ENTRADA', productoId: 2);
    await MovimientoRepositoryImpl(dio).create(
      const MovimientoStockRequest(productoId: 2, cantidad: 1, tipo: 'AJUSTE'),
    );
    final GastoRepositoryImpl expenses = GastoRepositoryImpl(dio);
    await expenses.create(const GastoRequest(descripcion: 'Luz', monto: 10));
    await expenses.update(1, const GastoRequest(descripcion: 'Luz', monto: 10));
    await expenses.delete(1);
    verify(() => dio.put<Object?>('/api/compras/1/anular')).called(1);
    verify(
      () =>
          dio.post<Object?>('/api/movimientos-stock', data: any(named: 'data')),
    ).called(1);
    verify(() => dio.delete<Object?>('/api/gastos/1')).called(1);
  });

  test('request payload models include usuarioId when authenticated', () {
    const int usuarioId = 42;
    final Map<String, Object?> sale = const VentaRequest(
      subtotal: 10,
      descuento: 0,
      iva: 1.5,
      total: 11.5,
      detalles: <DetalleVenta>[],
      usuarioId: usuarioId,
    ).toJson();
    final Map<String, Object?> purchase = const CompraRequest(
      numeroFactura: 'F-1',
      subtotal: 10,
      descuento: 0,
      iva: 1.5,
      total: 11.5,
      detalles: <DetalleCompra>[],
      usuarioId: usuarioId,
    ).toJson();
    final Map<String, Object?> movement = const MovimientoStockRequest(
      productoId: 2,
      cantidad: 1,
      tipo: 'AJUSTE',
      usuarioId: usuarioId,
    ).toJson();
    final Map<String, Object?> expense = const GastoRequest(
      descripcion: 'Luz',
      monto: 10,
      usuarioId: usuarioId,
    ).toJson();

    expect(sale['usuarioId'], usuarioId);
    expect(purchase['usuarioId'], usuarioId);
    expect(movement['usuarioId'], usuarioId);
    expect(expense['usuarioId'], usuarioId);
  });
}
