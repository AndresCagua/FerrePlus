import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ferreplus/core/errors/failure.dart';
import 'package:ferreplus/data/repositories/catalog_repositories_impl.dart';
import 'package:ferreplus/domain/models/catalog_models.dart';

class MockDio extends Mock implements Dio {}

Response<Object?> response(Object? data, {int statusCode = 200}) {
  return Response<Object?>(
    requestOptions: RequestOptions(path: '/api/test'),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  late MockDio dio;

  setUp(() => dio = MockDio());

  test('productos ejecuta listar con filtros y CRUD', () async {
    const Producto product = Producto(id: 1, nombre: 'Martillo');
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => response(<Map<String, Object?>>[
        <String, Object?>{'id': 1, 'nombre': 'Martillo'},
      ]),
    );
    when(() => dio.post<Object?>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => response(<String, Object?>{'id': 1, 'nombre': 'Martillo'}),
    );
    when(() => dio.put<Object?>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => response(<String, Object?>{'id': 1, 'nombre': 'Martillo'}),
    );
    when(
      () => dio.delete<Object?>(any()),
    ).thenAnswer((_) async => response(null));

    final ProductoRepositoryImpl repository = ProductoRepositoryImpl(dio);
    expect(await repository.list(query: 'martillo', categoria: 4), <Producto>[
      product,
    ]);
    await repository.create(product);
    await repository.update(1, product);
    await repository.delete(1);

    verify(
      () => dio.get<Object?>(
        '/api/productos',
        queryParameters: <String, Object?>{'query': 'martillo', 'categoria': 4},
      ),
    ).called(1);
    verify(
      () => dio.post<Object?>('/api/productos', data: any(named: 'data')),
    ).called(1);
    verify(
      () => dio.put<Object?>('/api/productos/1', data: any(named: 'data')),
    ).called(1);
    verify(() => dio.delete<Object?>('/api/productos/1')).called(1);
  });

  test('cada catalogo ejecuta listar, crear, editar y eliminar', () async {
    final Map<String, Object?> category = <String, Object?>{
      'id': 1,
      'nombre': 'Herramientas',
    };
    final Map<String, Object?> supplier = <String, Object?>{
      'id': 1,
      'nombre': 'Acme',
    };
    final Map<String, Object?> customer = <String, Object?>{
      'id': 1,
      'nombre': 'Ana',
    };
    when(() => dio.get<Object?>(any())).thenAnswer((invocation) async {
      final String path = invocation.positionalArguments.first as String;
      return response(<Map<String, Object?>>[
        path.contains('categorias')
            ? category
            : path.contains('proveedores')
            ? supplier
            : customer,
      ]);
    });
    when(
      () => dio.post<Object?>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => response(category));
    when(
      () => dio.put<Object?>(any(), data: any(named: 'data')),
    ).thenAnswer((_) async => response(category));
    when(
      () => dio.delete<Object?>(any()),
    ).thenAnswer((_) async => response(null));

    final CategoriaRepositoryImpl categories = CategoriaRepositoryImpl(dio);
    final ProveedorRepositoryImpl suppliers = ProveedorRepositoryImpl(dio);
    final ClienteRepositoryImpl customers = ClienteRepositoryImpl(dio);
    await categories.list();
    await categories.create(const Categoria(id: 0, nombre: 'Nueva'));
    await categories.update(1, const Categoria(id: 1, nombre: 'Editada'));
    await categories.delete(1);
    await suppliers.list();
    await suppliers.create(const Proveedor(id: 0, nombre: 'Nuevo'));
    await suppliers.update(1, const Proveedor(id: 1, nombre: 'Editado'));
    await suppliers.delete(1);
    await customers.list();
    await customers.create(const Cliente(id: 0, nombre: 'Nuevo'));
    await customers.update(1, const Cliente(id: 1, nombre: 'Editado'));
    await customers.delete(1);

    verify(() => dio.get<Object?>('/api/categorias')).called(1);
    verify(() => dio.get<Object?>('/api/proveedores')).called(1);
    verify(() => dio.get<Object?>('/api/clientes')).called(1);
  });

  test('mapea respuestas Dio a Failure de dominio', () async {
    when(() => dio.get<Object?>(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/api/categorias'),
        response: response(<String, Object?>{}, statusCode: 422),
      ),
    );

    expect(
      () => CategoriaRepositoryImpl(dio).list(),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
