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

Future<void> initializeSystemPlayerFavorite(
  SystemPlayerFavoriteChanged onFavoriteChanged,
  SystemPlayerDislikeChanged onDislikeChanged,
) async {}

Future<void> updateSystemPlayerFavorite({
  required int? trackId,
  required bool isAvailable,
  required bool isFavorite,
  required bool isDisliked,
  required bool isPending,
  required String localizedFavoriteTitle,
  required String localizedDislikeTitle,
}) async {}

Future<void> disposeSystemPlayerFavorite() async {}
