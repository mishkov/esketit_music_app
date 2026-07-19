import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:esketit_music_app/use_case/settings/fullscreen_player_inactive_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FullscreenInactiveControlsMenuContents extends StatelessWidget {
  const FullscreenInactiveControlsMenuContents({
    required this.controls,
    super.key,
  });

  final FullscreenPlayerInactiveControls controls;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            l10n.fullscreenInactiveControlsMenuTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        CheckboxListTile(
          value: controls.showTrackName,
          title: Text(l10n.fullscreenInactiveControlTrackName),
          onChanged: (value) => _update(
            context,
            controls.copyWith(showTrackName: value ?? false),
          ),
        ),
        CheckboxListTile(
          value: controls.showTrackAuthors,
          title: Text(l10n.fullscreenInactiveControlTrackAuthors),
          onChanged: (value) => _update(
            context,
            controls.copyWith(showTrackAuthors: value ?? false),
          ),
        ),
        CheckboxListTile(
          value: controls.showTrackProgressIndicator,
          title: Text(l10n.fullscreenInactiveControlProgressIndicator),
          onChanged: (value) => _update(
            context,
            controls.copyWith(showTrackProgressIndicator: value ?? false),
          ),
        ),
        CheckboxListTile(
          value: controls.showTrackTiming,
          title: Text(l10n.fullscreenInactiveControlTrackTiming),
          onChanged: controls.showTrackProgressIndicator
              ? (value) => _update(
                  context,
                  controls.copyWith(showTrackTiming: value ?? false),
                )
              : null,
        ),
        CheckboxListTile(
          value: controls.showPlaybackButtons,
          title: Text(l10n.fullscreenInactiveControlPlaybackButtons),
          onChanged: (value) => _update(
            context,
            controls.copyWith(showPlaybackButtons: value ?? false),
          ),
        ),
        CheckboxListTile(
          value: controls.showFavoriteButton,
          title: Text(l10n.fullscreenInactiveControlFavoriteButton),
          onChanged: (value) => _update(
            context,
            controls.copyWith(showFavoriteButton: value ?? false),
          ),
        ),
      ],
    );
  }

  void _update(
    BuildContext context,
    FullscreenPlayerInactiveControls updatedControls,
  ) {
    context.read<SettingsBloc>().add(
      SetFullscreenPlayerInactiveControls(updatedControls),
    );
  }
}
