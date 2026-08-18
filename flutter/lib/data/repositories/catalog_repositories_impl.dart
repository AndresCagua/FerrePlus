import 'package:dio/dio.dart';

import '../../core/constants/api_paths.dart';
import '../../core/errors/failure_mapper.dart';
import '../../domain/models/catalog_models.dart';
import '../../domain/repositories/catalog_repositories.dart';

Map<String, Object?> _map(Object? data) =>
    Map<String, Object?>.from(data! as Map<Object?, Object?>);
List<Map<String, Object?>> _list(Object? data) =>
    (data! as List<Object?>).map(_map).toList(growable: false);

abstract class _CrudRepository<T> {
  _CrudRepository(this.dio, this.path);
  final Dio dio;
  final String path;
  T decode(Map<String, Object?> json);
  Map<String, Object?> payload(T value);

  Future<List<T>> list() async {
    try {
      final Response<Object?> response = await dio.get<Object?>(path);
      return _list(response.data).map(decode).toList(growable: false);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<T> getByIdValue(int id) async {
    try {
      final Response<Object?> response = await dio.get<Object?>('$path/$id');
      return decode(_map(response.data));
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<T> createValue(T value) async {
    try {
      final Response<Object?> response = await dio.post<Object?>(
        path,
        data: payload(value),
      );
      return decode(_map(response.data));
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<T> updateValue(int id, T value) async {
    try {
      final Response<Object?> response = await dio.put<Object?>(
        '$path/$id',
        data: payload(value),
      );
      return decode(_map(response.data));
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Future<void> deleteValue(int id) async {
    try {
      await dio.delete<Object?>('$path/$id');
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}

class CategoriaRepositoryImpl extends _CrudRepository<Categoria>
    implements CategoriaRepository {
  CategoriaRepositoryImpl(Dio dio) : super(dio, ApiPaths.categorias);
  @override
  Categoria decode(Map<String, Object?> json) => Categoria.fromJson(json);
  @override
  Map<String, Object?> payload(Categoria value) => <String, Object?>{
    'nombre': value.nombre,
    'descripcion': value.descripcion,
  };
  @override
  Future<Categoria> create(Categoria value) => createValue(value);
  @override
  Future<Categoria> getById(int id) => getByIdValue(id);
  @override
  Future<Categoria> update(int id, Categoria value) => updateValue(id, value);
  @override
  Future<void> delete(int id) => deleteValue(id);
}

class ProveedorRepositoryImpl extends _CrudRepository<Proveedor>
    implements ProveedorRepository {
  ProveedorRepositoryImpl(Dio dio) : super(dio, ApiPaths.proveedores);
  @override
  Proveedor decode(Map<String, Object?> json) => Proveedor.fromJson(json);
  @override
  Map<String, Object?> payload(Proveedor value) => <String, Object?>{
    'nombre': value.nombre,
    'ruc': value.ruc,
    'contacto': value.contacto,
    'telefono': value.telefono,
    'email': value.email,
    'direccion': value.direccion,
    'activo': value.activo,
  };
  @override
  Future<Proveedor> create(Proveedor value) => createValue(value);
  @override
  Future<Proveedor> getById(int id) => getByIdValue(id);
  @override
  Future<Proveedor> update(int id, Proveedor value) => updateValue(id, value);
  @override
  Future<void> delete(int id) => deleteValue(id);
}

class ClienteRepositoryImpl extends _CrudRepository<Cliente>
    implements ClienteRepository {
  ClienteRepositoryImpl(Dio dio) : super(dio, ApiPaths.clientes);
  @override
  Cliente decode(Map<String, Object?> json) => Cliente.fromJson(json);
  @override
  Map<String, Object?> payload(Cliente value) => <String, Object?>{
    'nombre': value.nombre,
    'ruc': value.ruc,
    'telefono': value.telefono,
    'email': value.email,
    'direccion': value.direccion,
    'saldoPendiente': value.saldoPendiente,
    'activo': value.activo,
  };
  @override
  Future<Cliente> create(Cliente value) => createValue(value);
  @override
  Future<Cliente> getById(int id) => getByIdValue(id);
  @override
  Future<Cliente> update(int id, Cliente value) => updateValue(id, value);
  @override
  Future<void> delete(int id) => deleteValue(id);
}

class ProductoRepositoryImpl implements ProductoRepository {
  ProductoRepositoryImpl(this.dio);
  final Dio dio;
  @override
  Future<Producto> getById(int id) async {
    try {
      final Response<Object?> response = await dio.get<Object?>(
        '${ApiPaths.productos}/$id',
      );
      return Producto.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<List<Producto>> list({String? query, int? categoria}) async {
    try {
      final Response<Object?> response = await dio.get<Object?>(
        ApiPaths.productos,
        queryParameters:
            <String, Object?>{'query': query, 'categoria': categoria}
              ..removeWhere(
                (String key, Object? value) => value == null || value == '',
              ),
      );
      return _list(
        response.data,
      ).map(Producto.fromJson).toList(growable: false);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  Map<String, Object?> _payload(Producto value) => <String, Object?>{
    'nombre': value.nombre,
    'descripcion': value.descripcion,
    'codigoBarras': value.codigoBarras,
    'ubicacion': value.ubicacion,
    'stockActual': value.stockActual,
    'stockMinimo': value.stockMinimo,
    'stockMaximo': value.stockMaximo,
    'precioCompra': value.precioCompra,
    'precioVenta': value.precioVenta,
    'unidadMedida': value.unidadMedida,
    'imagen': value.imagen,
    'categoria': value.categoria == null
        ? null
        : <String, Object?>{'id': value.categoria!.id},
    'proveedor': value.proveedor == null
        ? null
        : <String, Object?>{'id': value.proveedor!.id},
    'activo': value.activo,
  };
  @override
  Future<Producto> create(Producto value) async =>
      _mutate('post', ApiPaths.productos, value);
  @override
  Future<Producto> update(int id, Producto value) async =>
      _mutate('put', '${ApiPaths.productos}/$id', value);
  Future<Producto> _mutate(String method, String path, Producto value) async {
    try {
      final Response<Object?> response = method == 'post'
          ? await dio.post<Object?>(path, data: _payload(value))
          : await dio.put<Object?>(path, data: _payload(value));
      return Producto.fromJson(_map(response.data));
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await dio.delete<Object?>('${ApiPaths.productos}/$id');
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}
