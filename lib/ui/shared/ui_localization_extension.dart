import 'package:esketit_music_app/domain/playlist.dart';
import 'package:esketit_music_app/l10n/app_localizations_build_context_extension.dart';
import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';

extension UiLocalizationExtension on BuildContext {
  String formatReleaseDate(DateTime releaseDate) {
    final locale = Localizations.localeOf(this).toLanguageTag();

    return DateFormat.yMMMd(locale).format(releaseDate);
  }

  String playlistVisibilityLabel(PlaylistVisibility visibility) {
    final l10n = this.l10n;

    return switch (visibility) {
      PlaylistVisibility.private => l10n.playlistVisibilityPrivate,
      PlaylistVisibility.public => l10n.playlistVisibilityPublic,
      PlaylistVisibility.shared => l10n.playlistVisibilityShared,
    };
  }
}
