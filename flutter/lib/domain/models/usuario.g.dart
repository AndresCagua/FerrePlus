// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Usuario _$UsuarioFromJson(Map<String, dynamic> json) => _Usuario(
  id: (json['id'] as num).toInt(),
  nombre: json['nombre'] as String,
  email: json['email'] as String,
  telefono: json['telefono'] as String?,
  activo: json['activo'] as bool? ?? true,
  rolId: (json['rolId'] as num?)?.toInt(),
  rolNombre: json['rolNombre'] as String?,
  permisos:
      (json['permisos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
);

Map<String, dynamic> _$UsuarioToJson(_Usuario instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'email': instance.email,
  'telefono': instance.telefono,
  'activo': instance.activo,
  'rolId': instance.rolId,
  'rolNombre': instance.rolNombre,
  'permisos': instance.permisos,
};
