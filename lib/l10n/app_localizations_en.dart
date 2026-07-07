// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Esketit Music';

  @override
  String get catalogTitle => 'Catalog';

  @override
  String get searchTitle => 'Search';

  @override
  String get myLibraryTitle => 'My Library';

  @override
  String get homeNavigationLabel => 'Home';

  @override
  String get searchNavigationLabel => 'Search';

  @override
  String get myLibraryNavigationLabel => 'My Library';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signUpTitle => 'Sign up';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get createAccountLink => 'Create an account';

  @override
  String get passwordHelperText => 'Use at least 8 characters.';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get forbiddenActionMessage => 'You do not have access to this action.';

  @override
  String get sessionExpiredMessage =>
      'Your session expired. Please sign in again.';

  @override
  String get requestFailedMessage => 'Request failed. Please try again.';

  @override
  String get unknownErrorMessage => 'Something went wrong. Please try again.';

  @override
  String get loginRequiredTitle => 'Login required';

  @override
  String get loginRequiredMessage => 'This feature requires login.';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get goToLoginButton => 'Go to login';

  @override
  String get bottomPlayerNoTrackSelected => 'No track selected';

  @override
  String get bottomPlayerUnknownArtist => 'Unknown artist';

  @override
  String get guestModeLabel => 'Guest mode';

  @override
  String get signInToUnlockProtectedFeatures =>
      'Sign in to unlock protected features';

  @override
  String get nativeLanguageName => 'English';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageAutoOption => 'Auto';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeLightOption => 'Light';

  @override
  String get settingsThemeDarkOption => 'Dark';

  @override
  String get settingsThemeAutoOption => 'Auto';

  @override
  String get signOutButton => 'Sign out';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get signInToSeeYourPlaylists => 'Sign in to see your playlists.';

  @override
  String get yourPlaylistsTitle => 'Your playlists';

  @override
  String get newPlaylistButton => 'New';

  @override
  String get playlistsDescription =>
      'Favorites is managed automatically. Everything else is fully editable.';

  @override
  String get noPlaylistsYet => 'No playlists yet. Create your first one.';

  @override
  String get tracksTitle => 'Tracks';

  @override
  String get noTracksInAlbumYet => 'No tracks in this album yet.';

  @override
  String get albumsTitle => 'Albums';

  @override
  String get noPublishedAlbumsYet => 'No published albums yet.';

  @override
  String get authorAlbumsDisplayModeMenu => 'Album display';

  @override
  String get authorAlbumsDisplayModeExpandedOption => 'Expanded';

  @override
  String get authorAlbumsDisplayModeCompactOption => 'Compact';

  @override
  String get featuredAuthorsTitle => 'Featured Authors';

  @override
  String get playMyVibeButton => 'Play my vibe';

  @override
  String get noPublishedAuthorsYet => 'No published authors yet.';

  @override
  String get searchHint => 'Search authors, albums, tracks, playlists';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get recentSearchQueriesTitle => 'Recent searches';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: '0 results',
    );
    return '$_temp0';
  }

  @override
  String noResultsFound(String query) {
    return 'No results found for \"$query\".';
  }

  @override
  String get endOfResults => 'End of results';

  @override
  String get authorTypeLabel => 'Author';

  @override
  String get albumTypeLabel => 'Album';

  @override
  String albumWithReleaseDateLabel(String date) {
    return 'Album • $date';
  }

  @override
  String get releaseDateUnknown => 'Release date unknown';

  @override
  String playlistTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
      zero: '0 tracks',
    );
    return '$_temp0';
  }

  @override
  String get systemPlaylistLabel => 'System playlist';

  @override
  String get playlistVisibilityPrivate => 'Private';

  @override
  String get playlistVisibilityPublic => 'Public';

  @override
  String get playlistVisibilityShared => 'Shared';

  @override
  String get addToPlaylistsTitle => 'Add to playlists';

  @override
  String get createCustomPlaylistFirst => 'Create a custom playlist first.';

  @override
  String get addButton => 'Add';

  @override
  String get newPlaylistTitle => 'New playlist';

  @override
  String get createButton => 'Create';

  @override
  String get editPlaylistTitle => 'Edit playlist';

  @override
  String get saveButton => 'Save';

  @override
  String get nameLabel => 'Name';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get coverImageUrlOrPathLabel => 'Cover image URL or path';

  @override
  String get chooseCoverImageButton => 'Choose cover image';

  @override
  String selectedCoverImageLabel(String fileName) {
    return 'Cover: $fileName';
  }

  @override
  String get clearCoverImageSelectionTooltip => 'Clear cover image selection';

  @override
  String get visibilityLabel => 'Visibility';

  @override
  String get nameRequired => 'Name is required.';

  @override
  String get descriptionRequired => 'Description is required.';

  @override
  String get playlistFallbackTitle => 'Playlist';

  @override
  String get playlistNotFound => 'Playlist not found.';

  @override
  String get playlistHasNoTracksYet => 'This playlist has no tracks yet.';

  @override
  String get copyPlaylistLinkTooltip => 'Copy playlist link';

  @override
  String get playlistLinkCopied => 'Playlist link copied.';

  @override
  String get deletePlaylistTitle => 'Delete playlist?';

  @override
  String deletePlaylistMessage(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get trackNotAvailable => 'Not available';

  @override
  String get trackScreenNowPlayingLabel => 'NOW PLAYING';

  @override
  String get trackScreenNoTrackSelectedMessage =>
      'No track is currently selected.';

  @override
  String get trackScreenLyricsSectionTitle => 'Lyrics';

  @override
  String get trackScreenLyricsNotAvailable =>
      'Lyrics are not available for this track.';

  @override
  String get trackScreenLyricsLoadFailed => 'Failed to load lyrics.';

  @override
  String get trackLyricsScreenTitle => 'Lyrics';

  @override
  String get trackScreenLyricsFullscreenTooltip => 'Open lyrics fullscreen';

  @override
  String get trackScreenGoToAlbumAction => 'Go to album';

  @override
  String get trackScreenGoToAuthorAction => 'Go to author';

  @override
  String get trackScreenChooseAuthorTitle => 'Choose author';

  @override
  String get removeFromFavoritesTooltip => 'Remove from favorites';

  @override
  String get addToFavoritesTooltip => 'Add to favorites';

  @override
  String get addToPlaylistsTooltip => 'Add to playlists';

  @override
  String get removeFromPlaylistTooltip => 'Remove from playlist';

  @override
  String get saveTrackToDownloadsTooltip => 'Save to downloads';

  @override
  String get saveTrackToDownloadsFailed => 'Could not download this track.';
}
