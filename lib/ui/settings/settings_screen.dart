import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/app_theme_mode.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageOptions = _LanguageOption.buildSupportedOptions();
    const themeOptions = _ThemeModeOption.supportedOptions;

    return ScreenSkeleton(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      enableBottomPlayer: false,
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _LanguageOption.localeToValue(state.locale),
                decoration: InputDecoration(
                  labelText: context.l10n.settingsLanguageLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final languageOption in languageOptions)
                    DropdownMenuItem<String>(
                      value: languageOption.value,
                      child: Text(languageOption.label(context)),
                    ),
                ],
                onChanged: (selectedValue) =>
                    _onLanguageChanged(context, selectedValue),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _ThemeModeOption.themeModeToValue(
                  state.themeMode,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.settingsThemeLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final themeOption in themeOptions)
                    DropdownMenuItem<String>(
                      value: themeOption.value,
                      child: Text(themeOption.label(context)),
                    ),
                ],
                onChanged: (selectedValue) =>
                    _onThemeChanged(context, selectedValue),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onLanguageChanged(BuildContext context, String? selectedValue) {
    context.read<SettingsBloc>().add(
      SetLocale(_LanguageOption.valueToLocale(selectedValue)),
    );
  }

  void _onThemeChanged(BuildContext context, String? selectedValue) {
    if (selectedValue == null) {
      return;
    }

    context.read<SettingsBloc>().add(
      SetThemeMode(_ThemeModeOption.valueToThemeMode(selectedValue)),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.value, required this.labelBuilder});

  static const String autoValue = 'auto';

  final String value;
  final String Function(BuildContext context) labelBuilder;

  String label(BuildContext context) => labelBuilder(context);

  static List<_LanguageOption> buildSupportedOptions() {
    return [
      ...AppLocalizations.supportedLocales.map(_fromLocale),
      _LanguageOption(
        value: autoValue,
        labelBuilder: (context) => context.l10n.settingsLanguageAutoOption,
      ),
    ];
  }

  static _LanguageOption _fromLocale(Locale locale) {
    final localizations = lookupAppLocalizations(locale);

    return _LanguageOption(
      value: locale.languageCode,
      labelBuilder: (context) => localizations.nativeLanguageName,
    );
  }

  static String localeToValue(AppLocale? locale) {
    return locale?.languageCode ?? autoValue;
  }

  static AppLocale? valueToLocale(String? value) {
    if (value == null || value == autoValue) {
      return null;
    }

    return AppLocale.fromLanguageCode(value);
  }
}

class _ThemeModeOption {
  const _ThemeModeOption({required this.value, required this.labelBuilder});

  static const List<_ThemeModeOption> supportedOptions = [
    _ThemeModeOption(value: 'light', labelBuilder: _lightLabel),
    _ThemeModeOption(value: 'dark', labelBuilder: _darkLabel),
    _ThemeModeOption(value: 'auto', labelBuilder: _autoLabel),
  ];

  final String value;
  final String Function(BuildContext context) labelBuilder;

  String label(BuildContext context) => labelBuilder(context);

  static String _lightLabel(BuildContext context) {
    return context.l10n.settingsThemeLightOption;
  }

  static String _darkLabel(BuildContext context) {
    return context.l10n.settingsThemeDarkOption;
  }

  static String _autoLabel(BuildContext context) {
    return context.l10n.settingsThemeAutoOption;
  }

  static AppThemeMode valueToThemeMode(String value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.auto,
    };
  }

  static String themeModeToValue(AppThemeMode themeMode) {
    return switch (themeMode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      AppThemeMode.auto => 'auto',
    };
  }
}
