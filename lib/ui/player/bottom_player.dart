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
        color: Theme.of(context).colorScheme.primaryContainer,
        child: ClipRRect(
          borderRadius: BorderRadiusGeometry.circular(16),
          child: BlocBuilder<PlayerBloc, PlayerState>(
            builder: (context, state) {
              return Row(
                children: [
                  if (state.selectedTrack?.image is HttpFile)
                    SizedBox.square(
                      dimension: 48,
                      child: Image.network(
                        (state.selectedTrack!.image as HttpFile).uri.toString(),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TODO: translate error messages.
                        Text(state.selectedTrack?.name ?? 'error'),
                        Text(
                          state.selectedTrack?.authors
                                  .map((author) => author.currentName)
                                  .join(', ') ??
                              'error',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<PlayerBloc>().add(TogglePlay());
                    },
                    icon: Icon(
                      state.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
