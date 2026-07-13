import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Esketit Music'**
  String get appTitle;

  /// No description provided for @catalogTitle.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogTitle;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @myLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibraryTitle;

  /// No description provided for @homeNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeNavigationLabel;

  /// No description provided for @searchNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchNavigationLabel;

  /// No description provided for @myLibraryNavigationLabel.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get myLibraryNavigationLabel;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUpTitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @createAccountLink.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccountLink;

  /// No description provided for @passwordHelperText.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordHelperText;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @forbiddenActionMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have access to this action.'**
  String get forbiddenActionMessage;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get sessionExpiredMessage;

  /// No description provided for @requestFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Request failed. Please try again.'**
  String get requestFailedMessage;

  /// No description provided for @unknownErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownErrorMessage;

  /// No description provided for @loginRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequiredTitle;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature requires login.'**
  String get loginRequiredMessage;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @goToLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Go to login'**
  String get goToLoginButton;

  /// No description provided for @bottomPlayerNoTrackSelected.
  ///
  /// In en, this message translates to:
  /// **'No track selected'**
  String get bottomPlayerNoTrackSelected;

  /// No description provided for @bottomPlayerUnknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get bottomPlayerUnknownArtist;

  /// No description provided for @guestModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest mode'**
  String get guestModeLabel;

  /// No description provided for @signInToUnlockProtectedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Sign in to unlock protected features'**
  String get signInToUnlockProtectedFeatures;

  /// No description provided for @nativeLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get nativeLanguageName;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageAutoOption.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsLanguageAutoOption;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// No description provided for @settingsThemeLightOption.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLightOption;

  /// No description provided for @settingsThemeDarkOption.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDarkOption;

  /// No description provided for @settingsThemeAutoOption.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAutoOption;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersionLabel(String version);

  /// No description provided for @signInToSeeYourPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your playlists.'**
  String get signInToSeeYourPlaylists;

  /// No description provided for @yourPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get yourPlaylistsTitle;

  /// No description provided for @newPlaylistButton.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newPlaylistButton;

  /// No description provided for @playlistsDescription.
  ///
  /// In en, this message translates to:
  /// **'Favorites is managed automatically. Everything else is fully editable.'**
  String get playlistsDescription;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Create your first one.'**
  String get noPlaylistsYet;

  /// No description provided for @tracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracksTitle;

  /// No description provided for @lastAddedTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Last added'**
  String get lastAddedTracksTitle;

  /// No description provided for @viewMoreButton.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get viewMoreButton;

  /// No description provided for @noTracksYet.
  ///
  /// In en, this message translates to:
  /// **'No tracks yet.'**
  String get noTracksYet;

  /// No description provided for @lastAddedTracksLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load last added tracks.'**
  String get lastAddedTracksLoadFailed;

  /// No description provided for @noTracksInAlbumYet.
  ///
  /// In en, this message translates to:
  /// **'No tracks in this album yet.'**
  String get noTracksInAlbumYet;

  /// No description provided for @albumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albumsTitle;

  /// No description provided for @noPublishedAlbumsYet.
  ///
  /// In en, this message translates to:
  /// **'No published albums yet.'**
  String get noPublishedAlbumsYet;

  /// No description provided for @authorAlbumsDisplayModeMenu.
  ///
  /// In en, this message translates to:
  /// **'Album display'**
  String get authorAlbumsDisplayModeMenu;

  /// No description provided for @authorAlbumsDisplayModeExpandedOption.
  ///
  /// In en, this message translates to:
  /// **'Expanded'**
  String get authorAlbumsDisplayModeExpandedOption;

  /// No description provided for @authorAlbumsDisplayModeCompactOption.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get authorAlbumsDisplayModeCompactOption;

  /// No description provided for @featuredAuthorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Featured Authors'**
  String get featuredAuthorsTitle;

  /// No description provided for @playMyVibeButton.
  ///
  /// In en, this message translates to:
  /// **'Play my vibe'**
  String get playMyVibeButton;

  /// No description provided for @noPublishedAuthorsYet.
  ///
  /// In en, this message translates to:
  /// **'No published authors yet.'**
  String get noPublishedAuthorsYet;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search authors, albums, tracks, playlists'**
  String get searchHint;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @recentSearchQueriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get recentSearchQueriesTitle;

  /// No description provided for @searchResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 results} =1{1 result} other{{count} results}}'**
  String searchResultsCount(int count);

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\".'**
  String noResultsFound(String query);

  /// No description provided for @endOfResults.
  ///
  /// In en, this message translates to:
  /// **'End of results'**
  String get endOfResults;

  /// No description provided for @authorTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorTypeLabel;

  /// No description provided for @albumTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumTypeLabel;

  /// No description provided for @albumWithReleaseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Album • {date}'**
  String albumWithReleaseDateLabel(String date);

  /// No description provided for @releaseDateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Release date unknown'**
  String get releaseDateUnknown;

  /// No description provided for @playlistTracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 tracks} =1{1 track} other{{count} tracks}}'**
  String playlistTracksCount(int count);

  /// No description provided for @systemPlaylistLabel.
  ///
  /// In en, this message translates to:
  /// **'System playlist'**
  String get systemPlaylistLabel;

  /// No description provided for @playlistVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get playlistVisibilityPrivate;

  /// No description provided for @playlistVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get playlistVisibilityPublic;

  /// No description provided for @playlistVisibilityShared.
  ///
  /// In en, this message translates to:
  /// **'Shared'**
  String get playlistVisibilityShared;

  /// No description provided for @addToPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to playlists'**
  String get addToPlaylistsTitle;

  /// No description provided for @createCustomPlaylistFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a custom playlist first.'**
  String get createCustomPlaylistFirst;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @newPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylistTitle;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @editPlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist'**
  String get editPlaylistTitle;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @coverImageUrlOrPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL or path'**
  String get coverImageUrlOrPathLabel;

  /// No description provided for @chooseCoverImageButton.
  ///
  /// In en, this message translates to:
  /// **'Choose cover image'**
  String get chooseCoverImageButton;

  /// No description provided for @selectedCoverImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover: {fileName}'**
  String selectedCoverImageLabel(String fileName);

  /// No description provided for @clearCoverImageSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear cover image selection'**
  String get clearCoverImageSelectionTooltip;

  /// No description provided for @visibilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibilityLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required.'**
  String get descriptionRequired;

  /// No description provided for @playlistFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistFallbackTitle;

  /// No description provided for @playlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found.'**
  String get playlistNotFound;

  /// No description provided for @playlistHasNoTracksYet.
  ///
  /// In en, this message translates to:
  /// **'This playlist has no tracks yet.'**
  String get playlistHasNoTracksYet;

  /// No description provided for @copyPlaylistLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy playlist link'**
  String get copyPlaylistLinkTooltip;

  /// No description provided for @playlistLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Playlist link copied.'**
  String get playlistLinkCopied;

  /// No description provided for @deletePlaylistTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist?'**
  String get deletePlaylistTitle;

  /// No description provided for @deletePlaylistMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deletePlaylistMessage(String name);

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @trackNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get trackNotAvailable;

  /// No description provided for @trackScreenNowPlayingLabel.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get trackScreenNowPlayingLabel;

  /// No description provided for @trackScreenNoTrackSelectedMessage.
  ///
  /// In en, this message translates to:
  /// **'No track is currently selected.'**
  String get trackScreenNoTrackSelectedMessage;

  /// No description provided for @trackScreenLyricsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get trackScreenLyricsSectionTitle;

  /// No description provided for @trackScreenLyricsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are not available for this track.'**
  String get trackScreenLyricsNotAvailable;

  /// No description provided for @trackScreenLyricsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load lyrics.'**
  String get trackScreenLyricsLoadFailed;

  /// No description provided for @trackLyricsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get trackLyricsScreenTitle;

  /// No description provided for @trackScreenLyricsFullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open lyrics fullscreen'**
  String get trackScreenLyricsFullscreenTooltip;

  /// No description provided for @trackScreenGoToAlbumAction.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get trackScreenGoToAlbumAction;

  /// No description provided for @trackScreenGoToAuthorAction.
  ///
  /// In en, this message translates to:
  /// **'Go to author'**
  String get trackScreenGoToAuthorAction;

  /// No description provided for @trackScreenChooseAuthorTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose author'**
  String get trackScreenChooseAuthorTitle;

  /// No description provided for @removeFromFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesTooltip;

  /// No description provided for @addToFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavoritesTooltip;

  /// No description provided for @addToPlaylistsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to playlists'**
  String get addToPlaylistsTooltip;

  /// No description provided for @removeFromPlaylistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylistTooltip;

  /// No description provided for @saveTrackToDownloadsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save to downloads'**
  String get saveTrackToDownloadsTooltip;

  /// No description provided for @saveTrackToDownloadsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not download this track.'**
  String get saveTrackToDownloadsFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
