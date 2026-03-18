import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/bottom_navigation_bar/esketit_bottom_navigation_bar.dart';
import 'package:esketit_music_app/ui/drawer/esketit_drawer.dart';
import 'package:esketit_music_app/ui/library/my_library_screen.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
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
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();

    context.read<TracksListBloc>().add(LoadMoreTracks());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && !current.isAuthenticated,
      listener: (context, state) {
        if (_currentTabIndex != 0) {
          setState(() {
            _currentTabIndex = 0;
          });
        }
      },
      child: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final pages = [
            _TracksListBody(selectedTrackExists: state.selectedTrack != null),
            const MyLibraryScreen(),
          ];

          return Scaffold(
            appBar: AppBar(
              title: Text(_currentTabIndex == 0 ? 'Tracks' : 'My Library'),
            ),
            drawer: const EsketitDrawer(),
            bottomNavigationBar: EsketitBottomNavigationBar(
              currentIndex: _currentTabIndex,
              onTap: _onTabSelected,
            ),
            body: pages[_currentTabIndex],
          );
        },
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index == 1 && !context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();
      return;
    }

    setState(() {
      _currentTabIndex = index;
    });
  }
}

class _TracksListBody extends StatelessWidget {
  const _TracksListBody({required this.selectedTrackExists});

  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<TracksListBloc, TracksListState>(
          builder: (context, state) {
            return ListView.separated(
              itemCount: state.tracks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
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
        // TOOD: wrap with bloc builder instead of relying on parameter.
        if (selectedTrackExists)
          const Positioned(bottom: 0, right: 0, left: 0, child: BottomPlayer()),
      ],
    );
  }
}
