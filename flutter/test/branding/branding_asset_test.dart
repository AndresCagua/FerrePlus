import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FerrePlus hardware asset is the configured launcher source', () {
    final File asset = File('assets/branding/ferreplus_hardware.png');
    final File config = File('flutter_launcher_icons.yaml');
    expect(asset.existsSync(), isTrue);
    expect(asset.lengthSync(), greaterThan(100));
    expect(config.readAsStringSync(), contains('ferreplus_hardware.png'));
  });
}
