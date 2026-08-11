import 'package:flutter/material.dart';

ImageProvider<Object> imageProviderForUri(Uri uri) {
  return NetworkImage(uri.toString());
}
