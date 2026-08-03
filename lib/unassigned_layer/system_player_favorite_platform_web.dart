typedef SystemPlayerFavoriteChanged =
    Future<bool> Function({
      required int trackId,
      required bool shouldBeFavorite,
    });

Future<void> initializeSystemPlayerFavorite(
  SystemPlayerFavoriteChanged onFavoriteChanged,
) async {}

Future<void> updateSystemPlayerFavorite({
  required int? trackId,
  required bool isAvailable,
  required bool isFavorite,
  required bool isPending,
  required String localizedTitle,
}) async {}

Future<void> disposeSystemPlayerFavorite() async {}
