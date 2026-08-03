import 'dart:io';

import 'package:flutter/services.dart';

typedef SystemPlayerFavoriteChanged =
    Future<bool> Function({
      required int trackId,
      required bool shouldBeFavorite,
    });

const _systemPlayerFavoriteChannel = MethodChannel(
  'esketit_music_app/system_player_favorite',
);

Future<void> initializeSystemPlayerFavorite(
  SystemPlayerFavoriteChanged onFavoriteChanged,
) async {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  _systemPlayerFavoriteChannel.setMethodCallHandler((call) async {
    if (call.method != 'favoriteChanged') {
      throw MissingPluginException('Unknown method ${call.method}');
    }

    final arguments = call.arguments as Map<Object?, Object?>?;
    final trackId = arguments?['trackId'] as int?;
    final shouldBeFavorite = arguments?['shouldBeFavorite'] as bool?;
    if (trackId == null || shouldBeFavorite == null) {
      return false;
    }

    return onFavoriteChanged(
      trackId: trackId,
      shouldBeFavorite: shouldBeFavorite,
    );
  });
}

Future<void> updateSystemPlayerFavorite({
  required int? trackId,
  required bool isAvailable,
  required bool isFavorite,
  required bool isPending,
  required String localizedTitle,
}) async {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  await _systemPlayerFavoriteChannel.invokeMethod<void>('update', {
    'trackId': trackId,
    'isAvailable': isAvailable,
    'isFavorite': isFavorite,
    'isPending': isPending,
    'localizedTitle': localizedTitle,
  });
}

Future<void> disposeSystemPlayerFavorite() async {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  await _systemPlayerFavoriteChannel.invokeMethod<void>('dispose');
  _systemPlayerFavoriteChannel.setMethodCallHandler(null);
}
