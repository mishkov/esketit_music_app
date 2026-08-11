import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/downloads/download_routes.dart';
import 'package:esketit_music_app/ui/downloads/downloaded_author_tile.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DownloadedAuthorsScreen extends StatelessWidget {
  const DownloadedAuthorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTrackExists = context.select<PlayerBloc, bool>(
      (bloc) => bloc.state.selectedTrack != null,
    );

    return ScreenSkeleton(
      appBar: AppBar(title: Text(context.l10n.downloadedAuthorsTitle)),
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

          final authors = state.library.authors;
          if (authors.isEmpty) {
            return Center(child: Text(context.l10n.noDownloadedAuthorsMessage));
          }

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              selectedTrackExists ? 100 : 16,
            ),
            itemCount: authors.length,
            itemBuilder: (context, index) {
              final author = authors[index];
              final trackCount = state.library.tracks
                  .where(
                    (track) => track.authors.any(
                      (trackAuthor) => trackAuthor.id == author.id,
                    ),
                  )
                  .length;

              return DownloadedAuthorTile(
                key: ValueKey(author.id),
                author: author,
                trackCount: trackCount,
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(downloadedAuthorDetailsRoutePath(author.id)),
              );
            },
          );
        },
      ),
    );
  }
}
