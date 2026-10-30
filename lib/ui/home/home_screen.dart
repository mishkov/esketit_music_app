import 'package:esketit_music_app/ui/agent/agent_access_scope.dart';
import 'package:esketit_music_app/ui/agent/agent_inbox_screen.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/bottom_navigation_bar/esketit_bottom_navigation_bar.dart';
import 'package:esketit_music_app/ui/catalog/catalog_browse_screen.dart';
import 'package:esketit_music_app/ui/catalog/catalog_screen.dart';
import 'package:esketit_music_app/ui/drawer/esketit_drawer.dart';
import 'package:esketit_music_app/ui/downloads/download_routes.dart';
import 'package:esketit_music_app/ui/downloads/download_status_banner.dart';
import 'package:esketit_music_app/ui/library/my_library_page.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/downloads/bloc/downloads_bloc.dart';
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

  static const int _agentTabIndex = 3;

  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final agentAllowed = AgentAccessScope.of(context);
    final tabOrder = [
      _browseTabIndex,
      _searchTabIndex,
      if (agentAllowed) _agentTabIndex,
      _libraryTabIndex,
    ];
    final selectedTabIndex = tabOrder.contains(_currentTabIndex)
        ? _currentTabIndex
        : _browseTabIndex;

    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous.status != current.status,
          listener: _onAuthStateChanged,
        ),
        BlocListener<PlaylistsBloc, PlaylistsState>(
          listenWhen: (previous, current) =>
              previous.feedbackSerial != current.feedbackSerial &&
              (current.feedbackMessage != null ||
                  current.feedbackReason != null),
          listener: _onPlaylistsStateChanged,
        ),
      ],
      child: ScreenSkeleton(
        appBar: AppBar(title: Text(_titleForIndex(selectedTabIndex))),
        drawer: const EsketitDrawer(),
        bottomNavigationBar: EsketitBottomNavigationBar(
          currentIndex: tabOrder.indexOf(selectedTabIndex),
          showAgent: agentAllowed,
          onTap: (index) => _onTabSelected(tabOrder[index]),
        ),
        body: Column(
          children: [
            BlocBuilder<DownloadsBloc, DownloadsState>(
              buildWhen: (previous, current) =>
                  previous.availability != current.availability ||
                  previous.queue != current.queue,
              builder: (context, downloadsState) {
                if (!downloadsState.isReady) {
                  return const SizedBox.shrink();
                }

                return DownloadStatusBanner(
                  queue: downloadsState.queue,
                  onOpen: () =>
                      Navigator.of(context).pushNamed(downloadManagerRoutePath),
                  onClearFailures: () => context.read<DownloadsBloc>().add(
                    const ClearDownloadFailuresRequested(),
                  ),
                );
              },
            ),
            Expanded(
              child: [
                const CatalogBrowseScreen(),
                const CatalogScreen(),
                const MyLibraryPage(),
                const AgentInboxScreen(),
              ][selectedTabIndex],
            ),
          ],
        ),
      ),
    );
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    if (index == _libraryTabIndex &&
        context.read<AuthBloc>().state.isAuthenticated) {
      context.read<PlaylistsBloc>().add(const LoadPlaylists());
    }
  }

  void _onAuthStateChanged(BuildContext context, AuthState state) {
    if (!state.isAuthenticated) {
      context.read<PlaylistsBloc>().add(const ClearPlaylists());

      return;
    }

    if (_currentTabIndex == _libraryTabIndex) {
      context.read<PlaylistsBloc>().add(const LoadPlaylists());
    }
  }

  void _onPlaylistsStateChanged(BuildContext context, PlaylistsState state) {
    final message = switch (state.feedbackReason) {
      PlaylistsFeedbackReason.favoriteUpdateFailed =>
        context.l10n.favoriteUpdateFailed,
      PlaylistsFeedbackReason.dislikeUpdateFailed =>
        context.l10n.dislikeUpdateFailed,
      null => state.feedbackMessage,
    };
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
      _agentTabIndex => l10n.agentTitle,
      _ => l10n.catalogTitle,
    };
  }
}
