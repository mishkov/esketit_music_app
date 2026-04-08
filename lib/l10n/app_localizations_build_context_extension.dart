import 'package:flutter/widgets.dart';
import 'package:esketit_music_app/l10n/app_localizations.dart';

extension AppLocalizationsBuildContextExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
