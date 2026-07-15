import 'dart:io';

import 'package:flutter/services.dart';

const _fullscreenChannel = MethodChannel('esketit_music_app/fullscreen');

bool get isFullscreenPlayerSupported => Platform.isMacOS;

Future<void> enterAppFullscreen() async {
  if (!Platform.isMacOS) {
    return;
  }

  await _fullscreenChannel.invokeMethod<void>('enterFullscreen');
}

Future<void> exitAppFullscreen() async {
  if (!Platform.isMacOS) {
    return;
  }

  await _fullscreenChannel.invokeMethod<void>('exitFullscreen');
}
