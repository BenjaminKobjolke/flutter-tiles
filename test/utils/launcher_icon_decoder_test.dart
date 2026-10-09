import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tiles/src/utils/launcher_icon_decoder.dart';

void main() {
  test(
    'decodes valid base64 and returns null for empty or malformed input',
    () {
      expect(decodeLauncherIcon(null), isNull);
      expect(decodeLauncherIcon(''), isNull);
      expect(decodeLauncherIcon('not base64!'), isNull);
      expect(decodeLauncherIcon('AQID'), Uint8List.fromList([1, 2, 3]));
    },
  );
}
