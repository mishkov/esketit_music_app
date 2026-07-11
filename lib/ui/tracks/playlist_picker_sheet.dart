import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class PlaylistPickerResult {
  const PlaylistPickerResult({
    required this.initialPlaylistIds,
    required this.selectedPlaylistIds,
  });

  final Set<int> initialPlaylistIds;
  final Set<int> selectedPlaylistIds;
}

class PlaylistPickerSheet extends StatefulWidget {
  const PlaylistPickerSheet({
    required this.playlists,
    required this.initialSelectedPlaylistIds,
    this.onCreatePlaylist,
    this.isLoading = false,
    super.key,
  });

  final List<Playlist> playlists;
  final Set<int> initialSelectedPlaylistIds;
  final Future<String?> Function()? onCreatePlaylist;
  final bool isLoading;

  @override
  State<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<PlaylistPickerSheet> {
  final Set<int> _selectedPlaylistIds = <int>{};
  final Set<String> _playlistNamesPendingSelection = <String>{};
  bool _hasUserChangedSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedPlaylistIds.addAll(widget.initialSelectedPlaylistIds);
  }

  @override
  void didUpdateWidget(covariant PlaylistPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_hasUserChangedSelection &&
        widget.initialSelectedPlaylistIds !=
            oldWidget.initialSelectedPlaylistIds) {
      _selectedPlaylistIds
        ..clear()
        ..addAll(widget.initialSelectedPlaylistIds);
    }

    _selectCreatedPlaylists(oldWidget.playlists);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.addToPlaylistsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onCreatePlaylist == null
                    ? null
                    : _createPlaylist,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.newPlaylistTitle),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (widget.playlists.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(l10n.createCustomPlaylistFirst),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: widget.playlists
                      .map((playlist) {
                        final isSelected = _selectedPlaylistIds.contains(
                          playlist.id,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(playlist.name),
                          subtitle: Text(
                            l10n.playlistTracksCount(playlist.trackCount),
                          ),
                          onChanged: (checked) =>
                              _onPlaylistSelectionChanged(playlist, checked),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isLoading || widget.playlists.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        PlaylistPickerResult(
                          initialPlaylistIds: widget.initialSelectedPlaylistIds,
                          selectedPlaylistIds: Set<int>.of(
                            _selectedPlaylistIds,
                          ),
                        ),
                      ),
                child: Text(l10n.saveButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlaylistSelectionChanged(Playlist playlist, bool? checked) {
    setState(() {
      _hasUserChangedSelection = true;
      if (checked ?? false) {
        _selectedPlaylistIds.add(playlist.id);
      } else {
        _selectedPlaylistIds.remove(playlist.id);
      }
    });
  }

  Future<void> _createPlaylist() async {
    final playlistName = await widget.onCreatePlaylist!();
    if (playlistName == null || !mounted) {
      return;
    }

    setState(() {
      _playlistNamesPendingSelection.add(playlistName);
    });
  }

  void _selectCreatedPlaylists(List<Playlist> previousPlaylists) {
    if (_playlistNamesPendingSelection.isEmpty) {
      return;
    }

    final previousPlaylistIds = previousPlaylists
        .map((playlist) => playlist.id)
        .toSet();
    final createdPlaylists = widget.playlists
        .where(
          (playlist) =>
              !previousPlaylistIds.contains(playlist.id) &&
              _playlistNamesPendingSelection.contains(playlist.name),
        )
        .toList(growable: false);
    if (createdPlaylists.isEmpty) {
      return;
    }

    _selectedPlaylistIds.addAll(
      createdPlaylists.map((playlist) => playlist.id),
    );
    _playlistNamesPendingSelection.removeAll(
      createdPlaylists.map((playlist) => playlist.name),
    );
  }
}
