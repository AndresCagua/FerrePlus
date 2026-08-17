// API models are immutable by convention; constructors expose final fields.
// ignore_for_file: depend_on_referenced_packages
import 'package:meta/meta.dart';

Map<String, Object?> adminMap(Object? value) =>
    Map<String, Object?>.from(value! as Map<Object?, Object?>);
int? adminInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
double adminDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
DateTime? adminDate(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');
List<Object?> adminList(Object? value) =>
    value is List<Object?> ? value : const <Object?>[];

@immutable
class PrecioProducto {
  const PrecioProducto({
    required this.id,
    required this.nombre,
    this.codigoBarras,
    required this.precioCompra,
    required this.precioVenta,
    this.ganancia = 0,
    this.margenPorcentaje = 0,
    this.fechaActualizacion,
  });
  final int id;
  final String nombre;
  final String? codigoBarras;
  final double precioCompra;
  final double precioVenta;
  final double ganancia;
  final double margenPorcentaje;
  final DateTime? fechaActualizacion;
  factory PrecioProducto.fromJson(Map<String, Object?> j) => PrecioProducto(
    id: adminInt(j['id']) ?? 0,
    nombre: '${j['nombre'] ?? ''}',
    codigoBarras: j['codigoBarras'] as String?,
    precioCompra: adminDouble(j['precioCompra']),
    precioVenta: adminDouble(j['precioVenta']),
    ganancia: adminDouble(j['ganancia']),
    margenPorcentaje: adminDouble(j['margenPorcentaje']),
    fechaActualizacion: adminDate(j['fechaActualizacion']),
  );
}

@immutable
class HistoricoPrecio {
  const HistoricoPrecio({
    required this.id,
    required this.productoId,
    required this.precioCompra,
    required this.precioVenta,
    this.tipoCambio,
    this.referencia,
    this.fechaCambio,
    this.usuarioNombre,
  });
  final int id;
  final int productoId;
  final double precioCompra;
  final double precioVenta;
  final String? tipoCambio;
  final String? referencia;
  final DateTime? fechaCambio;
  final String? usuarioNombre;
  factory HistoricoPrecio.fromJson(Map<String, Object?> j) => HistoricoPrecio(
    id: adminInt(j['id']) ?? 0,
    productoId: adminInt(j['productoId']) ?? 0,
    precioCompra: adminDouble(j['precioCompra']),
    precioVenta: adminDouble(j['precioVenta']),
    tipoCambio: j['tipoCambio'] as String?,
    referencia: j['referencia'] as String?,
    fechaCambio: adminDate(j['fechaCambio']),
    usuarioNombre: j['usuarioNombre'] as String?,
  );
}

@immutable
class ActualizarPrecioVentaRequest {
  const ActualizarPrecioVentaRequest({
    this.nuevoPrecio,
    this.margenPorcentaje,
    this.referencia,
  });
  final double? nuevoPrecio;
  final double? margenPorcentaje;
  final String? referencia;
  Map<String, Object?> toJson() => <String, Object?>{
    'nuevoPrecio': nuevoPrecio,
    'margenPorcentaje': margenPorcentaje,
    'referencia': referencia,
  }..removeWhere((String _, Object? v) => v == null);
}

@immutable
class UsuarioPermiso {
  const UsuarioPermiso({required this.permisoCodigo, required this.concedido});
  final String permisoCodigo;
  final bool concedido;
  Map<String, Object?> toJson() => <String, Object?>{
    'permisoCodigo': permisoCodigo,
    'concedido': concedido,
  };
  factory UsuarioPermiso.fromJson(Map<String, Object?> j) => UsuarioPermiso(
    permisoCodigo: '${j['permisoCodigo'] ?? ''}',
    concedido: j['concedido'] == true,
  );
}

@immutable
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    this.activo = true,
    this.rolId,
    this.rolNombre,
    this.permisos = const <String>[],
    this.overrides = const <UsuarioPermiso>[],
  });
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final bool activo;
  final int? rolId;
  final String? rolNombre;
  final List<String> permisos;
  final List<UsuarioPermiso> overrides;
  factory Usuario.fromJson(Map<String, Object?> j) => Usuario(
    id: adminInt(j['id']) ?? 0,
    nombre: '${j['nombre'] ?? ''}',
    email: '${j['email'] ?? ''}',
    telefono: j['telefono'] as String?,
    activo: j['activo'] != false,
    rolId: adminInt(j['rolId']),
    rolNombre: j['rolNombre'] as String?,
    permisos: adminList(
      j['permisos'],
    ).map((Object? v) => '$v').toList(growable: false),
    overrides: adminList(j['overrides'])
        .map((Object? v) => UsuarioPermiso.fromJson(adminMap(v)))
        .toList(growable: false),
  );
}

