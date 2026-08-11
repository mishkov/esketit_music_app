import 'package:esketit_music_app/ui/downloads/collection_download_button.dart';
import 'package:flutter/material.dart';

class DownloadedCollectionRemoveButton extends StatelessWidget {
  const DownloadedCollectionRemoveButton({
    required this.kind,
    required this.onPressed,
    super.key,
  });

  final DownloadCollectionUiKind kind;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CollectionDownloadButton(
      kind: kind,
      status: CollectionDownloadUiStatus.downloaded,
      onPressed: onPressed,
    );
  }
}
