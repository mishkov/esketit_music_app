import 'dart:typed_data';

int? calculateAverageRgbValueSynchronously(Uint8List rgbaPixels) {
  var redTotal = 0;
  var greenTotal = 0;
  var blueTotal = 0;
  var alphaTotal = 0;

  for (var offset = 0; offset < rgbaPixels.length; offset += 4) {
    final alpha = rgbaPixels[offset + 3];
    if (alpha == 0) {
      continue;
    }

    redTotal += rgbaPixels[offset] * alpha;
    greenTotal += rgbaPixels[offset + 1] * alpha;
    blueTotal += rgbaPixels[offset + 2] * alpha;
    alphaTotal += alpha;
  }

  if (alphaTotal == 0) {
    return null;
  }

  final red = redTotal ~/ alphaTotal;
  final green = greenTotal ~/ alphaTotal;
  final blue = blueTotal ~/ alphaTotal;

  return red << 16 | green << 8 | blue;
}

ColorComponents colorComponentsFromRgbValue(int rgbValue) {
  return ColorComponents(
    red: rgbValue >> 16 & 0xff,
    green: rgbValue >> 8 & 0xff,
    blue: rgbValue & 0xff,
  );
}

class ColorComponents {
  const ColorComponents({
    required this.red,
    required this.green,
    required this.blue,
  });

  final int red;
  final int green;
  final int blue;
}
