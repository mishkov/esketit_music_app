import 'package:esketit_music_app/ui/theme/album_cover_average_color.dart';
import 'package:flutter/foundation.dart';

Future<int?> calculatePlatformAverageRgbValue(Uint8List rgbaPixels) {
  return compute(calculateAverageRgbValueSynchronously, rgbaPixels);
}
