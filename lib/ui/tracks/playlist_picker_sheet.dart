import 'package:esketit_music_app/domain/playlist.dart';
import 'package:flutter/material.dart';

class PlaylistPickerSheet extends StatefulWidget {
  const PlaylistPickerSheet({required this.playlists, super.key});

  final List<Playlist> playlists;

  @override
  State<PlaylistPickerSheet> createState() => _PlaylistPickerSheetState();
}

class _PlaylistPickerSheetState extends State<PlaylistPickerSheet> {
  final Set<int> _selectedPlaylistIds = <int>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add to playlists',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (widget.playlists.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Create a custom playlist first.'),
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
                          subtitle: Text('${playlist.trackCount} tracks'),
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
                onPressed: widget.playlists.isEmpty
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop(_selectedPlaylistIds.toList(growable: false)),
                child: const Text('Add'),
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
