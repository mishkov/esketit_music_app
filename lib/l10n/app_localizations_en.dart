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
  String get bottomPlayerOpenFullscreenTooltip => 'Open fullscreen player';

  @override
  String get fullscreenPlayerCloseTooltip => 'Close fullscreen player';

  @override
  String get repeatQueueTooltip => 'Repeat queue';

  @override
  String get repeatTrackTooltip => 'Repeat track';

  @override
  String get repeatOffTooltip => 'Turn repeat off';

  @override
  String get fullscreenInactiveControlsSettingsTooltip =>
      'Customize inactive controls';

  @override
  String get fullscreenInactiveControlsMenuTitle =>
      'Select controls that will be visible in ‘inactive’ mode';

  @override
  String get fullscreenInactiveControlTrackName => 'Track name';

  @override
  String get fullscreenInactiveControlTrackAuthors => 'Track authors';

  @override
  String get fullscreenInactiveControlProgressIndicator =>
      'Track progress indicator';

  @override
  String get fullscreenInactiveControlTrackTiming =>
      'Track current playing time & duration';

  @override
  String get fullscreenInactiveControlPlaybackButtons =>
      'Previous/play/next buttons';

  @override
  String get fullscreenInactiveControlFavoriteButton =>
      'Favorite and dislike buttons';

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
  String get settingsUseTrackAlbumCoverColorSchemeSeedLabel =>
      'Set app color based on track album cover';

  @override
  String get signOutButton => 'Sign out';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get signInToSeeYourPlaylists => 'Sign in to see your playlists.';

  @override
  String get likesTitle => 'Likes';

  @override
  String get dislikesTitle => 'Dislikes';

  @override
  String get signInToViewLibraryItem => 'Sign in to view';

  @override
  String get playlistsSectionTitle => 'Playlists';

  @override
  String get createPlaylistTooltip => 'Create playlist';

  @override
  String get signInToManagePlaylists =>
      'Sign in to create and manage playlists.';

  @override
  String get playlistsLoadFailed => 'Failed to load playlists.';

  @override
  String get yourPlaylistsTitle => 'Your playlists';

  @override
  String get newPlaylistButton => 'New';

  @override
  String get playlistsDescription =>
      'Favorites and Dislikes are managed automatically. Everything else is fully editable.';

  @override
  String get noPlaylistsYet => 'No playlists yet. Create your first one.';

  @override
  String get downloadedTitle => 'Downloaded';

  @override
  String get deleteAllDownloadsTooltip => 'Delete all downloads';

  @override
  String get downloadedTracksTitle => 'Tracks';

  @override
  String get downloadedAuthorsTitle => 'Authors';

  @override
  String get downloadedAlbumsTitle => 'Albums';

  @override
  String get downloadedPlaylistsTitle => 'Playlists';

  @override
  String downloadedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: '0 items',
    );
    return '$_temp0';
  }

  @override
  String get trackDownloadQueuedTooltip => 'Queued for download';

  @override
  String get trackDownloadingTooltip => 'Downloading';

  @override
  String get trackDownloadedTooltip => 'Downloaded';

  @override
  String get trackDownloadFailedTooltip => 'Download failed';

  @override
  String get downloadManagerTitle => 'Downloads';

  @override
  String get currentDownloadSectionTitle => 'Current';

  @override
  String get queuedDownloadsSectionTitle => 'Queued';

  @override
  String get failedDownloadsSectionTitle => 'Failed';

  @override
  String get noDownloadActivity => 'There are no active or failed downloads.';

  @override
  String get cancelDownloadTooltip => 'Cancel download';

  @override
  String get clearButton => 'Clear';

  @override
  String get downloadQueuedStatus => 'Queued';

  @override
  String get downloadInProgressStatus => 'Downloading';

  @override
  String get downloadWaitingToRetryStatus => 'Waiting to try again';

  @override
  String downloadProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String downloadsQueuedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks queued',
      one: '1 track queued',
      zero: 'No tracks queued',
    );
    return '$_temp0';
  }

  @override
  String downloadsFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Failed to download $count tracks',
      one: 'Failed to download 1 track',
    );
    return '$_temp0';
  }

  @override
  String get downloadFailuresRemainMessage =>
      'Open downloads for details or clear this message.';

  @override
  String get downloadWaitingToStart => 'Waiting to start';

  @override
  String downloadingTrackName(String trackName) {
    return 'Downloading $trackName';
  }

  @override
  String downloadWaitingToRetryTrack(String trackName) {
    return 'Waiting to try $trackName again';
  }

  @override
  String get downloadFailureNetwork => 'Network error';

  @override
  String get downloadFailureServer => 'Server error';

  @override
  String get downloadFailureStorage => 'Storage error';

  @override
  String get downloadFailureInsufficientStorage => 'Not enough storage';

  @override
  String get downloadFailureInvalidResponse => 'Invalid server response';

  @override
  String get downloadFailureUnknown => 'Unknown error';

  @override
  String get downloadAlbumButton => 'Download album';

  @override
  String get downloadPlaylistButton => 'Download playlist';

  @override
  String get cancelDownloadButton => 'Cancel download';

  @override
  String get removeDownloadButton => 'Remove download';

  @override
  String get deleteAllDownloadsTitle => 'Delete all downloads?';

  @override
  String deleteAllDownloadsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Delete $count downloaded tracks? Current and queued downloads will also be canceled.',
      one:
          'Delete 1 downloaded track? Current and queued downloads will also be canceled.',
      zero:
          'Delete all downloaded content? Current and queued downloads will also be canceled.',
    );
    return '$_temp0';
  }

  @override
  String deleteAllDownloadsMessageWithSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Delete $count downloaded tracks ($size)? Current and queued downloads will also be canceled.',
      one:
          'Delete 1 downloaded track ($size)? Current and queued downloads will also be canceled.',
      zero:
          'Delete all downloaded content ($size)? Current and queued downloads will also be canceled.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllDownloadsButton => 'Delete all';

  @override
  String downloadSizeBytes(int count) {
    return '$count B';
  }

  @override
  String downloadSizeKilobytes(String value) {
    return '$value KB';
  }

  @override
  String downloadSizeMegabytes(String value) {
    return '$value MB';
  }

  @override
  String downloadSizeGigabytes(String value) {
    return '$value GB';
  }

  @override
  String get downloadsUnavailableMessage =>
      'Downloads are not available on this device.';

  @override
  String get noDownloadedTracksMessage => 'No downloaded tracks yet.';

  @override
  String get noDownloadedAuthorsMessage =>
      'No authors with downloaded tracks yet.';

  @override
  String get noDownloadedAlbumsMessage =>
      'No albums with downloaded tracks yet.';

  @override
  String get noDownloadedPlaylistsMessage => 'No downloaded playlists yet.';

  @override
  String get downloadedAuthorNotFound =>
      'This downloaded author is no longer available.';

  @override
  String get downloadedAlbumNotFound =>
      'This downloaded album is no longer available.';

  @override
  String get downloadedPlaylistNotFound =>
      'This downloaded playlist is no longer available.';

  @override
  String get noDownloadedTracksForAuthor =>
      'There are no downloaded tracks by this author.';

  @override
  String get noDownloadedTracksInAlbum =>
      'There are no downloaded tracks in this album.';

  @override
  String get noDownloadedTracksInPlaylist =>
      'There are no downloaded tracks in this playlist.';

  @override
  String get downloadedPlaylistLoadFailed =>
      'Failed to load the downloaded playlist.';

  @override
  String get downloadNotificationRunningTitle => 'Downloading tracks';

  @override
  String get downloadNotificationRunningBody => 'Download progress';

  @override
  String get downloadNotificationFailedTitle => 'Downloads finished';

  @override
  String get downloadNotificationFailedBody =>
      'Failed to download some tracks.';

  @override
  String get downloadNotificationCancelAction => 'Cancel';

  @override
  String get downloadNotificationChannelName => 'Track downloads';

  @override
  String get downloadNotificationChannelDescription =>
      'Track download progress and errors';

  @override
  String get downloadLowStorageNotificationTitle => 'Downloads stopped';

  @override
  String get downloadLowStorageNotificationBody =>
      'Not enough storage. Free some space before downloading again.';

  @override
  String get tracksTitle => 'Tracks';

  @override
  String get lastAddedTracksTitle => 'Last added';

  @override
  String get viewMoreButton => 'View more';

  @override
  String get noTracksYet => 'No tracks yet.';

  @override
  String get lastAddedTracksLoadFailed => 'Failed to load last added tracks.';

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
  String get authorsTitle => 'Authors';

  @override
  String get popularAuthorsTitle => 'Popular Authors';

  @override
  String get playMyVibeButton => 'Play my vibe';

  @override
  String get playAuthorButton => 'Play author';

  @override
  String get noPlayableAuthorTracks =>
      'No playable tracks by this artist. Playing My Vibe.';

  @override
  String get noPublishedAuthorsYet => 'No published authors yet.';

  @override
  String get authorNotFound => 'Author not found.';

  @override
  String get authorLoadFailed => 'Failed to load the author.';

  @override
  String get albumNotFound => 'Album not found.';

  @override
  String get albumLoadFailed => 'Failed to load the album.';

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
  String get trackNotFound => 'Track not found.';

  @override
  String get trackLoadFailed => 'Failed to load the track.';

  @override
  String get trackScreenTitle => 'Track';

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
  String get copyTrackLinkTooltip => 'Copy track link';

  @override
  String get trackLinkCopied => 'Track link copied.';

  @override
  String get removeFromFavoritesTooltip => 'Remove from favorites';

  @override
  String get addToFavoritesTooltip => 'Add to favorites';

  @override
  String get removeFromDislikesTooltip => 'Remove from dislikes';

  @override
  String get addToDislikesTooltip => 'Add to dislikes';

  @override
  String get trackDisliked => 'Disliked';

  @override
  String get favoriteUpdateFailed => 'Failed to update favorite.';

  @override
  String get dislikeUpdateFailed => 'Failed to update dislike.';

  @override
  String get addToPlaylistsTooltip => 'Add to playlists';

  @override
  String get removeFromPlaylistTooltip => 'Remove from playlist';

  @override
  String get saveTrackToDownloadsTooltip => 'Save to downloads';

  @override
  String get saveTrackToDownloadsFailed => 'Could not download this track.';
}
