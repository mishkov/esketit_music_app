import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/ui/playlists/playlist_tracks_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('system playlist is displayed without reorder support', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistTracksList(
            playlist: _playlist(system: true, kind: PlaylistKind.dislikes),
            tracks: const [],
            isReordering: false,
            onReorder: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('custom playlist keeps reorder support', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistTracksList(
            playlist: _playlist(system: false, kind: PlaylistKind.custom),
            tracks: const [],
            isReordering: false,
            onReorder: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  testWidgets('non-custom playlist is non-editable even without system flag', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlaylistTracksList(
            playlist: _playlist(system: false, kind: PlaylistKind.dislikes),
            tracks: const [],
            isReordering: false,
            onReorder: (_, _) {},
          ),
        ),
      ),
    );

    expect(find.byType(ReorderableListView), findsNothing);
    expect(find.byType(ListView), findsOneWidget);
  });
}

Playlist _playlist({required bool system, required PlaylistKind kind}) {
  return Playlist(
    id: 7,
    userId: 1,
    name: 'Playlist',
    description: '',
    coverImagePath: '',
    visibility: PlaylistVisibility.private,
    trackCount: 0,
    system: system,
    kind: kind,
  );
}
