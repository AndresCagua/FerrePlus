import 'package:flutter_test/flutter_test.dart';

import 'package:ferreplus/data/offline/payload_codec.dart';
import 'package:ferreplus/domain/models/offline_models.dart' as domain;

void main() {
  test('serializa enums offline con los valores del contrato', () {
    expect(domain.OfflineOperationType.saleVoid.value, 'sale_void');
    expect(domain.PendingOperationStatus.authRequired.value, 'auth_required');
    expect(
      domain.PendingOperationStatusCodec.parse('failed'),
      domain.PendingOperationStatus.failed,
    );
  });

  test('canonicaliza JSON de forma determinista', () {
    expect(
      PayloadCodec.canonicalizeJson(<String, Object?>{
        'z': 1,
        'a': <String, Object?>{'b': 2, 'a': 1},
      }),
      <String, Object?>{
        'a': <String, Object?>{'a': 1, 'b': 2},
        'z': 1,
      },
    );
  });
}
