import 'package:flutter/material.dart';
import 'package:esketit_music_app/ui/shared/fallback_image.dart';

class RemoteImage extends StatelessWidget {
  const RemoteImage({
    required this.imageUrl,
    required this.icon,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? imageUrl;
  final IconData icon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return FallbackImage(icon: icon);
    }

    return Image.network(
      imageUrl!,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return FallbackImage(icon: icon);
      },
    );
  }
}
