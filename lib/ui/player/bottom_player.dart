import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/tracks/track_screen.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Card.filled(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(16),
        ),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(16),
          child: BlocBuilder<PlayerBloc, PlayerState>(
            buildWhen: (previous, current) =>
                previous.selectedTrack != current.selectedTrack ||
                previous.isPlaying != current.isPlaying,
            builder: (context, state) {
              final selectedTrack = state.selectedTrack;
              final selectedTrackImageUrl = _selectedTrackImageUrl(
                selectedTrack?.image,
              );

              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: selectedTrack == null
                      ? null
                      : () => _openTrackScreen(context),
                  child: Row(
                    children: [
                      SizedBox.square(
                        dimension: 48,
                        child: _buildTrackArtwork(
                          imageUrl: selectedTrackImageUrl,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedTrack?.name ??
                                  l10n.bottomPlayerNoTrackSelected,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                            Text(
                              selectedTrack?.authors
                                      .map((author) => author.currentName)
                                      .join(', ') ??
                                  l10n.bottomPlayerUnknownArtist,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSecondaryContainer,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _togglePlay(context),
                        icon: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openTrackScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const TrackScreen()),
    );
  }

  void _togglePlay(BuildContext context) {
    context.read<PlayerBloc>().add(TogglePlay());
  }

  Widget _buildTrackArtwork({required String? imageUrl}) {
    if (imageUrl == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(imageUrl),
    );
  }

  String? _selectedTrackImageUrl(Object? image) {
    if (image is! HttpFile) {
      return null;
    }

    final imageUrl = image.uri.toString();

    return imageUrl.isEmpty ? null : imageUrl;
  }
}
