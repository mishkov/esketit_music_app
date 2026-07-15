import 'dart:typed_data';

import 'album_cover_average_color_calculator_stub.dart'
    if (dart.library.js_interop) 'album_cover_average_color_calculator_web.dart'
    if (dart.library.io) 'album_cover_average_color_calculator_native.dart';

Future<int?> calculateAverageRgbValue(Uint8List rgbaPixels) {
  return calculatePlatformAverageRgbValue(rgbaPixels);
}
