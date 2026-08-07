import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/authors/author_details_screen.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/catalog/bloc/catalog_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorDetailsRouteScreen extends StatefulWidget {
  const AuthorDetailsRouteScreen({
    required this.authorId,
    this.initialAuthor,
    super.key,
  });

  final int authorId;
  final Author? initialAuthor;

  @override
  State<AuthorDetailsRouteScreen> createState() =>
      _AuthorDetailsRouteScreenState();
}

class _AuthorDetailsRouteScreenState extends State<AuthorDetailsRouteScreen> {
  @override
  void initState() {
    super.initState();
    if (_authorFromState(context.read<CatalogBloc>().state) == null) {
      context.read<CatalogBloc>().add(LoadPublishedAuthors());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogBloc, CatalogState>(
      builder: (context, state) {
        final author = _authorFromState(state);
        if (author != null) {
          return AuthorDetailsScreen(author: author);
        }

        final message = state.authorsErrorMessage != null
            ? context.l10n.authorLoadFailed
            : context.l10n.authorNotFound;

        return ScreenSkeleton(
          appBar: AppBar(title: Text(context.l10n.authorTypeLabel)),
          body: state.isLoadingAuthors
              ? const Center(child: CircularProgressIndicator())
              : Center(child: Text(message)),
        );
      },
    );
  }

  Author? _authorFromState(CatalogState state) {
    final initialAuthor = widget.initialAuthor;
    if (initialAuthor != null && initialAuthor.id == widget.authorId) {
      return initialAuthor;
    }

    return state.authors
        .where((author) => author.id == widget.authorId)
        .firstOrNull;
  }
}
