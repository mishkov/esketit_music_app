import 'package:esketit_music_app/domain/track.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/tracks/show_add_to_playlists_sheet.dart';
import 'package:esketit_music_app/ui/tracks/track_download_launcher.dart';
import 'package:esketit_music_app/use_case/playlists/bloc/playlists_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum _TrackAction {
  toggleDislike,
  addToPlaylists,
  removeFromPlaylist,
  saveToDownloads,
}

class TrackActionsMenu extends StatefulWidget {
  const TrackActionsMenu({
    required this.track,
    required this.effectiveIsDisliked,
    required this.preferencePending,
    required this.playlistsPending,
    required this.playlistIdForRemoval,
    required this.showAddToPlaylistsAction,
    required this.showSaveToDownloadsAction,
    required this.onToggleDislike,
    super.key,
  });

  final Track track;
  final bool effectiveIsDisliked;
  final bool preferencePending;
  final bool playlistsPending;
  final int? playlistIdForRemoval;
  final bool showAddToPlaylistsAction;
  final bool showSaveToDownloadsAction;
  final VoidCallback onToggleDislike;

  @override
  State<TrackActionsMenu> createState() => _TrackActionsMenuState();
}

class _TrackActionsMenuState extends State<TrackActionsMenu> {
  bool _isSavingToDownloads = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopupMenuButton<_TrackAction>(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (context) => [
        PopupMenuItem<_TrackAction>(
          value: _TrackAction.toggleDislike,
          enabled: !widget.preferencePending,
          child: Text(
            widget.effectiveIsDisliked
                ? l10n.removeFromDislikesTooltip
                : l10n.addToDislikesTooltip,
          ),
        ),
        if (widget.showAddToPlaylistsAction)
          PopupMenuItem<_TrackAction>(
            value: _TrackAction.addToPlaylists,
            enabled: !widget.playlistsPending,
            child: Text(l10n.addToPlaylistsTooltip),
          ),
        if (widget.playlistIdForRemoval != null)
          PopupMenuItem<_TrackAction>(
            value: _TrackAction.removeFromPlaylist,
            enabled: !widget.playlistsPending,
            child: Text(l10n.removeFromPlaylistTooltip),
          ),
        if (widget.showSaveToDownloadsAction &&
            canSaveTrackToDownloads(widget.track))
          PopupMenuItem<_TrackAction>(
            value: _TrackAction.saveToDownloads,
            enabled: !_isSavingToDownloads,
            child: Text(l10n.saveTrackToDownloadsTooltip),
          ),
      ],
      icon: const Icon(Icons.more_vert_rounded),
    );
  }

  Future<void> _onSelected(BuildContext context, _TrackAction action) async {
    switch (action) {
      case _TrackAction.toggleDislike:
        widget.onToggleDislike();
      case _TrackAction.addToPlaylists:
        await showAddToPlaylistsSheet(context: context, track: widget.track);
      case _TrackAction.removeFromPlaylist:
        context.read<PlaylistsBloc>().add(
          RemoveTrackFromPlaylistRequested(
            trackId: widget.track.id,
            playlistId: widget.playlistIdForRemoval!,
          ),
        );
      case _TrackAction.saveToDownloads:
        await _saveToDownloads(context);
    }
  }

  Future<void> _saveToDownloads(BuildContext context) async {
    setState(() {
      _isSavingToDownloads = true;
    });

    try {
      await saveTrackToDownloads(widget.track);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.saveTrackToDownloadsFailed)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToDownloads = false;
        });
      }
    }
  }
}
