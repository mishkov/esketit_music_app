import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/file/local_file.dart';
import 'package:esketit_music_app/ui/shared/fallback_image.dart';
import 'package:esketit_music_app/ui/shared/local_image.dart';
import 'package:esketit_music_app/unassigned_layer/http_file.dart';
import 'package:flutter/material.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    this.imageUrl,
    this.file,
    required this.icon,
    this.fit = BoxFit.cover,
    super.key,
  }) : assert(imageUrl == null || file == null);

  final String? imageUrl;
  final AbstractFile? file;
  final IconData icon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final source = _imageSource();
    if (source == null || source.value.isEmpty) {
      return FallbackImage(icon: icon);
    }

    Widget errorBuilder(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    ) => FallbackImage(icon: icon);

    if (source.isLocal) {
      return buildLocalImage(
        path: source.value,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    return Image.network(
      source.value,
      fit: fit,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: errorBuilder,
    );
  }

  _ImageSource? _imageSource() {
    final abstractFile = file;
    if (abstractFile is LocalFile) {
      return _ImageSource.local(abstractFile.path);
    }
    if (abstractFile is HttpFile) {
      return _ImageSource.remote(abstractFile.uri.toString());
    }

    final value = imageUrl;
    if (value == null || value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri?.scheme == 'file') {
      return _ImageSource.local(uri!.toFilePath());
    }

    return _ImageSource.remote(value);
  }
}

class _ImageSource {
  const _ImageSource.local(this.value) : isLocal = true;
  const _ImageSource.remote(this.value) : isLocal = false;

  final String value;
  final bool isLocal;
}
