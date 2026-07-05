import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/playlists/playlist_details_body.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShareablePlaylistDetailsScreen extends StatefulWidget {
  const ShareablePlaylistDetailsScreen.public({
    required int playlistId,
    super.key,
  }) : _source = _ShareablePlaylistSource.public,
       _playlistId = playlistId,
       _shareToken = null;

  const ShareablePlaylistDetailsScreen.shared({
    required String shareToken,
    super.key,
  }) : _source = _ShareablePlaylistSource.shared,
       _playlistId = null,
       _shareToken = shareToken;

  final _ShareablePlaylistSource _source;
  final int? _playlistId;
  final String? _shareToken;

  @override
  State<ShareablePlaylistDetailsScreen> createState() =>
      _ShareablePlaylistDetailsScreenState();
}

class _ShareablePlaylistDetailsScreenState
    extends State<ShareablePlaylistDetailsScreen> {
  Future<PlaylistDetailsSnapshot>? _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = _loadDetails();
  }

  @override
  void didUpdateWidget(ShareablePlaylistDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._source != widget._source ||
        oldWidget._playlistId != widget._playlistId ||
        oldWidget._shareToken != widget._shareToken) {
      _detailsFuture = _loadDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FutureBuilder<PlaylistDetailsSnapshot>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        final details = snapshot.data;
        final playlist = details?.playlist;
        final selectedTrackExists = context.select<PlayerBloc, bool>(
          (bloc) => bloc.state.selectedTrack != null,
        );

        return ScreenSkeleton(
          appBar: AppBar(
            title: Text(playlist?.name ?? l10n.playlistFallbackTitle),
          ),
          body: switch (snapshot.connectionState) {
            ConnectionState.none || ConnectionState.waiting => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when snapshot.hasError => Center(
              child: Text(l10n.playlistNotFound),
            ),
            _ when details == null => Center(
              child: Text(l10n.playlistNotFound),
            ),
            _ => PlaylistDetailsBody(
              details: details,
              selectedTrackExists: selectedTrackExists,
            ),
          },
        );
      },
    );
  }

  Future<PlaylistDetailsSnapshot> _loadDetails() {
    final storage = context.read<ShareablePlaylistsStorage>();

    return switch (widget._source) {
      _ShareablePlaylistSource.public => storage.getPublicPlaylistDetails(
        playlistId: widget._playlistId!,
      ),
      _ShareablePlaylistSource.shared => storage.getSharedPlaylistDetails(
        shareToken: widget._shareToken!,
      ),
    };
  }
}

enum _ShareablePlaylistSource { public, shared }
