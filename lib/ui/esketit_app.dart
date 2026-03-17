import 'package:esketit_music_app/ui/home/home_screen.dart';
import 'package:flutter/material.dart';

class EsketitApp extends StatelessWidget {
  const EsketitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Esketit Music',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
