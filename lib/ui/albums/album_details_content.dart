import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/ui/albums/album_summary_card.dart';
import 'package:esketit_music_app/ui/albums/album_tracks_section.dart';
import 'package:esketit_music_app/ui/authors/author_desktop_layout.dart';
import 'package:esketit_music_app/ui/authors/author_mobile_layout.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:flutter/material.dart';

class AlbumDetailsContent extends StatelessWidget {
  const AlbumDetailsContent({
    required this.album,
    required this.tracks,
    required this.selectedTrackExists,
    super.key,
  });

  final Album album;
  final List<Track> tracks;
  final bool selectedTrackExists;

  static const _desktopLayoutBreakpoint = 900.0;
  static const _contentMaxWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    final tracksQueue = tracks
        .where((track) => track.isAvailable)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopLayout =
            constraints.maxWidth >= _desktopLayoutBreakpoint;

        final summary = AlbumSummaryCard(album: album);
        final tracksSection = AlbumTracksSection(
          tracks: tracks,
          tracksQueue: tracksQueue,
          autoplayContext: AutoplayContext(
            sourceType: AutoplaySourceType.album,
            sourceId: album.id,
          ),
        );

        Widget content = useDesktopLayout
            ? AuthorDesktopLayout(
                summary: summary,
                albumsSection: tracksSection,
              )
            : AuthorMobileLayout(
                summary: summary,
                albumsSection: tracksSection,
              );

        content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: content,
          ),
        );

        return ListView(
          key: PageStorageKey<int>(album.id),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: selectedTrackExists ? 100 : 16,
          ),
          children: [content],
        );
      },
    );
  }
}
