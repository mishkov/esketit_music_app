import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/ui/authors/author_albums_section.dart';
import 'package:esketit_music_app/ui/authors/author_desktop_layout.dart';
import 'package:esketit_music_app/ui/authors/author_mobile_layout.dart';
import 'package:esketit_music_app/ui/authors/author_summary_card.dart';
import 'package:flutter/material.dart';

class AuthorDetailsContent extends StatelessWidget {
  const AuthorDetailsContent({
    required this.author,
    required this.albums,
    required this.selectedTrackExists,
    super.key,
  });

  final Author author;
  final List<Album> albums;
  final bool selectedTrackExists;

  static const _desktopLayoutBreakpoint = 900.0;
  static const _contentMaxWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopLayout =
            constraints.maxWidth >= _desktopLayoutBreakpoint;

        Widget content = useDesktopLayout
            ? AuthorDesktopLayout(
                summary: AuthorSummaryCard(author: author),
                albumsSection: AuthorAlbumsSection(albums: albums),
              )
            : AuthorMobileLayout(
                summary: AuthorSummaryCard(author: author),
                albumsSection: AuthorAlbumsSection(albums: albums),
              );

        content = Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
            child: content,
          ),
        );

        return ListView(
          key: PageStorageKey<int>(author.id),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: selectedTrackExists ? 100 : 16,
          ),
          children: [content],
        );
      },
    );
  }
}
