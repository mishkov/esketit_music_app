import 'package:flutter/material.dart';

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
      return _FallbackImage(icon: icon);
    }

    return Image.network(
      imageUrl!,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _FallbackImage(icon: icon);
      },
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(child: Icon(icon, size: 40)),
    );
  }
}
