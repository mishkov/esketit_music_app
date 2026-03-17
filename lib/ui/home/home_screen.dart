import 'package:esketit_music_app/ui/bottom_navigation_bar/esketit_bottom_navigation_bar.dart';
import 'package:esketit_music_app/ui/drawer/esketit_drawer.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_list/bloc/tracks_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    context.read<TracksListBloc>().add(LoadMoreTracks());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        return Scaffold(
          // TODO; localize the title
          appBar: AppBar(title: Text('Tracks')),
          drawer: EsketitDrawer(),
          bottomNavigationBar: EsketitBottomNavigationBar(),
          body: Stack(
            children: [
              BlocBuilder<TracksListBloc, TracksListState>(
                builder: (context, state) {
                  return ListView.separated(
                    itemCount: state.tracks.length,
                    separatorBuilder: (context, index) => SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final track = state.tracks[index].data;
                      return Card.outlined(
                        child: ListTile(
                          onTap: () {
                            context.read<PlayerBloc>().add(PlayTrack(track));
                          },
                          title: Text(track.name),
                          subtitle: Text(
                            track.authors
                                .map((author) => author.currentName)
                                .join(', '),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              if (state.selectedTrack != null)
                Positioned(bottom: 0, right: 0, left: 0, child: BottomPlayer()),
            ],
          ),
        );
      },
    );
  }
}
