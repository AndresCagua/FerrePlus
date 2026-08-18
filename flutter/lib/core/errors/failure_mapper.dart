import 'package:dio/dio.dart';

import 'failure.dart';

Failure mapDioFailure(DioException exception) {
  final int? status = exception.response?.statusCode;
  if (status == 401) {
    return const AuthFailure('Credenciales invalidas o sesion expirada.');
  }
  if (status == 400 || status == 422) {
    return const ValidationFailure('La solicitud no es valida.');
  }
  if (status != null && status >= 500) {
    return const ServerFailure('El servidor no esta disponible.');
  }
  return const NetworkFailure('No se pudo conectar con el servidor.');
}
