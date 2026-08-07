import 'dart:async';

import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/unassigned_layer/system_player_favorite_platform.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SystemPlayerFavoriteSynchronizer extends StatefulWidget {
  const SystemPlayerFavoriteSynchronizer({required this.child, super.key});

  final Widget child;

  @override
  State<SystemPlayerFavoriteSynchronizer> createState() =>
      _SystemPlayerFavoriteSynchronizerState();
}

class _SystemPlayerFavoriteSynchronizerState
    extends State<SystemPlayerFavoriteSynchronizer> {
  StreamSubscription<PlayerState>? _playerSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlaylistsState>? _playlistsSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  PlayerBloc? _playerBloc;
  PlaylistsBloc? _playlistsBloc;
  AuthBloc? _authBloc;
  ErrorReporter? _errorReporter;
  bool? _lastPlayerIsPlaying;
  bool _hasRefreshedAfterSystemPlayerActivation = false;
  ({
    int? trackId,
    bool isAvailable,
    bool isFavorite,
    bool isDisliked,
    bool isPending,
    String localizedFavoriteTitle,
    String localizedDislikeTitle,
  })?
  _lastConfiguration;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _errorReporter = context.read<ErrorReporter>();
    _subscribeToPlayerBloc(context.read<PlayerBloc>());
    _subscribeToPlaylistsBloc(context.read<PlaylistsBloc>());
    _subscribeToAuthBloc(context.read<AuthBloc>());
    _synchronizePlatform();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    unawaited(_playerSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_playlistsSubscription?.cancel());
    unawaited(_authSubscription?.cancel());
    unawaited(disposeSystemPlayerFavorite());
    super.dispose();
  }

  void _subscribeToPlayerBloc(PlayerBloc playerBloc) {
    if (_playerBloc == playerBloc) {
      return;
    }

    unawaited(_playerSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    _playerBloc = playerBloc;
    _hasRefreshedAfterSystemPlayerActivation = false;
    _playerSubscription = playerBloc.stream.listen((_) {
      _synchronizePlatform();
    });
    _positionSubscription = playerBloc.positionStream.listen((position) {
      if (_hasRefreshedAfterSystemPlayerActivation ||
          position <= Duration.zero ||
          !playerBloc.state.isPlaying ||
          playerBloc.state.selectedTrack == null) {
        return;
      }

      // audio_service activates the Apple command center on first playback
      // and disables feedback commands while doing so. Once playback advances,
      // reapply the preference configuration after that activation has completed.
      _hasRefreshedAfterSystemPlayerActivation = true;
      _lastConfiguration = null;
      _synchronizePlatform();
    });
  }

  void _subscribeToPlaylistsBloc(PlaylistsBloc playlistsBloc) {
    if (_playlistsBloc == playlistsBloc) {
      return;
    }

    unawaited(_playlistsSubscription?.cancel());
    _playlistsBloc = playlistsBloc;
    _playlistsSubscription = playlistsBloc.stream.listen((_) {
      _synchronizePlatform();
    });
  }

  void _subscribeToAuthBloc(AuthBloc authBloc) {
    if (_authBloc == authBloc) {
      return;
    }

    unawaited(_authSubscription?.cancel());
    _authBloc = authBloc;
    _authSubscription = authBloc.stream.listen((_) {
      _synchronizePlatform();
    });
    unawaited(
      initializeSystemPlayerFavorite(_onFavoriteChanged, _onDislikeChanged),
    );
  }

  void _synchronizePlatform() {
    if (!mounted ||
        _playerBloc == null ||
        _playlistsBloc == null ||
        _authBloc == null) {
      return;
    }

    final playerState = _playerBloc!.state;
    final track = playerState.selectedTrack;
    final playlistsState = _playlistsBloc!.state;
    final isFavorite = track == null
        ? false
        : playlistsState.effectiveIsFavorite(track);
    final isDisliked = track == null
        ? false
        : playlistsState.effectiveIsDisliked(track);
    final configuration = (
      trackId: track?.id,
      isAvailable: track != null && _authBloc!.state.isAuthenticated,
      isFavorite: isFavorite,
      isDisliked: isDisliked,
      isPending:
          track != null && playlistsState.isTrackPreferencePending(track.id),
      localizedFavoriteTitle: isFavorite
          ? context.l10n.removeFromFavoritesTooltip
          : context.l10n.addToFavoritesTooltip,
      localizedDislikeTitle: isDisliked
          ? context.l10n.removeFromDislikesTooltip
          : context.l10n.addToDislikesTooltip,
    );
    final playbackStateChanged = _lastPlayerIsPlaying != playerState.isPlaying;
    _lastPlayerIsPlaying = playerState.isPlaying;
    if (_lastConfiguration == configuration && !playbackStateChanged) {
      return;
    }

    _lastConfiguration = configuration;
    unawaited(_updatePlatform(configuration));
  }

  Future<void> _updatePlatform(
    ({
      int? trackId,
      bool isAvailable,
      bool isFavorite,
      bool isDisliked,
      bool isPending,
      String localizedFavoriteTitle,
      String localizedDislikeTitle,
    })
    configuration,
  ) async {
    try {
      await updateSystemPlayerFavorite(
        trackId: configuration.trackId,
        isAvailable: configuration.isAvailable,
        isFavorite: configuration.isFavorite,
        isDisliked: configuration.isDisliked,
        isPending: configuration.isPending,
        localizedFavoriteTitle: configuration.localizedFavoriteTitle,
        localizedDislikeTitle: configuration.localizedDislikeTitle,
      );
    } catch (error, stackTrace) {
      await _errorReporter?.reportError(
        AppError(
          'Failed to synchronize the system player preference controls',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Future<bool> _onFavoriteChanged({
    required int trackId,
    required bool shouldBeFavorite,
  }) async {
    if (!mounted ||
        _playerBloc?.state.selectedTrack?.id != trackId ||
        !(_authBloc?.state.isAuthenticated ?? false) ||
        (_playlistsBloc?.state.isTrackPreferencePending(trackId) ?? true)) {
      return false;
    }

    final track = _playerBloc!.state.selectedTrack!;
    final isFavorite = _playlistsBloc!.state.effectiveIsFavorite(track);
    if (isFavorite == shouldBeFavorite) {
      return true;
    }

    _playlistsBloc!.add(
      ToggleFavoriteRequested(
        trackId: trackId,
        shouldBeFavorite: shouldBeFavorite,
        currentIsDisliked: _playlistsBloc!.state.effectiveIsDisliked(track),
      ),
    );
    unawaited(
      _errorReporter?.addBreadcrumb(
        Breadcrumb(
          message: 'Toggle favorite from the Apple system player',
          category: Category.uiClick,
          data: {'trackId': trackId, 'shouldBeFavorite': shouldBeFavorite},
        ),
      ),
    );

    return true;
  }

  Future<bool> _onDislikeChanged({
    required int trackId,
    required bool shouldBeDisliked,
  }) async {
    if (!mounted ||
        _playerBloc?.state.selectedTrack?.id != trackId ||
        !(_authBloc?.state.isAuthenticated ?? false) ||
        (_playlistsBloc?.state.isTrackPreferencePending(trackId) ?? true)) {
      return false;
    }

    final track = _playerBloc!.state.selectedTrack!;
    final isDisliked = _playlistsBloc!.state.effectiveIsDisliked(track);
    if (isDisliked == shouldBeDisliked) {
      return true;
    }

    _playlistsBloc!.add(
      ToggleDislikeRequested(
        trackId: trackId,
        shouldBeDisliked: shouldBeDisliked,
        sourceWasPlaying: _playerBloc!.state.isPlaying,
      ),
    );
    unawaited(
      _errorReporter?.addBreadcrumb(
        Breadcrumb(
          message: 'Toggle dislike from the Apple system player',
          category: Category.uiClick,
          data: {'trackId': trackId, 'shouldBeDisliked': shouldBeDisliked},
        ),
      ),
    );

    return true;
  }
}
