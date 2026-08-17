import '../models/admin_models.dart';
import '../models/commercial_models.dart';

abstract class PrecioRepository {
  Future<List<PrecioProducto>> list();
  Future<PrecioProducto> getById(int id);
  Future<List<HistoricoPrecio>> historial(int id);
  Future<void> actualizarVenta(int id, ActualizarPrecioVentaRequest request);
}

abstract class UsuarioRepository {
  Future<List<Usuario>> list();
  Future<Usuario> getById(int id);
  Future<Usuario> me();
  Future<Usuario> create(UsuarioRequest request);
  Future<Usuario> update(int id, UsuarioRequest request);
  Future<void> delete(int id);
  Future<void> changePassword(int id, CambioPasswordRequest request);
}

abstract class RolRepository {
  Future<List<Rol>> list();
  Future<Rol> getById(int id);
  Future<Rol> create(RolRequest request);
  Future<Rol> update(int id, RolRequest request);
  Future<void> delete(int id);
}

abstract class CatalogoAdminRepository {
  Future<List<Modulo>> modulos();
  Future<List<Permiso>> permisos();
}

abstract class ReporteRepository {
  Future<ReporteDashboard> dashboard();
  Future<List<Venta>> ventas(DateTime desde, DateTime hasta);
  Future<ReporteDashboard> inventario();
  Future<ReporteDashboard> movimientos();
}

abstract class LogRepository {
  Future<LogsPage> list({
    int page,
    int size,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? usuarioId,
    String? entidad,
    String? accion,
  });
  Future<List<UsuarioOpcion>> usuarios();
  Future<LogsEliminados> deleteRange(DateTime desde, DateTime hasta);
}
