import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get isFullscreenPlayerSupported => true;

Future<void> enterAppFullscreen() async {
  final documentElement = web.document.documentElement;
  if (documentElement == null || web.document.fullscreenElement != null) {
    return;
  }

  await documentElement.requestFullscreen().toDart;
}

Future<void> exitAppFullscreen() async {
  if (web.document.fullscreenElement == null) {
    return;
  }

  await web.document.exitFullscreen().toDart;
}
