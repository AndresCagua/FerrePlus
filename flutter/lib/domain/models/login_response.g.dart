// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    _LoginResponse(
      token: json['token'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: json['rol'] as String?,
      usuarioId: (json['usuarioId'] as num).toInt(),
      permisos:
          (json['permisos'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$LoginResponseToJson(_LoginResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'email': instance.email,
      'nombre': instance.nombre,
      'rol': instance.rol,
      'usuarioId': instance.usuarioId,
      'permisos': instance.permisos,
    };
