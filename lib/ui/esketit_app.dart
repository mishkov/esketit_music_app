import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/app_shell.dart';
import 'package:flutter/material.dart';

class EsketitApp extends StatelessWidget {
  const EsketitApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const AppShell(),
    );
  }
}
