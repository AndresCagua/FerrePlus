import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PayloadCodec {
  PayloadCodec({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const String _keyName = 'ferreplus_offline_key';
  final FlutterSecureStorage _storage;
  final AesGcm _cipher = AesGcm.with256bits();

  Future<String> encryptPayload(Map<String, Object?> payload) async {
    final SecretKey key = await _key();
    final List<int> nonce = _cipher.newNonce();
    final SecretBox box = await _cipher.encrypt(
      utf8.encode(jsonEncode(canonicalizeJson(payload))),
      secretKey: key,
      nonce: nonce,
    );
    return base64UrlEncode(<int>[
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  Future<Map<String, Object?>> decryptPayload(String encoded) async {
    final List<int> bytes = base64Url.decode(encoded);
    final SecretBox box = SecretBox(
      bytes.sublist(12, bytes.length - 16),
      nonce: bytes.sublist(0, 12),
      mac: Mac(bytes.sublist(bytes.length - 16)),
    );
    final SecretKey key = await _key();
    final String decoded = utf8.decode(
      await _cipher.decrypt(box, secretKey: key),
    );
    return Map<String, Object?>.from(
      jsonDecode(decoded) as Map<Object?, Object?>,
    );
  }

  Future<Map<String, Object?>> decryptOrDecode(String value) async {
    try {
      return await decryptPayload(value);
    } catch (_) {
      return Map<String, Object?>.from(
        jsonDecode(value) as Map<Object?, Object?>,
      );
    }
  }

  Future<SecretKey> _key() async {
    final String? stored = await _storage.read(key: _keyName);
    if (stored != null) return SecretKey(base64Url.decode(stored));
    final SecretKey key = await _cipher.newSecretKey();
    final List<int> bytes = await key.extractBytes();
    await _storage.write(key: _keyName, value: base64UrlEncode(bytes));
    return key;
  }

  static Object? canonicalizeJson(Object? value) {
    if (value is Map<Object?, Object?>) {
      final List<String> keys =
          value.keys.map((Object? key) => key! as String).toList()..sort();
      return <String, Object?>{
        for (final String key in keys) key: canonicalizeJson(value[key]),
      };
    }
    if (value is List<Object?>) {
      return value.map(canonicalizeJson).toList(growable: false);
    }
    return value;
  }

  static String sanitizeError(Object error) {
    final String message = error.toString();
    final String sanitized = message
        .replaceAll(
          RegExp(
            r'(authorization|token|password|body|headers)\s*[:=][^,; ]+',
            caseSensitive: false,
          ),
          '[redacted]',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.length > 240 ? sanitized.substring(0, 240) : sanitized;
  }
}

Map<String, Object?> canonicalizeJson(Map<String, Object?> value) =>
    Map<String, Object?>.from(
      PayloadCodec.canonicalizeJson(value)! as Map<Object?, Object?>,
    );

String sanitizeError(Object error) => PayloadCodec.sanitizeError(error);
