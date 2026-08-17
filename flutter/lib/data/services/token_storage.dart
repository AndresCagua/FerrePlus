import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/login_response.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  String? cachedToken;

  Future<String?> readToken() async {
    cachedToken = await _storage.read(key: AppConstants.tokenKey);
    return cachedToken;
  }

  Future<void> saveSession(LoginResponse response) async {
    cachedToken = response.token;
    await _storage.write(key: AppConstants.tokenKey, value: response.token);
    await _storage.write(key: AppConstants.emailKey, value: response.email);
    await _storage.write(key: AppConstants.nombreKey, value: response.nombre);
    await _storage.write(key: AppConstants.rolKey, value: response.rol);
    await _storage.write(
      key: AppConstants.usuarioIdKey,
      value: response.usuarioId.toString(),
    );
    await _storage.write(
      key: AppConstants.permisosKey,
      value: jsonEncode(response.permisos),
    );
  }

  Future<List<String>> readPermissions() async {
    final String? value = await _storage.read(key: AppConstants.permisosKey);
    if (value == null) return <String>[];
    final Object? decoded = jsonDecode(value);
    if (decoded is! List<Object?>) throw const FormatException('Permisos invalidos');
    return decoded.whereType<String>().toList(growable: false);
  }

  Future<void> clear() async {
    cachedToken = null;
    await _storage.deleteAll();
  }
}
