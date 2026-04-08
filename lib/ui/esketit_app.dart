import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/app_shell.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EsketitApp extends StatelessWidget {
  const EsketitApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          locale: _toFlutterLocale(state.locale),
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
          home: const AppShell(),
        );
      },
    );
  }

  Locale? _toFlutterLocale(AppLocale? appLocale) {
    if (appLocale == null) {
      return null;
    }

    return Locale(appLocale.languageCode);
  }
}
