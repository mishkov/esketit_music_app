import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/use_case/playlists/playlists_storage.dart';
import 'package:flutter/material.dart';

class PlaylistEditorDialog extends StatefulWidget {
  const PlaylistEditorDialog({
    this.initialName = '',
    this.initialDescription = '',
    this.initialCoverImagePath = '',
    this.initialVisibility = PlaylistVisibility.private,
    this.title = 'New playlist',
    this.submitLabel = 'Create',
    super.key,
  });

  final String initialName;
  final String initialDescription;
  final String initialCoverImagePath;
  final PlaylistVisibility initialVisibility;
  final String title;
  final String submitLabel;

  @override
  State<PlaylistEditorDialog> createState() => _PlaylistEditorDialogState();
}

class _PlaylistEditorDialogState extends State<PlaylistEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coverImagePathController;
  late PlaylistVisibility _visibility;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _coverImagePathController = TextEditingController(
      text: widget.initialCoverImagePath,
    );
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
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Name'),
                maxLength: 200,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Name is required.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Description is required.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _coverImagePathController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Cover image URL or path',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlaylistVisibility>(
                initialValue: _visibility,
                decoration: const InputDecoration(labelText: 'Visibility'),
                items: PlaylistVisibility.values
                    .map((visibility) {
                      return DropdownMenuItem(
                        value: visibility,
                        child: Text(_visibilityLabel(visibility)),
                      );
                    })
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _visibility = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
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
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

String _visibilityLabel(PlaylistVisibility visibility) {
  return switch (visibility) {
    PlaylistVisibility.private => 'Private',
    PlaylistVisibility.public => 'Public',
    PlaylistVisibility.shared => 'Shared',
  };
}
