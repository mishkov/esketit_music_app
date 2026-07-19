import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/player/fullscreen_inactive_controls_menu_contents.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FullscreenInactiveControlsMenu extends StatelessWidget {
  const FullscreenInactiveControlsMenu({
    required this.onOpened,
    required this.onClosed,
    super.key,
  });

  final VoidCallback onOpened;
  final VoidCallback onClosed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          previous.fullscreenPlayerInactiveControls !=
          current.fullscreenPlayerInactiveControls,
      builder: (context, state) {
        return MenuAnchor(
          onOpen: onOpened,
          onClose: onClosed,
          menuChildren: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: FullscreenInactiveControlsMenuContents(
                  controls: state.fullscreenPlayerInactiveControls,
                ),
              ),
            ),
          ],
          builder: (context, controller, child) {
            return IconButton.filledTonal(
              tooltip: context.l10n.fullscreenInactiveControlsSettingsTooltip,
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const Icon(Icons.settings_rounded),
            );
          },
        );
      },
    );
  }
}
