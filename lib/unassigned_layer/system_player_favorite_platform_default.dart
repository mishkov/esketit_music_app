import 'dart:io';

import 'package:flutter/services.dart';

typedef SystemPlayerFavoriteChanged =
    Future<bool> Function({
      required int trackId,
      required bool shouldBeFavorite,
    });

typedef SystemPlayerDislikeChanged =
    Future<bool> Function({
      required int trackId,
      required bool shouldBeDisliked,
    });

const _systemPlayerFavoriteChannel = MethodChannel(
  'esketit_music_app/system_player_favorite',
);

Future<void> initializeSystemPlayerFavorite(
  SystemPlayerFavoriteChanged onFavoriteChanged,
  SystemPlayerDislikeChanged onDislikeChanged,
) async {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  _systemPlayerFavoriteChannel.setMethodCallHandler((call) async {
    final arguments = call.arguments as Map<Object?, Object?>?;
    final trackId = arguments?['trackId'] as int?;
    if (trackId == null) {
      return false;
    }

    return switch (call.method) {
      'favoriteChanged' => switch (arguments?['shouldBeFavorite']) {
        final bool shouldBeFavorite => onFavoriteChanged(
          trackId: trackId,
          shouldBeFavorite: shouldBeFavorite,
        ),
        _ => false,
      },
      'dislikeChanged' => switch (arguments?['shouldBeDisliked']) {
        final bool shouldBeDisliked => onDislikeChanged(
          trackId: trackId,
          shouldBeDisliked: shouldBeDisliked,
        ),
        _ => false,
      },
      _ => throw MissingPluginException('Unknown method ${call.method}'),
    };
  });
}

Future<void> updateSystemPlayerFavorite({
  required int? trackId,
  required bool isAvailable,
  required bool isFavorite,
  required bool isDisliked,
  required bool isPending,
  required String localizedFavoriteTitle,
  required String localizedDislikeTitle,
}) async {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  await _systemPlayerFavoriteChannel.invokeMethod<void>('update', {
    'trackId': trackId,
    'isAvailable': isAvailable,
    'isFavorite': isFavorite,
    'isDisliked': isDisliked,
    'isPending': isPending,
    'localizedFavoriteTitle': localizedFavoriteTitle,
    'localizedDislikeTitle': localizedDislikeTitle,
  });
}

Future<void> disposeSystemPlayerFavorite() async {
  if (!Platform.isIOS && !Platform.isMacOS) {
    return;
  }

  await _systemPlayerFavoriteChannel.invokeMethod<void>('dispose');
  _systemPlayerFavoriteChannel.setMethodCallHandler(null);
}
