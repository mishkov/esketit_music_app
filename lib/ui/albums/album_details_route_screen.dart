import 'package:esketit_music_app/domain/album.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/albums/album_details_screen.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/albums/album_details/bloc/album_details_bloc.dart';
import 'package:esketit_music_app/use_case/catalog/catalog_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlbumDetailsRouteScreen extends StatelessWidget {
  const AlbumDetailsRouteScreen({
    required this.albumId,
    this.initialAlbum,
    super.key,
  });

  final int albumId;
  final Album? initialAlbum;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: _createAlbumDetailsBloc,
      child: BlocBuilder<AlbumDetailsBloc, AlbumDetailsState>(
        builder: _buildContent,
      ),
    );
  }

  AlbumDetailsBloc _createAlbumDetailsBloc(BuildContext context) {
    final effectiveInitialAlbum = initialAlbum?.id == albumId
        ? initialAlbum
        : null;
    final bloc = AlbumDetailsBloc(
      initialState: AlbumDetailsState(
        albumId: albumId,
        album: effectiveInitialAlbum,
        isLoading: effectiveInitialAlbum == null,
        error: null,
      ),
      catalogStorage: context.read<CatalogStorage>(),
      errorReporter: context.read<ErrorReporter>(),
    );
    if (effectiveInitialAlbum == null) {
      bloc.add(LoadAlbumDetails(albumId));
    }

    return bloc;
  }

  Widget _buildContent(BuildContext context, AlbumDetailsState state) {
    final album = state.album;
    if (album != null) {
      return AlbumDetailsScreen(album: album);
    }

    return ScreenSkeleton(
      appBar: AppBar(title: Text(context.l10n.albumTypeLabel)),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Text(
                state.error == null
                    ? context.l10n.albumNotFound
                    : context.l10n.albumLoadFailed,
              ),
            ),
    );
  }
}
