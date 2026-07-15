import 'dart:async';
import 'dart:ui' as ui;

import 'package:esketit_music_app/ui/theme/album_cover_average_color.dart';
import 'package:esketit_music_app/ui/theme/album_cover_average_color_calculator.dart';
import 'package:flutter/material.dart';

class AlbumCoverColorSchemeSeedBuilder extends StatefulWidget {
  const AlbumCoverColorSchemeSeedBuilder({
    required this.albumCoverUri,
    required this.enabled,
    required this.builder,
    super.key,
  });

  static const Color fallbackSeedColor = Colors.green;

  final Uri? albumCoverUri;
  final bool enabled;
  final Widget Function(BuildContext context, Color colorSchemeSeed) builder;

  @override
  State<AlbumCoverColorSchemeSeedBuilder> createState() =>
      _AlbumCoverColorSchemeSeedBuilderState();
}

class _AlbumCoverColorSchemeSeedBuilderState
    extends State<AlbumCoverColorSchemeSeedBuilder> {
  static const int _decodeSize = 32;
  static final Map<Uri, Color> _colorCache = <Uri, Color>{};

  Color _colorSchemeSeed = AlbumCoverColorSchemeSeedBuilder.fallbackSeedColor;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _updateColorSchemeSeedSynchronously();
  }

  @override
  void didUpdateWidget(AlbumCoverColorSchemeSeedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albumCoverUri != oldWidget.albumCoverUri ||
        widget.enabled != oldWidget.enabled) {
      _updateColorSchemeSeedSynchronously();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _colorSchemeSeed);
  }

  void _updateColorSchemeSeedSynchronously() {
    final albumCoverUri = widget.albumCoverUri;
    if (!widget.enabled || albumCoverUri == null) {
      _loadGeneration++;
      _colorSchemeSeed = AlbumCoverColorSchemeSeedBuilder.fallbackSeedColor;

      return;
    }

    final cachedColor = _colorCache[albumCoverUri];
    if (cachedColor != null) {
      _loadGeneration++;
      _colorSchemeSeed = cachedColor;

      return;
    }

    final loadGeneration = ++_loadGeneration;
    unawaited(_loadColorSchemeSeed(albumCoverUri, loadGeneration));
  }

  Future<void> _loadColorSchemeSeed(
    Uri albumCoverUri,
    int loadGeneration,
  ) async {
    try {
      final color = await _calculateAverageColor(albumCoverUri);
      if (!mounted || loadGeneration != _loadGeneration || color == null) {
        return;
      }

      _colorCache[albumCoverUri] = color;
      _setColorSchemeSeed(color);
    } catch (_) {
      if (!mounted || loadGeneration != _loadGeneration) {
        return;
      }

      _setColorSchemeSeed(AlbumCoverColorSchemeSeedBuilder.fallbackSeedColor);
    }
  }

  void _setColorSchemeSeed(Color color) {
    if (_colorSchemeSeed == color) {
      return;
    }

    setState(() {
      _colorSchemeSeed = color;
    });
  }

  Future<Color?> _calculateAverageColor(Uri albumCoverUri) async {
    final imageProvider = ResizeImage.resizeIfNeeded(
      _decodeSize,
      _decodeSize,
      NetworkImage(albumCoverUri.toString()),
    );
    final imageInfo = await _resolveImage(imageProvider);
    try {
      final byteData = await imageInfo.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        return null;
      }

      final rgbValue = await calculateAverageRgbValue(
        byteData.buffer.asUint8List(),
      );
      if (rgbValue == null) {
        return null;
      }

      final colorComponents = colorComponentsFromRgbValue(rgbValue);

      return Color.fromARGB(
        255,
        colorComponents.red,
        colorComponents.green,
        colorComponents.blue,
      );
    } finally {
      imageInfo.dispose();
    }
  }

  Future<ImageInfo> _resolveImage(ImageProvider imageProvider) {
    final completer = Completer<ImageInfo>();
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      _completeImageInfo(completer),
      onError: _completeImageError(completer),
    );
    stream.addListener(listener);

    return completer.future.whenComplete(() {
      stream.removeListener(listener);
    });
  }

  ImageListener _completeImageInfo(Completer<ImageInfo> completer) {
    return (imageInfo, synchronousCall) {
      if (!completer.isCompleted) {
        completer.complete(imageInfo);
      }
    };
  }

  ImageErrorListener _completeImageError(Completer<ImageInfo> completer) {
    return (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    };
  }
}
