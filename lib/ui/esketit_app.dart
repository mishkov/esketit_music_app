import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/app_shell.dart';
import 'package:esketit_music_app/ui/playlists/shareable_playlist_details_screen.dart';
import 'package:esketit_music_app/ui/theme/album_cover_color_scheme_seed_builder.dart';
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
    if (image is! HttpFile) {
      return null;
    }

    return image.uri.toString().isEmpty ? null : image.uri;
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