@immutable
class UsuarioRequest {
  const UsuarioRequest({
    required this.nombre,
    required this.email,
    this.telefono,
    required this.activo,
    required this.rolId,
    this.password,
    this.overrides = const <UsuarioPermiso>[],
  });
  final String nombre, email;
  final String? telefono, password;
  final bool activo;
  final int rolId;
  final List<UsuarioPermiso> overrides;
  Map<String, Object?> toJson() => <String, Object?>{
    'nombre': nombre,
    'email': email,
    'telefono': telefono,
    'activo': activo,
    'rolId': rolId,
    'password': password,
    'overrides': overrides.map((UsuarioPermiso e) => e.toJson()).toList(),
  }..removeWhere((String _, Object? v) => v == null);
}

@immutable
class CambioPasswordRequest {
  const CambioPasswordRequest({
    required this.passwordActual,
    required this.nuevoPassword,
  });
  final String passwordActual, nuevoPassword;
  Map<String, Object?> toJson() => <String, Object?>{
    'passwordActual': passwordActual,
    'nuevoPassword': nuevoPassword,
  };
}

@immutable
class Rol {
  const Rol({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.permisos = const <String>[],
  });
  final int id;
  final String nombre;
  final String? descripcion;
  final List<String> permisos;
  factory Rol.fromJson(Map<String, Object?> j) => Rol(
    id: adminInt(j['id']) ?? 0,
    nombre: '${j['nombre'] ?? ''}',
    descripcion: j['descripcion'] as String?,
    permisos: adminList(
      j['permisos'],
    ).map((Object? v) => '$v').toList(growable: false),
  );
}

@immutable
class RolRequest {
  const RolRequest({
    required this.nombre,
    this.descripcion,
    this.permisos = const <String>[],
  });
  final String nombre;
  final String? descripcion;
  final List<String> permisos;
  Map<String, Object?> toJson() => <String, Object?>{
    'nombre': nombre,
    'descripcion': descripcion,
    'permisos': permisos,
  };
}

@immutable
class Permiso {
  const Permiso({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.accion,
    this.moduloId,
    this.moduloCodigo,
    this.moduloNombre,
  });
  final int id;
  final String codigo, nombre;
  final String? accion, moduloCodigo, moduloNombre;
  final int? moduloId;
  factory Permiso.fromJson(Map<String, Object?> j) => Permiso(
    id: adminInt(j['id']) ?? 0,
    codigo: '${j['codigo'] ?? ''}',
    nombre: '${j['nombre'] ?? ''}',
    accion: j['accion'] as String?,
    moduloId: adminInt(j['moduloId']),
    moduloCodigo: j['moduloCodigo'] as String?,
    moduloNombre: j['moduloNombre'] as String?,
  );
}

@immutable
class Modulo {
  const Modulo({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.orden,
    this.permisos = const <Permiso>[],
  });
  final int id;
  final String nombre, codigo;
  final int? orden;
  final List<Permiso> permisos;
  factory Modulo.fromJson(Map<String, Object?> j) => Modulo(
    id: adminInt(j['id']) ?? 0,
    nombre: '${j['nombre'] ?? ''}',
    codigo: '${j['codigo'] ?? ''}',
    orden: adminInt(j['orden']),
    permisos: adminList(
      j['permisos'],
    ).map((Object? v) => Permiso.fromJson(adminMap(v))).toList(growable: false),
  );
}

@immutable
class ChartPoint {
  const ChartPoint({required this.fecha, required this.total});
  final DateTime? fecha;
  final double total;
  factory ChartPoint.fromJson(Map<String, Object?> j) =>
      ChartPoint(fecha: adminDate(j['fecha']), total: adminDouble(j['total']));
}

