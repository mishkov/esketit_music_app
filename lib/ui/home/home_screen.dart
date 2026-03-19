import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/bottom_navigation_bar/esketit_bottom_navigation_bar.dart';
import 'package:esketit_music_app/ui/drawer/esketit_drawer.dart';
import 'package:esketit_music_app/ui/library/my_library_screen.dart';
import 'package:esketit_music_app/ui/player/bottom_player.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
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

    context.read<CatalogBloc>().add(LoadPublishedAuthors());
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
            _AuthorsBody(selectedTrackExists: state.selectedTrack != null),
            const MyLibraryScreen(),
          ];

          return Scaffold(
            appBar: AppBar(
              title: Text(_currentTabIndex == 0 ? 'Authors' : 'My Library'),
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

class _AuthorsBody extends StatelessWidget {
  const _AuthorsBody({required this.selectedTrackExists});

  final bool selectedTrackExists;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocBuilder<CatalogBloc, CatalogState>(
          builder: (context, state) {
            if (state.isLoadingAuthors && state.authors.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.authorsErrorMessage != null && state.authors.isEmpty) {
              return Center(child: Text(state.authorsErrorMessage!));
            }

            if (state.authors.isEmpty) {
              return const Center(child: Text('No published authors yet.'));
            }

            return ListView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: selectedTrackExists ? 100 : 16,
              ),
              children: [
                Text(
                  'Featured Authors',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.authors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final author = state.authors[index];
                      return SizedBox(
                        width: 180,
                        child: _AuthorCard(author: author),
                      );
                    },
                  ),
                ),
              ],
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

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AuthorDetailsScreen(author: author),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RemoteImage(
                imageUrl: author.primaryPhotoUrl,
                icon: Icons.person_rounded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                author.currentName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
