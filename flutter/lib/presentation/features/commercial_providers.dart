import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_providers.dart';
import '../../../data/repositories/commercial_repositories_impl.dart';
import '../../../domain/models/commercial_models.dart';
import '../../../domain/repositories/commercial_repositories.dart';

final ventaRepositoryProvider = Provider<VentaRepository>(
  (ref) => VentaRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final compraRepositoryProvider = Provider<CompraRepository>(
  (ref) => CompraRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final movimientoRepositoryProvider = Provider<MovimientoRepository>(
  (ref) => MovimientoRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final gastoRepositoryProvider = Provider<GastoRepository>(
  (ref) => GastoRepositoryImpl(ref.watch(apiClientProvider).dio),
);

final ventasProvider = AsyncNotifierProvider<VentasNotifier, List<Venta>>(
  VentasNotifier.new,
);
final comprasProvider = AsyncNotifierProvider<ComprasNotifier, List<Compra>>(
  ComprasNotifier.new,
);
final movimientosProvider =
    AsyncNotifierProvider<MovimientosNotifier, List<MovimientoStock>>(
      MovimientosNotifier.new,
    );
final gastosProvider = AsyncNotifierProvider<GastosNotifier, List<Gasto>>(
  GastosNotifier.new,
);
final ventaDetailProvider = FutureProvider.family<Venta, int>(
  (ref, id) => ref.watch(ventaRepositoryProvider).getById(id),
);
final posNotifierProvider = NotifierProvider<PosNotifier, PosDraft>(
  PosNotifier.new,
);

class PosDraft {
  const PosDraft({
    this.detalles = const <DetalleVenta>[],
    this.clienteId,
    this.descuento = 0,
    this.metodoPago = 'EFECTIVO',
    this.observaciones,
  });
  final List<DetalleVenta> detalles;
  final int? clienteId;
  final num descuento;
  final String metodoPago;
  final String? observaciones;
  num get subtotal => detalles.fold<num>(
    0,
    (num total, DetalleVenta item) =>
        total + item.cantidad * item.precioUnitario,
  );
  num get iva => (subtotal - descuento) * .15;
  num get total => subtotal - descuento + iva;
  PosDraft copyWith({
    List<DetalleVenta>? detalles,
    int? clienteId,
    num? descuento,
    String? metodoPago,
    String? observaciones,
  }) => PosDraft(
    detalles: detalles ?? this.detalles,
    clienteId: clienteId ?? this.clienteId,
    descuento: descuento ?? this.descuento,
    metodoPago: metodoPago ?? this.metodoPago,
    observaciones: observaciones ?? this.observaciones,
  );
}

class PosNotifier extends Notifier<PosDraft> {
  @override
  PosDraft build() => const PosDraft();
  void addLine(DetalleVenta detail) => state = state.copyWith(
    detalles: <DetalleVenta>[...state.detalles, detail],
  );
  void removeLine(int index) => state = state.copyWith(
    detalles: <DetalleVenta>[...state.detalles]..removeAt(index),
  );
  void setClient(int? value) => state = state.copyWith(clienteId: value);
  void setDiscount(num value) => state = state.copyWith(descuento: value);
  void setPaymentMethod(String value) =>
      state = state.copyWith(metodoPago: value);
  void setObservations(String value) =>
      state = state.copyWith(observaciones: value);
  void clear() => state = const PosDraft();
}

class VentasNotifier extends AsyncNotifier<List<Venta>> {
  late final VentaRepository repository;
  bool mutationInFlight = false;
  DateTime? desde;
  DateTime? hasta;
  String? estado;
  int? clienteId;
  @override
  Future<List<Venta>> build() {
    repository = ref.watch(ventaRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _filterSales(await repository.list()),
    );
  }

  List<Venta> _filterSales(List<Venta> values) => values
      .where((Venta sale) {
        final DateTime? date = sale.fechaCreacion;
        final DateTime? exclusiveEnd = hasta == null
            ? null
            : DateTime(hasta!.year, hasta!.month, hasta!.day + 1);
        return (estado == null || sale.estado == estado) &&
            (clienteId == null || sale.clienteId == clienteId) &&
            (desde == null || date == null || !date.isBefore(desde!)) &&
            (exclusiveEnd == null ||
                date == null ||
                date.isBefore(exclusiveEnd));
      })
      .toList(growable: false);

  Future<void> filter({
    DateTime? from,
    DateTime? to,
    String? status,
    int? client,
  }) async {
    desde = from;
    hasta = to;
    estado = status;
    clienteId = client;
    await reload();
  }

  Future<void> create(VentaRequest request) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.create(request);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Venta>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> anular(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.anular(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Venta>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<List<Venta>> report(DateTime from, DateTime to) =>
      repository.reportePorFecha(from, to);
}

class ComprasNotifier extends AsyncNotifier<List<Compra>> {
  late final CompraRepository repository;
  bool mutationInFlight = false;
  DateTime? desde;
  DateTime? hasta;
  String? estado;
  int? proveedorId;
  @override
  Future<List<Compra>> build() {
    repository = ref.watch(compraRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _filterPurchases(await repository.list()),
    );
  }

  List<Compra> _filterPurchases(List<Compra> values) => values
      .where((Compra purchase) {
        final DateTime? date = purchase.fechaFactura ?? purchase.fechaCreacion;
        final DateTime? exclusiveEnd = hasta == null
            ? null
            : DateTime(hasta!.year, hasta!.month, hasta!.day + 1);
        return (estado == null || purchase.estado == estado) &&
            (proveedorId == null || purchase.proveedorId == proveedorId) &&
            (desde == null || date == null || !date.isBefore(desde!)) &&
            (exclusiveEnd == null ||
                date == null ||
                date.isBefore(exclusiveEnd));
      })
      .toList(growable: false);

  Future<void> filter({
    DateTime? from,
    DateTime? to,
    String? status,
    int? supplier,
  }) async {
    desde = from;
    hasta = to;
    estado = status;
    proveedorId = supplier;
    await reload();
  }

  Future<void> save(int? id, CompraRequest request) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      if (id == null) {
        await repository.create(request);
      } else {
        await repository.update(id, request);
      }
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Compra>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> anular(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.anular(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Compra>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<List<Compra>> report(DateTime from, DateTime to) =>
      repository.reportePorFecha(from, to);
}

class MovimientosNotifier extends AsyncNotifier<List<MovimientoStock>> {
  late final MovimientoRepository repository;
  bool mutationInFlight = false;
  int? productoId;
  String? tipo;
  DateTime? desde;
  DateTime? hasta;
  @override
  Future<List<MovimientoStock>> build() {
    repository = ref.watch(movimientoRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => repository.list(
        productoId: productoId,
        tipo: tipo,
        desde: desde,
        hasta: hasta,
      ),
    );
  }

  Future<void> filter({
    int? product,
    String? movementType,
    DateTime? from,
    DateTime? to,
  }) async {
    productoId = product;
    tipo = movementType;
    desde = from;
    hasta = to;
    await reload();
  }

  Future<void> create(MovimientoStockRequest request) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.create(request);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<MovimientoStock>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }
}

class GastosNotifier extends AsyncNotifier<List<Gasto>> {
  late final GastoRepository repository;
  bool mutationInFlight = false;
  @override
  Future<List<Gasto>> build() {
    repository = ref.watch(gastoRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> save(int? id, GastoRequest request) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      if (id == null) {
        await repository.create(request);
      } else {
        await repository.update(id, request);
      }
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Gasto>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }

  Future<void> remove(int id) async {
    if (mutationInFlight) return;
    mutationInFlight = true;
    state = const AsyncLoading();
    try {
      await repository.delete(id);
      await reload();
    } catch (error, stack) {
      state = AsyncError<List<Gasto>>(error, stack);
      rethrow;
    } finally {
      mutationInFlight = false;
    }
  }
}
