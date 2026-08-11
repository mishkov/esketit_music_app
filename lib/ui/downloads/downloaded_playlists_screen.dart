import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/download_routes.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_playlist_tile.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedPlaylistsScreen extends StatelessWidget {
  const DownloadedPlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTrackExists = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.selectedTrack != null,
    );

    return ScreenSkeleton(
      appBar: AppBar(title: Text(context.l10n.downloadedPlaylistsTitle)),
      body: BlocBuilder<DownloadsBloc, DownloadsState>(
        buildWhen: (previous, current) =>
            previous.availability != current.availability ||
            previous.library.playlists != current.library.playlists,
        builder: (context, state) {
          if (state.availability == DownloadsAvailability.starting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.isSupported) {
            return Center(
              child: Text(context.l10n.downloadsUnavailableMessage),
            );
          }

          final playlists = state.library.playlists;
          if (playlists.isEmpty) {
            return Center(
              child: Text(context.l10n.noDownloadedPlaylistsMessage),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              selectedTrackExists ? 100 : 16,
            ),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];

              return DownloadedPlaylistTile(
                key: ValueKey(playlist.id),
                playlist: playlist,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(downloadedPlaylistDetailsRoutePath(playlist.id)),
              );
            },
          );
        },
      ),
    );
  }
}
