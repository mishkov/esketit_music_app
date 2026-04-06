import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Card.filled(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(16),
        ),
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(16),
          child: BlocBuilder<PlayerBloc, PlayerState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 48,
                      child:
                          // TODO: refactor this spagetti.
                          (state.selectedTrack?.image is HttpFile &&
                              ((state.selectedTrack!.image as HttpFile).uri
                                      .toString())
                                  .isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadiusGeometry.circular(12),
                              child: Image.network(
                                (state.selectedTrack!.image as HttpFile).uri
                                    .toString(),
                              ),
                            )
                          : SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TODO: translate error messages.
                          Text(
                            state.selectedTrack?.name ?? 'error',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                          ),
                          Text(
                            state.selectedTrack?.authors
                                    .map((author) => author.currentName)
                                    .join(', ') ??
                                'error',

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
              );
            },
          ),
        ),
      ),
    );
  }

  void _togglePlay(BuildContext context) {
    context.read<PlayerBloc>().add(TogglePlay());
  }
}
