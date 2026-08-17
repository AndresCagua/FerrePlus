// ignore_for_file: annotate_overrides, curly_braces_in_flow_control_structures
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../data/repositories/admin_repositories_impl.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/admin_repositories.dart';

final precioRepositoryProvider = Provider<PrecioRepository>(
  (ref) => PrecioRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final usuarioRepositoryProvider = Provider<UsuarioRepository>(
  (ref) => UsuarioRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final rolRepositoryProvider = Provider<RolRepository>(
  (ref) => RolRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final catalogoAdminRepositoryProvider = Provider<CatalogoAdminRepository>(
  (ref) => CatalogoAdminRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final reporteRepositoryProvider = Provider<ReporteRepository>(
  (ref) => ReporteRepositoryImpl(ref.watch(apiClientProvider).dio),
);
final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepositoryImpl(ref.watch(apiClientProvider).dio),
);

final preciosProvider =
    AsyncNotifierProvider<PreciosNotifier, List<PrecioProducto>>(
      PreciosNotifier.new,
    );

class PreciosNotifier extends AsyncNotifier<List<PrecioProducto>> {
  late final PrecioRepository repository;
  @override
  Future<List<PrecioProducto>> build() {
    repository = ref.watch(precioRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> updatePrice(int id, ActualizarPrecioVentaRequest r) async {
    await repository.actualizarVenta(id, r);
    await reload();
  }
}

final usuariosProvider = AsyncNotifierProvider<UsuariosNotifier, List<Usuario>>(
  UsuariosNotifier.new,
);

class UsuariosNotifier extends AsyncNotifier<List<Usuario>> {
  late final UsuarioRepository repository;
  @override
  Future<List<Usuario>> build() {
    repository = ref.watch(usuarioRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> save(int? id, UsuarioRequest r) async {
    if (id == null)
      await repository.create(r);
    else
      await repository.update(id, r);
    await reload();
  }

  Future<void> remove(int id) async {
    await repository.delete(id);
    await reload();
  }

  Future<void> changePassword(int id, CambioPasswordRequest r) =>
      repository.changePassword(id, r);
}

final rolesProvider = AsyncNotifierProvider<RolesNotifier, List<Rol>>(
  RolesNotifier.new,
);

class RolesNotifier extends AsyncNotifier<List<Rol>> {
  late final RolRepository repository;
  @override
  Future<List<Rol>> build() {
    repository = ref.watch(rolRepositoryProvider);
    return repository.list();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(repository.list);
  }

  Future<void> save(int? id, RolRequest r) async {
    if (id == null)
      await repository.create(r);
    else
      await repository.update(id, r);
    await reload();
  }

  Future<void> remove(int id) async {
    await repository.delete(id);
    await reload();
  }
}

final modulosProvider = FutureProvider<List<Modulo>>(
  (ref) => ref.watch(catalogoAdminRepositoryProvider).modulos(),
);
final permisosProvider = FutureProvider<List<Permiso>>(
  (ref) => ref.watch(catalogoAdminRepositoryProvider).permisos(),
);
final dashboardProvider = FutureProvider<ReporteDashboard>(
  (ref) => ref.watch(reporteRepositoryProvider).dashboard(),
);
final inventoryReportProvider = FutureProvider<ReporteDashboard>(
  (ref) => ref.watch(reporteRepositoryProvider).inventario(),
);
final movementsReportProvider = FutureProvider<ReporteDashboard>(
  (ref) => ref.watch(reporteRepositoryProvider).movimientos(),
);

final reportSalesProvider = FutureProvider.family<List<Venta>, DateRange>(
  (ref, range) =>
      ref.watch(reporteRepositoryProvider).ventas(range.desde, range.hasta),
);

class DateRange {
  const DateRange(this.desde, this.hasta);
  final DateTime desde;
  final DateTime hasta;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.desde == desde && other.hasta == hasta;

  @override
  int get hashCode => Object.hash(desde, hasta);
}

final logsProvider = AsyncNotifierProvider<LogsNotifier, LogsPage>(
  LogsNotifier.new,
);

class LogsNotifier extends AsyncNotifier<LogsPage> {
  late final LogRepository repository;
  int page = 0;
  DateTime? desde, hasta;
  int? usuarioId;
  String? entidad, accion;
  @override
  Future<LogsPage> build() {
    repository = ref.watch(logRepositoryProvider);
    return _fetch();
  }

  Future<LogsPage> _fetch() => repository.list(
    page: page,
    fechaDesde: desde,
    fechaHasta: hasta,
    usuarioId: usuarioId,
    entidad: entidad,
    accion: accion,
  );
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setFilters({
    DateTime? from,
    DateTime? to,
    int? user,
    String? entity,
    String? action,
  }) async {
    desde = from;
    hasta = to;
    usuarioId = user;
    entidad = entity;
    accion = action;
    page = 0;
    await reload();
  }

  Future<void> goTo(int value) async {
    page = value;
    await reload();
  }
}

final logUsersProvider = FutureProvider<List<UsuarioOpcion>>(
  (ref) => ref.watch(logRepositoryProvider).usuarios(),
);
