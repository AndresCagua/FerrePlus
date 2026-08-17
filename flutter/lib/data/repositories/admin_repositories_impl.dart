// ignore_for_file: annotate_overrides
import 'package:dio/dio.dart';
import '../../core/constants/api_paths.dart';
import '../../core/errors/failure_mapper.dart';
import '../../domain/models/admin_models.dart';
import '../../domain/models/commercial_models.dart';
import '../../domain/repositories/admin_repositories.dart';

Map<String, Object?> _m(Object? value) => adminMap(value);
List<Object?> _l(Object? value) => adminList(value);
Future<T> _request<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioFailure(error);
  }
}

class PrecioRepositoryImpl implements PrecioRepository {
  PrecioRepositoryImpl(this.dio);
  final Dio dio;
  Future<List<PrecioProducto>> list() => _request(() async {
    final Response<Object?> response = await dio.get<Object?>(ApiPaths.precios);
    return _l(
      response.data,
    ).map((Object? v) => PrecioProducto.fromJson(_m(v))).toList();
  });
  Future<PrecioProducto> getById(int id) => _request(
    () async => PrecioProducto.fromJson(
      _m((await dio.get<Object?>('${ApiPaths.precios}/$id')).data),
    ),
  );
  Future<List<HistoricoPrecio>> historial(int id) => _request(
    () async => _l(
      (await dio.get<Object?>('${ApiPaths.precios}/$id/historial')).data,
    ).map((Object? v) => HistoricoPrecio.fromJson(_m(v))).toList(),
  );
  Future<void> actualizarVenta(int id, ActualizarPrecioVentaRequest request) =>
      _request(() async {
        await dio.put<Object?>(
          '${ApiPaths.precios}/$id/venta',
          data: request.toJson(),
        );
      });
}

class UsuarioRepositoryImpl implements UsuarioRepository {
  UsuarioRepositoryImpl(this.dio);
  final Dio dio;
  Future<List<Usuario>> list() => _request(
    () async => _l(
      (await dio.get<Object?>(ApiPaths.usuarios)).data,
    ).map((Object? v) => Usuario.fromJson(_m(v))).toList(),
  );
  Future<Usuario> getById(int id) => _request(
    () async => Usuario.fromJson(
      _m((await dio.get<Object?>('${ApiPaths.usuarios}/$id')).data),
    ),
  );
  Future<Usuario> me() => _request(
    () async => Usuario.fromJson(
      _m((await dio.get<Object?>(ApiPaths.currentUser)).data),
    ),
  );
  Future<Usuario> create(UsuarioRequest request) => _request(
    () async => Usuario.fromJson(
      _m(
        (await dio.post<Object?>(
          ApiPaths.usuarios,
          data: request.toJson(),
        )).data,
      ),
    ),
  );
  Future<Usuario> update(int id, UsuarioRequest request) => _request(
    () async => Usuario.fromJson(
      _m(
        (await dio.put<Object?>(
          '${ApiPaths.usuarios}/$id',
          data: request.toJson(),
        )).data,
      ),
    ),
  );
  Future<void> delete(int id) => _request(() async {
    await dio.delete<Object?>('${ApiPaths.usuarios}/$id');
  });
  Future<void> changePassword(int id, CambioPasswordRequest request) =>
      _request(() async {
        await dio.put<Object?>(
          '${ApiPaths.usuarios}/$id/password',
          data: request.toJson(),
        );
      });
}

