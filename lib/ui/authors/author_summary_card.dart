import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/auth/login_required_prompt_scope.dart';
import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:esketit_music_app/use_case/auth/bloc/auth_bloc.dart';
import 'package:esketit_music_app/use_case/player/autoplay_storage.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorSummaryCard extends StatelessWidget {
  const AuthorSummaryCard({required this.author, super.key});

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: RemoteImage(
              imageUrl: author.primaryPhotoUrl,
              icon: Icons.person_rounded,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          author.currentName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _playAuthor(context),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.l10n.playAuthorButton),
        ),
      ],
    );
  }

  void _playAuthor(BuildContext context) {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      LoginRequiredPromptScope.of(context).show();

      return;
    }

    context.read<PlayerBloc>().add(
      StartAutoplayPlaybackRequested(
        AutoplayContext(
          sourceType: AutoplaySourceType.author,
          sourceId: author.id,
        ),
      ),
    );
  }
}
