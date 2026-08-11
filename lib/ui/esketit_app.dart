import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/albums/album_details_route_screen.dart';
import 'package:esketit_music_app/ui/albums/album_routes.dart';
import 'package:esketit_music_app/ui/app_shell.dart';
import 'package:esketit_music_app/ui/authors/author_details_route_screen.dart';
import 'package:esketit_music_app/ui/authors/author_routes.dart';
import 'package:esketit_music_app/ui/downloads/download_manager_route_screen.dart';
import 'package:esketit_music_app/ui/downloads/download_routes.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_album_details_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_albums_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_author_details_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_authors_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_playlist_details_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_playlists_screen.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_tracks_screen.dart';
import 'package:esketit_music_app/ui/player/system_player_favorite_synchronizer.dart';
import 'package:esketit_music_app/ui/player/track_preference_synchronizer.dart';
import 'package:esketit_music_app/ui/playlists/shareable_playlist_details_screen.dart';
import 'package:esketit_music_app/ui/theme/album_cover_color_scheme_seed_builder.dart';
import 'package:esketit_music_app/ui/tracks/track_route_screen.dart';
import 'package:esketit_music_app/ui/tracks/track_routes.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/app_theme_mode.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EsketitApp extends StatelessWidget {
  const EsketitApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return BlocSelector<PlayerBloc, PlayerState, Uri?>(
          selector: _selectedTrackAlbumCoverUri,
          builder: (context, albumCoverUri) {
            return AlbumCoverColorSchemeSeedBuilder(
              albumCoverUri: albumCoverUri,
              enabled: state.useTrackAlbumCoverColorSchemeSeed,
              builder: (context, colorSchemeSeed) {
                return MaterialApp(
                  navigatorKey: navigatorKey,
                  locale: _toFlutterLocale(state.locale),
                  onGenerateTitle: (context) =>
                      AppLocalizations.of(context)!.appTitle,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => TrackPreferenceSynchronizer(
                    child: SystemPlayerFavoriteSynchronizer(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                  theme: ThemeData(
                    colorSchemeSeed: colorSchemeSeed,
                    useMaterial3: true,
                  ),
                  darkTheme: ThemeData(
                    colorSchemeSeed: colorSchemeSeed,
                    useMaterial3: true,
                    brightness: Brightness.dark,
                  ),
                  themeMode: _toFlutterThemeMode(state.themeMode),
                  home: const AppShell(),
                  onGenerateRoute: _onGenerateRoute,
                );
              },
            );
          },
        );
      },
    );
  }

  Uri? _selectedTrackAlbumCoverUri(PlayerState playerState) {
    final image = playerState.selectedTrack?.image;
    if (image is LocalFile) {
      return image.path.isEmpty ? null : Uri.file(image.path);
    }
    if (image is HttpFile) {
      return image.uri.toString().isEmpty ? null : image.uri;
    }

    return null;
  }

  Route<void>? _onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    if (name == null || name == Navigator.defaultRouteName) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const AppShell(),
      );
    }

    final uri = Uri.tryParse(name);
    final segments = uri?.pathSegments ?? const <String>[];

    if (name == downloadManagerRoutePath) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const DownloadManagerRouteScreen(),
      );
    }
    if (name == downloadedTracksRoutePath) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const DownloadedTracksScreen(),
      );
    }
    if (name == downloadedAuthorsRoutePath) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const DownloadedAuthorsScreen(),
      );
    }
    if (name == downloadedAlbumsRoutePath) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const DownloadedAlbumsScreen(),
      );
    }
    if (name == downloadedPlaylistsRoutePath) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => const DownloadedPlaylistsScreen(),
      );
    }

    final downloadedAuthorId = downloadedAuthorIdFromRouteName(name);
    if (downloadedAuthorId != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) =>
            DownloadedAuthorDetailsScreen(authorId: downloadedAuthorId),
      );
    }

    final downloadedAlbumId = downloadedAlbumIdFromRouteName(name);
    if (downloadedAlbumId != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) =>
            DownloadedAlbumDetailsScreen(albumId: downloadedAlbumId),
      );
    }

    final downloadedPlaylistId = downloadedPlaylistIdFromRouteName(name);
    if (downloadedPlaylistId != null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) =>
            DownloadedPlaylistDetailsScreen(playlistId: downloadedPlaylistId),
      );
    }

    final authorId = authorIdFromRouteName(name);
    if (authorId != null) {
      final argument = settings.arguments;
      final initialAuthor = argument is Author && argument.id == authorId
          ? argument
          : null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => AuthorDetailsRouteScreen(
          authorId: authorId,
          initialAuthor: initialAuthor,
        ),
      );
    }

    final albumId = albumIdFromRouteName(name);
    if (albumId != null) {
      final argument = settings.arguments;
      final initialAlbum = argument is Album && argument.id == albumId
          ? argument
          : null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => AlbumDetailsRouteScreen(
          albumId: albumId,
          initialAlbum: initialAlbum,
        ),
      );
    }

    final trackId = trackIdFromRouteName(name);
    if (trackId != null) {
      final argument = settings.arguments;
      final initialTrack = argument is Track && argument.id == trackId
          ? argument
          : null;

      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) =>
            TrackRouteScreen(trackId: trackId, initialTrack: initialTrack),
      );
    }

    if (segments.length == 2 && segments.first == 'playlists') {
      final playlistId = int.tryParse(segments[1]);
      if (playlistId != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) =>
              ShareablePlaylistDetailsScreen.public(playlistId: playlistId),
        );
      }
    }

    if (segments.length == 3 &&
        segments.first == 'playlists' &&
        segments[1] == 'shared' &&
        segments[2].isNotEmpty) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => ShareablePlaylistDetailsScreen.shared(
          shareToken: Uri.decodeComponent(segments[2]),
        ),
      );
    }

    return null;
  }

  Locale? _toFlutterLocale(AppLocale? appLocale) {
    if (appLocale == null) {
      return null;
    }

    return Locale(appLocale.languageCode);
  }

  ThemeMode _toFlutterThemeMode(AppThemeMode appThemeMode) {
    return switch (appThemeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.auto => ThemeMode.system,
    };
  }
}
