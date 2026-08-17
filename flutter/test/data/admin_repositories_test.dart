import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ferreplus/data/repositories/admin_repositories_impl.dart';
import 'package:ferreplus/domain/models/admin_models.dart';

class AdminDioMock extends Mock implements Dio {}

Response<Object?> adminResponse(Object? data) => Response<Object?>(
  requestOptions: RequestOptions(path: '/api/test'),
  statusCode: 200,
  data: data,
);

void main() {
  late AdminDioMock dio;

  setUp(() => dio = AdminDioMock());

  test('precios mapea historial y actualiza por margen', () async {
    when(() => dio.get<Object?>('/api/precios')).thenAnswer(
      (_) async => adminResponse(<Map<String, Object?>>[
        <String, Object?>{
          'id': 4,
          'nombre': 'Taladro',
          'precioCompra': 10,
          'precioVenta': 15,
          'ganancia': 5,
          'margenPorcentaje': 50,
        },
      ]),
    );
    when(() => dio.get<Object?>('/api/precios/4/historial')).thenAnswer(
      (_) async => adminResponse(<Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'productoId': 4,
          'precioCompra': 10,
          'precioVenta': 15,
          'fechaCambio': '2026-08-15T10:00:00',
          'referencia': 'lista agosto',
        },
      ]),
    );
    when(
      () => dio.put<Object?>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => adminResponse(null));

    final PrecioRepositoryImpl repository = PrecioRepositoryImpl(dio);
    expect((await repository.list()).single.margenPorcentaje, 50);
    expect((await repository.historial(4)).single.referencia, 'lista agosto');
    await repository.actualizarVenta(
      4,
      const ActualizarPrecioVentaRequest(
        margenPorcentaje: 20,
        referencia: 'promocion',
      ),
    );

    verify(
      () => dio.put<Object?>(
        '/api/precios/4/venta',
        data: <String, Object?>{
          'margenPorcentaje': 20,
          'referencia': 'promocion',
        },
      ),
    ).called(1);
  });

  test('logs interpreta el wrapper Page de Spring', () async {
    when(
      () => dio.get<Object?>(
        '/api/logs',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => adminResponse(<String, Object?>{
        'content': <Map<String, Object?>>[
          <String, Object?>{
            'id': 8,
            'entidad': 'VENTA',
            'accion': 'CREAR',
            'fecha': '2026-08-15T14:30:00',
          },
        ],
        'totalElements': 21,
        'totalPages': 3,
        'number': 1,
        'size': 10,
      }),
    );
    final LogRepositoryImpl repository = LogRepositoryImpl(dio);
    final LogsPage page = await repository.list(
      page: 1,
      size: 10,
      entidad: 'VENTA',
    );
    expect(page.content.single.accion, 'CREAR');
    expect(page.totalElements, 21);
    expect(page.totalPages, 3);
    verify(
      () => dio.get<Object?>(
        '/api/logs',
        queryParameters: <String, Object?>{
          'page': 1,
          'size': 10,
          'entidad': 'VENTA',
        },
      ),
    ).called(1);
  });

  test('matriz de permisos conserva codigos del rol', () {
    final Rol role = Rol.fromJson(<String, Object?>{
      'id': 1,
      'nombre': 'Admin',
      'permisos': <String>['PRODUCTOS_VER', 'VENTAS_CREAR'],
    });
    expect(
      role.permisos,
      containsAll(<String>['PRODUCTOS_VER', 'VENTAS_CREAR']),
    );
  });
}
