import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_session.freezed.dart';

@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String token,
    required String email,
    required String nombre,
    String? rol,
    required int usuarioId,
    @Default(<String>[]) List<String> permisos,
  }) = _AuthSession;
}
