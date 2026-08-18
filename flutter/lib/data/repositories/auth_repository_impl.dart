import 'package:dio/dio.dart';

import '../../core/constants/api_paths.dart';
import '../../core/errors/failure.dart';
import '../../core/errors/failure_mapper.dart';
import '../../domain/models/login_request.dart';
import '../../domain/models/login_response.dart';
import '../../domain/models/usuario.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required Dio dio, required TokenStorage storage})
    : _dio = dio,
      _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final Response<Object?> response = await _dio.post<Object?>(
        ApiPaths.login,
        data: request.toJson(),
      );
      final Map<String, Object?> json = Map<String, Object?>.from(
        response.data! as Map<Object?, Object?>,
      );
      final LoginResponse result = LoginResponse.fromJson(json);
      if (result.token.isEmpty) {
        throw const AuthFailure('Respuesta de autenticacion incompleta.');
      }
      await _storage.saveSession(result);
      return result;
    } on DioException catch (exception) {
      throw mapDioFailure(exception);
    }
  }

  @override
  Future<Usuario> register(String email, String password, String nombre) async {
    try {
      final Response<Object?> response = await _dio.post<Object?>(
        ApiPaths.register,
        data: <String, Object?>{
          'nombre': nombre,
          'email': email,
          'password': password,
        },
      );
      final Map<String, Object?> json = Map<String, Object?>.from(
        response.data! as Map<Object?, Object?>,
      );
      return Usuario.fromJson(json);
    } on DioException catch (exception) {
      if (exception.response?.statusCode == 400 ||
          exception.response?.statusCode == 409) {
        throw const ValidationFailure(
          'El registro inicial no esta disponible: ya existen usuarios o los datos no son validos.',
        );
      }
      throw mapDioFailure(exception);
    }
  }

  @override
  Future<Usuario> getCurrentUser() async {
    try {
      final Response<Object?> response = await _dio.get<Object?>(
        ApiPaths.currentUser,
      );
      final Usuario user = Usuario.fromJson(
        Map<String, Object?>.from(response.data! as Map<Object?, Object?>),
      );
      final String? token = await _storage.readToken();
      if (token == null || token.isEmpty) {
        throw const AuthFailure('Sesion invalida.');
      }
      await _storage.saveSession(
        LoginResponse(
          token: token,
          email: user.email,
          nombre: user.nombre,
          usuarioId: user.id,
          permisos: user.permisos,
        ),
      );
      return user;
    } on DioException catch (exception) {
      throw mapDioFailure(exception);
    }
  }

  @override
  Future<void> logout() => _storage.clear();

  @override
  Future<bool> isAuthenticated() async =>
      (await _storage.readToken())?.isNotEmpty ?? false;

  @override
  Future<bool> hasPermission(String permission) async =>
      (await _storage.readPermissions()).contains(permission);
}
