import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class PlaylistPickerSheet extends StatefulWidget {
  const PlaylistPickerSheet({
    required this.playlists,
    this.isLoading = false,
    super.key,
  });

  final List<Playlist> playlists;
  final bool isLoading;

  @override
  State<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<PlaylistPickerSheet> {
  final Set<int> _selectedPlaylistIds = <int>{};

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
                    : () => Navigator.of(
                        context,
                      ).pop(_selectedPlaylistIds.toList(growable: false)),
                child: Text(l10n.addButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPlaylistSelectionChanged(Playlist playlist, bool? checked) {
    setState(() {
      if (checked ?? false) {
        _selectedPlaylistIds.add(playlist.id);
      } else {
        _selectedPlaylistIds.remove(playlist.id);
      }
    });
  }
}
