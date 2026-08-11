import 'package:flutter/material.dart';

class DownloadManagerSection extends StatelessWidget {
  const DownloadManagerSection({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final separatedChildren = <Widget>[];
    for (var index = 0; index < children.length; index += 1) {
      if (index > 0) {
        separatedChildren.add(const Divider(height: 1));
      }
      separatedChildren.add(children[index]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Card.outlined(
          margin: EdgeInsets.zero,
          child: Column(children: separatedChildren),
        ),
      ],
    );
  }
}
