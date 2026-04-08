import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/ui_localization_extension.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';

class PlaylistEditorDialog extends StatefulWidget {
  const PlaylistEditorDialog({
    this.initialName = '',
    this.initialDescription = '',
    this.initialCoverImagePath = '',
    this.initialVisibility = PlaylistVisibility.private,
    this.title,
    this.submitLabel,
    super.key,
  });

  final String initialName;
  final String initialDescription;
  final String initialCoverImagePath;
  final PlaylistVisibility initialVisibility;
  final String? title;
  final String? submitLabel;

  @override
  State<PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends State<PlaylistEditorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coverImagePathController =
      TextEditingController();
  PlaylistVisibility _visibility = PlaylistVisibility.private;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    _descriptionController.text = widget.initialDescription;
    _coverImagePathController.text = widget.initialCoverImagePath;
    _visibility = widget.initialVisibility;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _coverImagePathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title ?? l10n.newPlaylistTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.nameLabel),
                maxLength: 200,
                validator: _validateName,
              ),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.descriptionLabel),
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                validator: _validateDescription,
              ),
              TextFormField(
                controller: _coverImagePathController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.coverImageUrlOrPathLabel,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlaylistVisibility>(
                initialValue: _visibility,
                decoration: InputDecoration(labelText: l10n.visibilityLabel),
                items: PlaylistVisibility.values
                    .map((visibility) {
                      return DropdownMenuItem(
                        value: visibility,
                        child: Text(
                          context.playlistVisibilityLabel(visibility),
                        ),
                      );
                    })
                    .toList(growable: false),
                onChanged: _onVisibilityChanged,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _cancel(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: Text(widget.submitLabel ?? l10n.createButton),
        ),
      ],
    );
  }

  String? _validateName(String? value) {
    final l10n = context.l10n;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.nameRequired;
    }

    return null;
  }

  String? _validateDescription(String? value) {
    final l10n = context.l10n;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.descriptionRequired;
    }

    return null;
  }

  void _onVisibilityChanged(PlaylistVisibility? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _visibility = value;
    });
  }

  void _cancel(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      PlaylistUpsertInput(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImagePath: _coverImagePathController.text.trim(),
        visibility: _visibility,
      ),
    );
  }
}
