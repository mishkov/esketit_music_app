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

  /// No description provided for @bottomPlayerOpenFullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open fullscreen player'**
  String get bottomPlayerOpenFullscreenTooltip;

  /// No description provided for @fullscreenPlayerCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close fullscreen player'**
  String get fullscreenPlayerCloseTooltip;

  /// No description provided for @fullscreenInactiveControlsSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Customize inactive controls'**
  String get fullscreenInactiveControlsSettingsTooltip;

  /// No description provided for @fullscreenInactiveControlsMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Select controls that will be visible in ‘inactive’ mode'**
  String get fullscreenInactiveControlsMenuTitle;

  /// No description provided for @fullscreenInactiveControlTrackName.
  ///
  /// In en, this message translates to:
  /// **'Track name'**
  String get fullscreenInactiveControlTrackName;

  /// No description provided for @fullscreenInactiveControlTrackAuthors.
  ///
  /// In en, this message translates to:
  /// **'Track authors'**
  String get fullscreenInactiveControlTrackAuthors;

  /// No description provided for @fullscreenInactiveControlProgressIndicator.
  ///
  /// In en, this message translates to:
  /// **'Track progress indicator'**
  String get fullscreenInactiveControlProgressIndicator;

  /// No description provided for @fullscreenInactiveControlTrackTiming.
  ///
  /// In en, this message translates to:
  /// **'Track current playing time & duration'**
  String get fullscreenInactiveControlTrackTiming;

  /// No description provided for @fullscreenInactiveControlPlaybackButtons.
  ///
  /// In en, this message translates to:
  /// **'Previous/play/next buttons'**
  String get fullscreenInactiveControlPlaybackButtons;

  /// No description provided for @fullscreenInactiveControlFavoriteButton.
  ///
  /// In en, this message translates to:
  /// **'Favorite and dislike buttons'**
  String get fullscreenInactiveControlFavoriteButton;

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

  /// No description provided for @settingsUseTrackAlbumCoverColorSchemeSeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Set app color based on track album cover'**
  String get settingsUseTrackAlbumCoverColorSchemeSeedLabel;

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

  /// No description provided for @likesTitle.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likesTitle;

  /// No description provided for @dislikesTitle.
  ///
  /// In en, this message translates to:
  /// **'Dislikes'**
  String get dislikesTitle;

  /// No description provided for @signInToViewLibraryItem.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view'**
  String get signInToViewLibraryItem;

  /// No description provided for @playlistsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistsSectionTitle;

  /// No description provided for @createPlaylistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get createPlaylistTooltip;

  /// No description provided for @signInToManagePlaylists.
  ///
  /// In en, this message translates to:
  /// **'Sign in to create and manage playlists.'**
  String get signInToManagePlaylists;

  /// No description provided for @playlistsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load playlists.'**
  String get playlistsLoadFailed;

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
  /// **'Favorites and Dislikes are managed automatically. Everything else is fully editable.'**
  String get playlistsDescription;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Create your first one.'**
  String get noPlaylistsYet;

  /// No description provided for @downloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadedTitle;

  /// No description provided for @deleteAllDownloadsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads'**
  String get deleteAllDownloadsTooltip;

  /// No description provided for @downloadedTracksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get downloadedTracksTitle;

  /// No description provided for @downloadedAuthorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get downloadedAuthorsTitle;

  /// No description provided for @downloadedAlbumsTitle.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get downloadedAlbumsTitle;

  /// No description provided for @downloadedPlaylistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get downloadedPlaylistsTitle;

  /// No description provided for @downloadedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 items} =1{1 item} other{{count} items}}'**
  String downloadedItemsCount(int count);

  /// No description provided for @trackDownloadQueuedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Queued for download'**
  String get trackDownloadQueuedTooltip;

  /// No description provided for @trackDownloadingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get trackDownloadingTooltip;

  /// No description provided for @trackDownloadedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get trackDownloadedTooltip;

  /// No description provided for @trackDownloadFailedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get trackDownloadFailedTooltip;

  /// No description provided for @downloadManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadManagerTitle;

  /// No description provided for @currentDownloadSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentDownloadSectionTitle;

  /// No description provided for @queuedDownloadsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queuedDownloadsSectionTitle;

  /// No description provided for @failedDownloadsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failedDownloadsSectionTitle;

  /// No description provided for @noDownloadActivity.
  ///
  /// In en, this message translates to:
  /// **'There are no active or failed downloads.'**
  String get noDownloadActivity;

  /// No description provided for @cancelDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownloadTooltip;

  /// No description provided for @clearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearButton;

  /// No description provided for @downloadQueuedStatus.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get downloadQueuedStatus;

  /// No description provided for @downloadInProgressStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadInProgressStatus;

  /// No description provided for @downloadWaitingToRetryStatus.
  ///
  /// In en, this message translates to:
  /// **'Waiting to try again'**
  String get downloadWaitingToRetryStatus;

  /// No description provided for @downloadProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String downloadProgressPercent(int percent);

  /// No description provided for @downloadsQueuedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tracks queued} =1{1 track queued} other{{count} tracks queued}}'**
  String downloadsQueuedCount(int count);

  /// No description provided for @downloadsFailedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Failed to download 1 track} other{Failed to download {count} tracks}}'**
  String downloadsFailedCount(int count);

  /// No description provided for @downloadFailuresRemainMessage.
  ///
  /// In en, this message translates to:
  /// **'Open downloads for details or clear this message.'**
  String get downloadFailuresRemainMessage;

  /// No description provided for @downloadWaitingToStart.
  ///
  /// In en, this message translates to:
  /// **'Waiting to start'**
  String get downloadWaitingToStart;

  /// No description provided for @downloadingTrackName.
  ///
  /// In en, this message translates to:
  /// **'Downloading {trackName}'**
  String downloadingTrackName(String trackName);

  /// No description provided for @downloadWaitingToRetryTrack.
  ///
  /// In en, this message translates to:
  /// **'Waiting to try {trackName} again'**
  String downloadWaitingToRetryTrack(String trackName);

  /// No description provided for @downloadFailureNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get downloadFailureNetwork;

  /// No description provided for @downloadFailureServer.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get downloadFailureServer;

  /// No description provided for @downloadFailureStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage error'**
  String get downloadFailureStorage;

  /// No description provided for @downloadFailureInsufficientStorage.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage'**
  String get downloadFailureInsufficientStorage;

  /// No description provided for @downloadFailureInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid server response'**
  String get downloadFailureInvalidResponse;

  /// No description provided for @downloadFailureUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get downloadFailureUnknown;

  /// No description provided for @downloadAlbumButton.
  ///
  /// In en, this message translates to:
  /// **'Download album'**
  String get downloadAlbumButton;

  /// No description provided for @downloadPlaylistButton.
  ///
  /// In en, this message translates to:
  /// **'Download playlist'**
  String get downloadPlaylistButton;

  /// No description provided for @cancelDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownloadButton;

  /// No description provided for @removeDownloadButton.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownloadButton;

  /// No description provided for @deleteAllDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads?'**
  String get deleteAllDownloadsTitle;

  /// No description provided for @deleteAllDownloadsMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Delete all downloaded content? Current and queued downloads will also be canceled.} =1{Delete 1 downloaded track? Current and queued downloads will also be canceled.} other{Delete {count} downloaded tracks? Current and queued downloads will also be canceled.}}'**
  String deleteAllDownloadsMessage(int count);

  /// No description provided for @deleteAllDownloadsMessageWithSize.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Delete all downloaded content ({size})? Current and queued downloads will also be canceled.} =1{Delete 1 downloaded track ({size})? Current and queued downloads will also be canceled.} other{Delete {count} downloaded tracks ({size})? Current and queued downloads will also be canceled.}}'**
  String deleteAllDownloadsMessageWithSize(int count, String size);

  /// No description provided for @deleteAllDownloadsButton.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAllDownloadsButton;

  /// No description provided for @downloadSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{count} B'**
  String downloadSizeBytes(int count);

  /// No description provided for @downloadSizeKilobytes.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String downloadSizeKilobytes(String value);

  /// No description provided for @downloadSizeMegabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String downloadSizeMegabytes(String value);

  /// No description provided for @downloadSizeGigabytes.
  ///
  /// In en, this message translates to:
  /// **'{value} GB'**
  String downloadSizeGigabytes(String value);

  /// No description provided for @downloadsUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Downloads are not available on this device.'**
  String get downloadsUnavailableMessage;

  /// No description provided for @noDownloadedTracksMessage.
  ///
  /// In en, this message translates to:
  /// **'No downloaded tracks yet.'**
  String get noDownloadedTracksMessage;

  /// No description provided for @noDownloadedAuthorsMessage.
  ///
  /// In en, this message translates to:
  /// **'No authors with downloaded tracks yet.'**
  String get noDownloadedAuthorsMessage;

  /// No description provided for @noDownloadedAlbumsMessage.
  ///
  /// In en, this message translates to:
  /// **'No albums with downloaded tracks yet.'**
  String get noDownloadedAlbumsMessage;

  /// No description provided for @noDownloadedPlaylistsMessage.
  ///
  /// In en, this message translates to:
  /// **'No downloaded playlists yet.'**
  String get noDownloadedPlaylistsMessage;

  /// No description provided for @downloadedAuthorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This downloaded author is no longer available.'**
  String get downloadedAuthorNotFound;

  /// No description provided for @downloadedAlbumNotFound.
  ///
  /// In en, this message translates to:
  /// **'This downloaded album is no longer available.'**
  String get downloadedAlbumNotFound;

  /// No description provided for @downloadedPlaylistNotFound.
  ///
  /// In en, this message translates to:
  /// **'This downloaded playlist is no longer available.'**
  String get downloadedPlaylistNotFound;

  /// No description provided for @noDownloadedTracksForAuthor.
  ///
  /// In en, this message translates to:
  /// **'There are no downloaded tracks by this author.'**
  String get noDownloadedTracksForAuthor;

  /// No description provided for @noDownloadedTracksInAlbum.
  ///
  /// In en, this message translates to:
  /// **'There are no downloaded tracks in this album.'**
  String get noDownloadedTracksInAlbum;

  /// No description provided for @noDownloadedTracksInPlaylist.
  ///
  /// In en, this message translates to:
  /// **'There are no downloaded tracks in this playlist.'**
  String get noDownloadedTracksInPlaylist;

  /// No description provided for @downloadedPlaylistLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the downloaded playlist.'**
  String get downloadedPlaylistLoadFailed;

  /// No description provided for @downloadNotificationRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloading tracks'**
  String get downloadNotificationRunningTitle;

  /// No description provided for @downloadNotificationRunningBody.
  ///
  /// In en, this message translates to:
  /// **'Download progress'**
  String get downloadNotificationRunningBody;

  /// No description provided for @downloadNotificationFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads finished'**
  String get downloadNotificationFailedTitle;

  /// No description provided for @downloadNotificationFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Failed to download some tracks.'**
  String get downloadNotificationFailedBody;

  /// No description provided for @downloadNotificationCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadNotificationCancelAction;

  /// No description provided for @downloadNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Track downloads'**
  String get downloadNotificationChannelName;

  /// No description provided for @downloadNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Track download progress and errors'**
  String get downloadNotificationChannelDescription;

  /// No description provided for @downloadLowStorageNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads stopped'**
  String get downloadLowStorageNotificationTitle;

  /// No description provided for @downloadLowStorageNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'Not enough storage. Free some space before downloading again.'**
  String get downloadLowStorageNotificationBody;

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

  /// No description provided for @authorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get authorsTitle;

  /// No description provided for @popularAuthorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Authors'**
  String get popularAuthorsTitle;

  /// No description provided for @playMyVibeButton.
  ///
  /// In en, this message translates to:
  /// **'Play my vibe'**
  String get playMyVibeButton;

  /// No description provided for @playAuthorButton.
  ///
  /// In en, this message translates to:
  /// **'Play author'**
  String get playAuthorButton;

  /// No description provided for @noPlayableAuthorTracks.
  ///
  /// In en, this message translates to:
  /// **'No playable tracks by this artist. Playing My Vibe.'**
  String get noPlayableAuthorTracks;

  /// No description provided for @noPublishedAuthorsYet.
  ///
  /// In en, this message translates to:
  /// **'No published authors yet.'**
  String get noPublishedAuthorsYet;

  /// No description provided for @authorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Author not found.'**
  String get authorNotFound;

  /// No description provided for @authorLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the author.'**
  String get authorLoadFailed;

  /// No description provided for @albumNotFound.
  ///
  /// In en, this message translates to:
  /// **'Album not found.'**
  String get albumNotFound;

  /// No description provided for @albumLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the album.'**
  String get albumLoadFailed;

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

  /// No description provided for @trackNotFound.
  ///
  /// In en, this message translates to:
  /// **'Track not found.'**
  String get trackNotFound;

  /// No description provided for @trackLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load the track.'**
  String get trackLoadFailed;

  /// No description provided for @trackScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackScreenTitle;

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

  /// No description provided for @copyTrackLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy track link'**
  String get copyTrackLinkTooltip;

  /// No description provided for @trackLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Track link copied.'**
  String get trackLinkCopied;

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

  /// No description provided for @removeFromDislikesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from dislikes'**
  String get removeFromDislikesTooltip;

  /// No description provided for @addToDislikesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to dislikes'**
  String get addToDislikesTooltip;

  /// No description provided for @trackDisliked.
  ///
  /// In en, this message translates to:
  /// **'Disliked'**
  String get trackDisliked;

  /// No description provided for @favoriteUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update favorite.'**
  String get favoriteUpdateFailed;

  /// No description provided for @dislikeUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update dislike.'**
  String get dislikeUpdateFailed;

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
