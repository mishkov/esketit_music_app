import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/bottom_navigation_bar/esketit_bottom_navigation_bar.dart';
import 'package:esketit_music_app/ui/catalog/catalog_browse_screen.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen.dart';
import 'package:esketit_music_app/ui/drawer/esketit_drawer.dart';
import 'package:esketit_music_app/ui/library/my_library_page.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _browseTabIndex = 0;
  static const int _searchTabIndex = 1;
  static const int _libraryTabIndex = 2;

  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onAuthStateChanged,
        ),
        BlocListener<PlaylistsBloc, PlaylistsState>(
          listenWhen: (previous, current) =>
              previous.feedbackSerial != current.feedbackSerial &&
              current.feedbackMessage != null,
          listener: _onPlaylistsStateChanged,
        ),
      ],
      child: ScreenSkeleton(
        appBar: AppBar(title: Text(_titleForIndex(_currentTabIndex))),
        drawer: const EsketitDrawer(),
        bottomNavigationBar: EsketitBottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onTabSelected,
        ),
        body: [
          const CatalogBrowseScreen(),
          const CatalogScreen(),
          const MyLibraryPage(),
        ][_currentTabIndex],
      ),
    );
  }

  void _onTabSelected(int index) {
    if (index == _libraryTabIndex &&
        !context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    setState(() {
      _currentTabIndex = index;
    });

    if (index == _libraryTabIndex) {
      context.read<PlaylistsBloc>().add(const LoadPlaylists());
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!state.isAuthenticated) {
      context.read<PlaylistsBloc>().add(const ClearPlaylists());
      if (_currentTabIndex == _libraryTabIndex) {
        setState(() {
          _currentTabIndex = _browseTabIndex;
        });
      }

      return;
    }

    if (_currentTabIndex == _libraryTabIndex) {
      context.read<PlaylistsBloc>().add(const LoadPlaylists());
    }
  }

  void _onPlaylistsStateChanged(BuildContext context, PlaylistsState state) {
    final message = state.feedbackMessage;
    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: state.isFeedbackError
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }

  String _titleForIndex(int index) {
    final l10n = context.l10n;

    return switch (index) {
      _browseTabIndex => l10n.catalogTitle,
      _searchTabIndex => l10n.searchTitle,
      _libraryTabIndex => l10n.myLibraryTitle,
      _ => l10n.catalogTitle,
    };
  }
}
