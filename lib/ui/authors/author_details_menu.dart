import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/use_case/settings/author_albums_display_mode.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthorDetailsMenu extends StatelessWidget {
  const AuthorDetailsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) =>
          previous.authorAlbumsDisplayMode != current.authorAlbumsDisplayMode,
      builder: (context, state) {
        return MenuAnchor(
          menuChildren: [
            SubmenuButton(
              menuChildren: AuthorAlbumsDisplayMode.values
                  .map((displayMode) {
                    final isSelected =
                        state.authorAlbumsDisplayMode == displayMode;

                    return MenuItemButton(
                      leadingIcon: isSelected
                          ? const Icon(Icons.check_rounded)
                          : const SizedBox.square(dimension: 24),
                      onPressed: isSelected
                          ? null
                          : () => _onDisplayModePressed(context, displayMode),
                      child: Text(_displayModeLabel(context, displayMode)),
                    );
                  })
                  .toList(growable: false),
              child: Text(context.l10n.authorAlbumsDisplayModeMenu),
            ),
          ],
          builder: _buildMenuButton,
        );
      },
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    MenuController controller,
    Widget? child,
  ) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      icon: const Icon(Icons.more_vert_rounded),
      onPressed: () => _onMenuButtonPressed(controller),
    );
  }

  void _onMenuButtonPressed(MenuController controller) {
    if (controller.isOpen) {
      controller.close();
    } else {
      controller.open();
    }
  }

  void _onDisplayModePressed(
    BuildContext context,
    AuthorAlbumsDisplayMode displayMode,
  ) {
    context.read<SettingsBloc>().add(SetAuthorAlbumsDisplayMode(displayMode));
  }

  String _displayModeLabel(
    BuildContext context,
    AuthorAlbumsDisplayMode displayMode,
  ) {
    final l10n = context.l10n;

    return switch (displayMode) {
      AuthorAlbumsDisplayMode.expanded =>
        l10n.authorAlbumsDisplayModeExpandedOption,
      AuthorAlbumsDisplayMode.compact =>
        l10n.authorAlbumsDisplayModeCompactOption,
    };
  }
}