@immutable
class ReporteDashboard {
  const ReporteDashboard({
    this.totalProductos = 0,
    this.productosStockBajo = 0,
    this.ventasHoy = 0,
    this.totalVentasHoy = 0,
    this.ventasMes = 0,
    this.totalVentasMes = 0,
    this.comprasMes = 0,
    this.totalComprasMes = 0,
    this.gastosMes = 0,
    this.totalGastosMes = 0,
    this.totalClientes = 0,
    this.totalProveedores = 0,
    this.totalUsuarios = 0,
    this.saldoPendienteClientes = 0,
    this.ventasPorDia = const <ChartPoint>[],
    this.productosStockBajoList = const <Map<String, Object?>>[],
  });
  final int totalProductos,
      productosStockBajo,
      comprasMes,
      gastosMes,
      totalClientes,
      totalProveedores,
      totalUsuarios;
  final double ventasHoy,
      totalVentasHoy,
      ventasMes,
      totalVentasMes,
      totalComprasMes,
      totalGastosMes,
      saldoPendienteClientes;
  final List<ChartPoint> ventasPorDia;
  final List<Map<String, Object?>> productosStockBajoList;
  factory ReporteDashboard.fromJson(Map<String, Object?> j) => ReporteDashboard(
    totalProductos: adminInt(j['totalProductos']) ?? 0,
    productosStockBajo: adminInt(j['productosStockBajo']) ?? 0,
    ventasHoy: adminDouble(j['ventasHoy']),
    totalVentasHoy: adminDouble(j['totalVentasHoy']),
    ventasMes: adminDouble(j['ventasMes']),
    totalVentasMes: adminDouble(j['totalVentasMes']),
    comprasMes: adminInt(j['comprasMes']) ?? 0,
    totalComprasMes: adminDouble(j['totalComprasMes']),
    gastosMes: adminInt(j['gastosMes']) ?? 0,
    totalGastosMes: adminDouble(j['totalGastosMes']),
    totalClientes: adminInt(j['totalClientes']) ?? 0,
    totalProveedores: adminInt(j['totalProveedores']) ?? 0,
    totalUsuarios: adminInt(j['totalUsuarios']) ?? 0,
    saldoPendienteClientes: adminDouble(j['saldoPendienteClientes']),
    ventasPorDia: adminList(j['ventasPorDia'])
        .map((Object? v) => ChartPoint.fromJson(adminMap(v)))
        .toList(growable: false),
    productosStockBajoList: adminList(
      j['productosStockBajoList'],
    ).map((Object? v) => adminMap(v)).toList(growable: false),
  );
}

@immutable
class Auditoria {
  const Auditoria({
    required this.id,
    required this.entidad,
    this.entidadId,
    required this.accion,
    this.usuarioId,
    this.usuarioNombre,
    this.fecha,
    this.detalle,
  });
  final int id;
  final String entidad, accion;
  final int? entidadId, usuarioId;
  final String? usuarioNombre, detalle;
  final DateTime? fecha;
  factory Auditoria.fromJson(Map<String, Object?> j) => Auditoria(
    id: adminInt(j['id']) ?? 0,
    entidad: '${j['entidad'] ?? ''}',
    entidadId: adminInt(j['entidadId']),
    accion: '${j['accion'] ?? ''}',
    usuarioId: adminInt(j['usuarioId']),
    usuarioNombre: j['usuarioNombre'] as String?,
    fecha: adminDate(j['fecha']),
    detalle: j['detalle'] as String?,
  );
}

@immutable
class UsuarioOpcion {
  const UsuarioOpcion({required this.id, required this.nombre});
  final int id;
  final String nombre;
  factory UsuarioOpcion.fromJson(Map<String, Object?> j) =>
      UsuarioOpcion(id: adminInt(j['id']) ?? 0, nombre: '${j['nombre'] ?? ''}');
}

@immutable
class LogsPage {
  const LogsPage({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.number,
    required this.size,
  });
  final List<Auditoria> content;
  final int totalElements, totalPages, number, size;
  factory LogsPage.fromJson(Map<String, Object?> j) => LogsPage(
    content: adminList(j['content'])
        .map((Object? v) => Auditoria.fromJson(adminMap(v)))
        .toList(growable: false),
    totalElements: adminInt(j['totalElements']) ?? 0,
    totalPages: adminInt(j['totalPages']) ?? 0,
    number: adminInt(j['number']) ?? 0,
    size: adminInt(j['size']) ?? 20,
  );
}

@immutable
class LogsEliminados {
  const LogsEliminados(this.eliminados);
  final int eliminados;
  factory LogsEliminados.fromJson(Map<String, Object?> j) =>
      LogsEliminados(adminInt(j['eliminados']) ?? 0);
}
