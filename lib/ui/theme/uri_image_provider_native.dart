import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object> imageProviderForUri(Uri uri) {
  if (uri.scheme == 'file') {
    return FileImage(File(uri.toFilePath()));
  }

  return NetworkImage(uri.toString());
}
