import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ferreplus/data/local/app_database.dart';
import 'package:ferreplus/data/local/daos/cached_expenses_dao.dart';
import 'package:ferreplus/data/local/daos/cached_movements_dao.dart';
import 'package:ferreplus/data/local/daos/cached_purchases_dao.dart';
import 'package:ferreplus/data/local/daos/cached_sales_dao.dart';
import 'package:ferreplus/data/offline/payload_codec.dart';
import 'package:ferreplus/domain/models/commercial_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late PayloadCodec codec;

  setUp(() {
    database = AppDatabase.memory();
    codec = PayloadCodec(storage: _MemorySecureStorage());
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'replace conserva ventas, compras, gastos y movimientos pending',
    () async {
      final CachedSalesDao sales = CachedSalesDao(database, codec: codec);
      final CachedPurchasesDao purchases = CachedPurchasesDao(
        database,
        codec: codec,
      );
      final CachedExpensesDao expenses = CachedExpensesDao(
        database,
        codec: codec,
      );
      final CachedMovementsDao movements = CachedMovementsDao(
        database,
        codec: codec,
      );

      await sales.upsertOptimistic(_sale(1), idempotencyKey: 'sale-pending');
      await purchases.upsertOptimistic(
        _purchase(2),
        idempotencyKey: 'purchase-pending',
      );
      await expenses.upsertOptimistic(
        _expense(3),
        idempotencyKey: 'expense-pending',
      );
      await movements.upsertOptimistic(
        _movement(4),
        idempotencyKey: 'movement-pending',
      );

      await sales.replace(<Venta>[_sale(1)]);
      await purchases.replace(<Compra>[_purchase(2)]);
      await expenses.replace(<Gasto>[_expense(3)]);
      await movements.replace(<MovimientoStock>[_movement(4)]);

      expect((await sales.read()).map((Venta value) => value.id), contains(1));
      expect(
        (await purchases.read()).map((Compra value) => value.id),
        contains(2),
      );
      expect(
        (await expenses.read()).map((Gasto value) => value.id),
        contains(3),
      );
      expect(
        (await movements.read()).map((MovimientoStock value) => value.id),
        contains(4),
      );
    },
  );

  test('clear elimina la cache de la sesion al cerrar sesion', () async {
    final CachedSalesDao sales = CachedSalesDao(database, codec: codec);
    await sales.replace(<Venta>[_sale(7)]);

    // Como las tablas no tienen user_id, el logout limpia el snapshot completo.
    await sales.clear();
    expect(await sales.read(), isEmpty);
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _values.remove(key);
    } else {
      _values[key] = value;
    }
  }
}

Venta _sale(int id) => Venta(
  id: id,
  subtotal: 10,
  descuento: 0,
  iva: 1.6,
  total: 11.6,
  estado: 'PENDIENTE',
);

Compra _purchase(int id) => Compra(
  id: id,
  numeroFactura: 'F-$id',
  subtotal: 10,
  descuento: 0,
  iva: 1.6,
  total: 11.6,
  estado: 'PENDIENTE',
);

Gasto _expense(int id) => Gasto(id: id, descripcion: 'Gasto $id', monto: 10);

MovimientoStock _movement(int id) =>
    MovimientoStock(id: id, cantidad: 1, tipo: 'ENTRADA');
