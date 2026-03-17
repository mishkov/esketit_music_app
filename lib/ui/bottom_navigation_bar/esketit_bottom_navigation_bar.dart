import 'package:flutter/material.dart';

class EsketitBottomNavigationBar extends StatelessWidget {
  const EsketitBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          // TODO: translate the text.
          label: 'Home',
          icon: Icon(Icons.home_rounded),
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
