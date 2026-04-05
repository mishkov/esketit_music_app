import 'package:flutter/material.dart';

class EsketitBottomNavigationBar extends StatelessWidget {
  const EsketitBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        BottomNavigationBarItem(
          // TODO: translate the text.
          label: 'Home',
          icon: Icon(Icons.home_rounded),
        ),
        BottomNavigationBarItem(
          label: 'Search',
          icon: Icon(Icons.search_rounded),
        ),
        BottomNavigationBarItem(
          // TODO: translate the text.
          label: 'My Library',
          icon: Icon(Icons.library_music_rounded),
        ),
      ],
    );
  }
}
