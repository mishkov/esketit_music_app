import 'package:flutter/material.dart';

class AuthorDesktopLayout extends StatelessWidget {
  const AuthorDesktopLayout({
    required this.summary,
    required this.albumsSection,
    super.key,
  });

  final Widget summary;
  final Widget albumsSection;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: summary),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: albumsSection),
      ],
    );
  }
}
