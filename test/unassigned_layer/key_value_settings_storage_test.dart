import 'package:esketit_music_app/unassigned_layer/key_value_settings_storage.dart';
import 'package:esketit_music_app/unassigned_layer/shared_preferences_key_value_storage.dart';
import 'package:esketit_music_app/use_case/settings/author_albums_display_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('KeyValueSettingsStorage', () {
    test('returns null when author albums display mode is missing', () async {
      final testStorage = await _createStorage();

      expect(await testStorage.storage.getAuthorAlbumsDisplayMode(), isNull);
    });

    test('returns null when author albums display mode is unknown', () async {
      final testStorage = await _createStorage();

      await testStorage.preferences.setString(
        'settings.author_albums_display_mode',
        'obsolete',
      );

      expect(await testStorage.storage.getAuthorAlbumsDisplayMode(), isNull);
    });

    test('saves and reads author albums display mode', () async {
      final testStorage = await _createStorage();

      await testStorage.storage.setAuthorAlbumsDisplayMode(
        AuthorAlbumsDisplayMode.compact,
      );

      expect(
        await testStorage.storage.getAuthorAlbumsDisplayMode(),
        AuthorAlbumsDisplayMode.compact,
      );

      await testStorage.storage.setAuthorAlbumsDisplayMode(
        AuthorAlbumsDisplayMode.expanded,
      );

      expect(
        await testStorage.storage.getAuthorAlbumsDisplayMode(),
        AuthorAlbumsDisplayMode.expanded,
      );
    });

    test(
      'returns null when track album cover color scheme seed setting is missing',
      () async {
        final testStorage = await _createStorage();

        expect(
          await testStorage.storage.getUseTrackAlbumCoverColorSchemeSeed(),
          isNull,
        );
      },
    );

    test(
      'returns null when track album cover color scheme seed setting is unknown',
      () async {
        final testStorage = await _createStorage();

        await testStorage.preferences.setString(
          'settings.use_track_album_cover_color_scheme_seed',
          'obsolete',
        );

        expect(
          await testStorage.storage.getUseTrackAlbumCoverColorSchemeSeed(),
          isNull,
        );
      },
    );

    test(
      'saves and reads track album cover color scheme seed setting',
      () async {
        final testStorage = await _createStorage();

        await testStorage.storage.setUseTrackAlbumCoverColorSchemeSeed(false);

        expect(
          await testStorage.storage.getUseTrackAlbumCoverColorSchemeSeed(),
          isFalse,
        );

        await testStorage.storage.setUseTrackAlbumCoverColorSchemeSeed(true);

        expect(
          await testStorage.storage.getUseTrackAlbumCoverColorSchemeSeed(),
          isTrue,
        );
      },
    );
  });
}

Future<({SharedPreferences preferences, KeyValueSettingsStorage storage})>
_createStorage() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final storage = KeyValueSettingsStorage(
    keyValueStorage: SharedPreferencesKeyValueStorage(preferences: preferences),
  );

  return (preferences: preferences, storage: storage);
}
