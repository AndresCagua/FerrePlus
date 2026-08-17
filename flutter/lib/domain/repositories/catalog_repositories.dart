import '../models/catalog_models.dart';

abstract interface class CategoriaRepository {
  Future<List<Categoria>> list();
  Future<Categoria> create(Categoria value);
  Future<Categoria> update(int id, Categoria value);
  Future<void> delete(int id);
}

abstract interface class ProveedorRepository {
  Future<List<Proveedor>> list();
  Future<Proveedor> create(Proveedor value);
  Future<Proveedor> update(int id, Proveedor value);
  Future<void> delete(int id);
}

abstract interface class ClienteRepository {
  Future<List<Cliente>> list();
  Future<Cliente> create(Cliente value);
  Future<Cliente> update(int id, Cliente value);
  Future<void> delete(int id);
}

abstract interface class ProductoRepository {
  Future<List<Producto>> list({String? query, int? categoria});
  Future<Producto> create(Producto value);
  Future<Producto> update(int id, Producto value);
  Future<void> delete(int id);
}
