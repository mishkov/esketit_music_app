import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/ui/settings/settings_screen.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/app_theme_mode.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:esketit_music_app/use_case/settings/settings_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders localized language options', (tester) async {
    final settingsStorage = _FakeSettingsStorage();
    final settingsBloc = SettingsBloc(
      initialState: SettingsState(
        serverUri: Uri.parse('https://example.com'),
        locale: null,
        themeMode: AppThemeMode.auto,
      ),
      settingsStorage: settingsStorage,
    );
    addTearDown(settingsBloc.close);

    await tester.pumpWidget(
      _SettingsScreenHarness(
        locale: const Locale('ru'),
        settingsBloc: settingsBloc,
      ),
    );

    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Тема'), findsOneWidget);
    expect(find.text('Авто'), findsNWidgets(2));

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();

    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Авто'), findsWidgets);
  });

  testWidgets('renders localized theme options', (tester) async {
    final settingsStorage = _FakeSettingsStorage();
    final settingsBloc = SettingsBloc(
      initialState: SettingsState(
        serverUri: Uri.parse('https://example.com'),
        locale: null,
        themeMode: AppThemeMode.auto,
      ),
      settingsStorage: settingsStorage,
    );
    addTearDown(settingsBloc.close);

    await tester.pumpWidget(
      _SettingsScreenHarness(
        locale: const Locale('ru'),
        settingsBloc: settingsBloc,
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();

    expect(find.text('Светлая'), findsOneWidget);
    expect(find.text('Тёмная'), findsOneWidget);
    expect(find.text('Авто'), findsWidgets);
  });

  testWidgets('stores selected locale', (tester) async {
    final settingsStorage = _FakeSettingsStorage();
    final settingsBloc = SettingsBloc(
      initialState: SettingsState(
        serverUri: Uri.parse('https://example.com'),
        locale: null,
        themeMode: AppThemeMode.auto,
      ),
      settingsStorage: settingsStorage,
    );
    addTearDown(settingsBloc.close);

    await tester.pumpWidget(
      _SettingsScreenHarness(
        locale: const Locale('en'),
        settingsBloc: settingsBloc,
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский').last);
    await tester.pumpAndSettle();

    expect(settingsBloc.state.locale, const AppLocale('ru'));
    expect(settingsStorage.savedLocale, const AppLocale('ru'));
  });

  testWidgets('stores selected theme mode', (tester) async {
    final settingsStorage = _FakeSettingsStorage();
    final settingsBloc = SettingsBloc(
      initialState: SettingsState(
        serverUri: Uri.parse('https://example.com'),
        locale: null,
        themeMode: AppThemeMode.auto,
      ),
      settingsStorage: settingsStorage,
    );
    addTearDown(settingsBloc.close);

    await tester.pumpWidget(
      _SettingsScreenHarness(
        locale: const Locale('en'),
        settingsBloc: settingsBloc,
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(settingsBloc.state.themeMode, AppThemeMode.dark);
    expect(settingsStorage.savedThemeMode, AppThemeMode.dark);
  });
}

class _SettingsScreenHarness extends StatelessWidget {
  const _SettingsScreenHarness({
    required this.locale,
    required this.settingsBloc,
  });

  final Locale locale;
  final SettingsBloc settingsBloc;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SettingsBloc>.value(
        value: settingsBloc,
        child: const SettingsScreen(),
      ),
    );
  }
}

class _FakeSettingsStorage implements SettingsStorage {
  AppLocale? savedLocale;
  Uri? savedServerUri;
  AppThemeMode? savedThemeMode;

  @override
  Future<AppLocale?> getLocale() async => savedLocale;

  @override
  Future<Uri?> getServerUri() async => savedServerUri;

  @override
  Future<AppThemeMode?> getThemeMode() async => savedThemeMode;

  @override
  Future<void> setLocale(AppLocale? locale) async {
    savedLocale = locale;
  }

  @override
  Future<void> setServerUri(Uri uri) async {
    savedServerUri = uri;
  }

  @override
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    savedThemeMode = themeMode;
  }
}
