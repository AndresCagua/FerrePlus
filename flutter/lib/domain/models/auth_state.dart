import 'package:freezed_annotation/freezed_annotation.dart';

import 'usuario.dart';

part 'auth_state.freezed.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, failure }

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    Usuario? user,
    @Default(<String>{}) Set<String> permisos,
    String? error,
  }) = _AuthState;
}