class RolRepositoryImpl implements RolRepository {
  RolRepositoryImpl(this.dio);
  final Dio dio;
  Future<List<Rol>> list() => _request(
    () async => _l(
      (await dio.get<Object?>(ApiPaths.roles)).data,
    ).map((Object? v) => Rol.fromJson(_m(v))).toList(),
  );
  Future<Rol> getById(int id) => _request(
    () async => Rol.fromJson(
      _m((await dio.get<Object?>('${ApiPaths.roles}/$id')).data),
    ),
  );
  Future<Rol> create(RolRequest request) => _request(
    () async => Rol.fromJson(
      _m(
        (await dio.post<Object?>(ApiPaths.roles, data: request.toJson())).data,
      ),
    ),
  );
  Future<Rol> update(int id, RolRequest request) => _request(
    () async => Rol.fromJson(
      _m(
        (await dio.put<Object?>(
          '${ApiPaths.roles}/$id',
          data: request.toJson(),
        )).data,
      ),
    ),
  );
  Future<void> delete(int id) => _request(() async {
    await dio.delete<Object?>('${ApiPaths.roles}/$id');
  });
}

class CatalogoAdminRepositoryImpl implements CatalogoAdminRepository {
  CatalogoAdminRepositoryImpl(this.dio);
  final Dio dio;
  Future<List<Modulo>> modulos() => _request(
    () async => _l(
      (await dio.get<Object?>(ApiPaths.modulos)).data,
    ).map((Object? v) => Modulo.fromJson(_m(v))).toList(),
  );
  Future<List<Permiso>> permisos() => _request(
    () async => _l(
      (await dio.get<Object?>(ApiPaths.permisos)).data,
    ).map((Object? v) => Permiso.fromJson(_m(v))).toList(),
  );
}

class ReporteRepositoryImpl implements ReporteRepository {
  ReporteRepositoryImpl(this.dio);
  final Dio dio;
  Future<ReporteDashboard> dashboard() => _report(ApiPaths.reportesDashboard);
  Future<ReporteDashboard> inventario() => _report(ApiPaths.reportesInventario);
  Future<ReporteDashboard> movimientos() =>
      _report(ApiPaths.reportesMovimientos);
  Future<ReporteDashboard> _report(String path) => _request(
    () async =>
        ReporteDashboard.fromJson(_m((await dio.get<Object?>(path)).data)),
  );
  Future<List<Venta>> ventas(DateTime desde, DateTime hasta) => _request(
    () async => _l(
      (await dio.get<Object?>(
        ApiPaths.reportesVentas,
        queryParameters: <String, Object?>{
          'desde': _date(desde),
          'hasta': _date(hasta),
        },
      )).data,
    ).map((Object? v) => Venta.fromJson(_m(v))).toList(),
  );
}

String _date(DateTime date) => date.toIso8601String().substring(0, 10);

class LogRepositoryImpl implements LogRepository {
  LogRepositoryImpl(this.dio);
  final Dio dio;
  Future<LogsPage> list({
    int page = 0,
    int size = 20,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    int? usuarioId,
    String? entidad,
    String? accion,
  }) => _request(() async {
    final Map<String, Object?> q = <String, Object?>{
      'page': page,
      'size': size,
      'fechaDesde': fechaDesde == null ? null : _date(fechaDesde),
      'fechaHasta': fechaHasta == null ? null : _date(fechaHasta),
      'usuarioId': usuarioId,
      'entidad': entidad,
      'accion': accion,
    };
    q.removeWhere((String _, Object? v) => v == null || v == '');
    return LogsPage.fromJson(
      _m((await dio.get<Object?>(ApiPaths.logs, queryParameters: q)).data),
    );
  });
  Future<List<UsuarioOpcion>> usuarios() => _request(
    () async => _l(
      (await dio.get<Object?>('${ApiPaths.logs}/usuarios')).data,
    ).map((Object? v) => UsuarioOpcion.fromJson(_m(v))).toList(),
  );
  Future<LogsEliminados> deleteRange(DateTime desde, DateTime hasta) =>
      _request(
        () async => LogsEliminados.fromJson(
          _m(
            (await dio.delete<Object?>(
              ApiPaths.logs,
              queryParameters: <String, Object?>{
                'desde': _date(desde),
                'hasta': _date(hasta),
              },
            )).data,
          ),
        ),
      );
}
