import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/usuario.dart';

abstract interface class AuthRepository {
  Future<LoginResponse> login(LoginRequest request);
  Future<Usuario> register(String email, String password, String nombre);
  Future<Usuario> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<bool> hasPermission(String permission);
}
