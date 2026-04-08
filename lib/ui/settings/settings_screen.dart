import 'package:esketit_music_app/l10n/app_localizations.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:esketit_music_app/ui/shared/screen_skeleton.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageOptions = _LanguageOption.buildSupportedOptions();

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
