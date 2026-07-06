import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:flutter/material.dart';

class CoverUploadPicker extends StatelessWidget {
  const CoverUploadPicker({
    required this.fileName,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(
              fileName == null
                  ? l10n.chooseCoverImageButton
                  : l10n.selectedCoverImageLabel(fileName!),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (onClear != null) ...[
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.clearCoverImageSelectionTooltip,
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ],
    );
  }
}
