import 'package:flutter/material.dart';

class FallbackImage extends StatelessWidget {
  const FallbackImage({required this.icon, super.key});

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
