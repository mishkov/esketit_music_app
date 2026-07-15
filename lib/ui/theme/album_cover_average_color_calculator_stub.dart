import 'dart:typed_data';

import 'package:esketit_music_app/ui/theme/album_cover_average_color.dart';

Future<int?> calculatePlatformAverageRgbValue(Uint8List rgbaPixels) async {
  return calculateAverageRgbValueSynchronously(rgbaPixels);
}
