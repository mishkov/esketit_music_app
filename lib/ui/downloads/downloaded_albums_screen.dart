import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/download_routes.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_album_tile.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedAlbumsScreen extends StatelessWidget {
  const DownloadedAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTrackExists = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.selectedTrack != null,
    );

    return ScreenSkeleton(
      appBar: AppBar(title: Text(context.l10n.downloadedAlbumsTitle)),
      body: BlocBuilder<DownloadsBloc, DownloadsState>(
        buildWhen: (previous, current) =>
            previous.availability != current.availability ||
            previous.library != current.library,
        builder: (context, state) {
          if (state.availability == DownloadsAvailability.starting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!state.isSupported) {
            return Center(
              child: Text(context.l10n.downloadsUnavailableMessage),
            );
          }

          final albums = state.library.albums;
          if (albums.isEmpty) {
            return Center(child: Text(context.l10n.noDownloadedAlbumsMessage));
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              selectedTrackExists ? 100 : 16,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              final trackCount = state.library.tracks
                  .where(
                    (track) =>
                        track.albumId == album.id ||
                        album.trackIds.contains(track.id),
                  )
                  .length;

              return DownloadedAlbumTile(
                key: ValueKey(album.id),
                album: album,
                trackCount: trackCount,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(downloadedAlbumDetailsRoutePath(album.id)),
              );
            },
          );
        },
      ),
    );
  }
}
