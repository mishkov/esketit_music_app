import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/downloads/collection_download_button.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumDownloadAction extends StatelessWidget {
  const AlbumDownloadAction({
    required this.album,
    required this.tracks,
    super.key,
  });

  final Album album;
  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsBloc, DownloadsState>(
      buildWhen: (previous, current) =>
          previous.availability != current.availability ||
          previous.queue != current.queue ||
          previous.library.albumDownloadIds != current.library.albumDownloadIds,
      builder: (context, state) {
        if (!state.isReady || tracks.isEmpty) {
          return const SizedBox.shrink();
        }
        final status = _status(state);

        return Align(
          alignment: Alignment.centerLeft,
          child: CollectionDownloadButton(
            kind: DownloadCollectionUiKind.album,
            status: status,
            onPressed: () => _onPressed(context, status),
          ),
        );
      },
    );
  }

  CollectionDownloadUiStatus _status(DownloadsState state) {
    if (!state.library.albumDownloadIds.contains(album.id)) {
      return CollectionDownloadUiStatus.notDownloaded;
    }
    final statuses = tracks
        .map((track) => state.statusForTrack(track.id))
        .toSet();
    if (statuses.contains(TrackDownloadState.downloading)) {
      return CollectionDownloadUiStatus.downloading;
    }
    if (statuses.contains(TrackDownloadState.queued)) {
      return CollectionDownloadUiStatus.queued;
    }
    if (tracks.every((track) => state.downloadedTrackIds.contains(track.id))) {
      return CollectionDownloadUiStatus.downloaded;
    }

    return CollectionDownloadUiStatus.error;
  }

  void _onPressed(BuildContext context, CollectionDownloadUiStatus status) {
    final downloadsBloc = context.read<DownloadsBloc>();
    if (status == CollectionDownloadUiStatus.queued ||
        status == CollectionDownloadUiStatus.downloading ||
        status == CollectionDownloadUiStatus.downloaded) {
      downloadsBloc.add(RemoveAlbumDownloadRequested(album.id));

      return;
    }

    downloadsBloc.add(DownloadAlbumRequested(album: album, tracks: tracks));
  }
}
