import 'package:flutter/material.dart';

Widget buildLocalImage({
  required String path,
  required BoxFit fit,
  required ImageErrorWidgetBuilder errorBuilder,
}) {
  return errorBuilder(
    const SizedBox.shrink().createElement(),
    UnsupportedError('Local images are unavailable on this platform'),
    null,
  );
}
