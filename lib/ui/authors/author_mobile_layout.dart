import 'package:flutter/material.dart';

class AuthorMobileLayout extends StatelessWidget {
  const AuthorMobileLayout({
    required this.summary,
    required this.albumsSection,
    super.key,
  });

  final Widget summary;
  final Widget albumsSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [summary, const SizedBox(height: 16), albumsSection],
    );
  }
}
