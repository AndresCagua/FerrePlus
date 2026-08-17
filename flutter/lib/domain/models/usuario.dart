import 'package:freezed_annotation/freezed_annotation.dart';

part 'usuario.freezed.dart';
part 'usuario.g.dart';

@freezed
abstract class Usuario with _$Usuario {
  const factory Usuario({
    required int id,
    required String nombre,
    required String email,
    String? telefono,
    @Default(true) bool activo,
    int? rolId,
    String? rolNombre,
    @Default(<String>[]) List<String> permisos,
  }) = _Usuario;

  factory Usuario.fromJson(Map<String, Object?> json) => _$UsuarioFromJson(json);
}
