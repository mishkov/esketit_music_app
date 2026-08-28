// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Эщкере Музыка';

  @override
  String get catalogTitle => 'Каталог';

  @override
  String get searchTitle => 'Поиск';

  @override
  String get myLibraryTitle => 'Моя библиотека';

  @override
  String get homeNavigationLabel => 'Главная';

  @override
  String get searchNavigationLabel => 'Поиск';

  @override
  String get myLibraryNavigationLabel => 'Моя библиотека';

  @override
  String get signInTitle => 'Войти';

  @override
  String get signUpTitle => 'Регистрация';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get signInButton => 'Войти';

  @override
  String get createAccountButton => 'Создать аккаунт';

  @override
  String get createAccountLink => 'Создать аккаунт';

  @override
  String get passwordHelperText => 'Используйте не менее 8 символов.';

  @override
  String get enterYourEmail => 'Введите email';

  @override
  String get enterValidEmail => 'Введите корректный email';

  @override
  String get enterYourPassword => 'Введите пароль';

  @override
  String get passwordMinLength => 'Пароль должен содержать не менее 8 символов';

  @override
  String get forbiddenActionMessage => 'У вас нет доступа к этому действию.';

  @override
  String get sessionExpiredMessage => 'Сессия истекла. Войдите снова.';

  @override
  String get requestFailedMessage =>
      'Не удалось выполнить запрос. Попробуйте еще раз.';

  @override
  String get unknownErrorMessage => 'Что-то пошло не так. Попробуйте еще раз.';

  @override
  String get loginRequiredTitle => 'Требуется вход';

  @override
  String get loginRequiredMessage => 'Для этой функции требуется вход.';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get goToLoginButton => 'Перейти ко входу';

  @override
  String get bottomPlayerNoTrackSelected => 'Трек не выбран';

  @override
  String get bottomPlayerUnknownArtist => 'Неизвестный исполнитель';

  @override
  String get bottomPlayerOpenFullscreenTooltip => 'Открыть плеер на весь экран';

  @override
  String get fullscreenPlayerCloseTooltip => 'Закрыть полноэкранный плеер';

  @override
  String get repeatQueueTooltip => 'Повторять очередь';

  @override
  String get repeatTrackTooltip => 'Повторять трек';

  @override
  String get repeatOffTooltip => 'Выключить повтор';

  @override
  String get fullscreenInactiveControlsSettingsTooltip =>
      'Настроить элементы неактивного режима';

  @override
  String get fullscreenInactiveControlsMenuTitle =>
      'Выберите элементы, которые будут видны в «неактивном» режиме';

  @override
  String get fullscreenInactiveControlTrackName => 'Название трека';

  @override
  String get fullscreenInactiveControlTrackAuthors => 'Исполнители трека';

  @override
  String get fullscreenInactiveControlProgressIndicator =>
      'Индикатор прогресса трека';

  @override
  String get fullscreenInactiveControlTrackTiming =>
      'Текущее время воспроизведения и длительность';

  @override
  String get fullscreenInactiveControlPlaybackButtons =>
      'Кнопки назад/воспроизведение/вперёд';

  @override
  String get fullscreenInactiveControlFavoriteButton =>
      'Кнопки избранного и дизлайка';

  @override
  String get guestModeLabel => 'Гостевой режим';

  @override
  String get signInToUnlockProtectedFeatures =>
      'Войдите, чтобы открыть защищенные функции';

  @override
  String get nativeLanguageName => 'Русский';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsLanguageLabel => 'Язык';

  @override
  String get settingsLanguageAutoOption => 'Авто';

  @override
  String get settingsThemeLabel => 'Тема';

  @override
  String get settingsThemeLightOption => 'Светлая';

  @override
  String get settingsThemeDarkOption => 'Тёмная';

  @override
  String get settingsThemeAutoOption => 'Авто';

  @override
  String get settingsUseTrackAlbumCoverColorSchemeSeedLabel =>
      'Подбирать цвет приложения по обложке трека';

  @override
  String get signOutButton => 'Выйти';

  @override
  String appVersionLabel(String version) {
    return 'Версия $version';
  }

  @override
  String get signInToSeeYourPlaylists =>
      'Войдите, чтобы увидеть свои плейлисты.';

  @override
  String get likesTitle => 'Лайки';

  @override
  String get dislikesTitle => 'Дизлайки';

  @override
  String get signInToViewLibraryItem => 'Войдите для просмотра';

  @override
  String get playlistsSectionTitle => 'Плейлисты';

  @override
  String get createPlaylistTooltip => 'Создать плейлист';

  @override
  String get signInToManagePlaylists =>
      'Войдите, чтобы создавать плейлисты и управлять ими.';

  @override
  String get playlistsLoadFailed => 'Не удалось загрузить плейлисты.';

  @override
  String get yourPlaylistsTitle => 'Ваши плейлисты';

  @override
  String get newPlaylistButton => 'Новый';

  @override
  String get playlistsDescription =>
      'Избранное и дизлайки управляются автоматически. Остальные плейлисты можно редактировать.';

  @override
  String get noPlaylistsYet => 'Плейлистов пока нет. Создайте первый.';

  @override
  String get downloadedTitle => 'Скачанное';

  @override
  String get deleteAllDownloadsTooltip => 'Удалить все скачанные треки';

  @override
  String get downloadedTracksTitle => 'Треки';

  @override
  String get downloadedAuthorsTitle => 'Авторы';

  @override
  String get downloadedAlbumsTitle => 'Альбомы';

  @override
  String get downloadedPlaylistsTitle => 'Плейлисты';

  @override
  String downloadedItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count элемента',
      many: '$count элементов',
      few: '$count элемента',
      one: '$count элемент',
      zero: '0 элементов',
    );
    return '$_temp0';
  }

  @override
  String get trackDownloadQueuedTooltip => 'В очереди на скачивание';

  @override
  String get trackDownloadingTooltip => 'Скачивается';

  @override
  String get trackDownloadedTooltip => 'Скачано';

  @override
  String get trackDownloadFailedTooltip => 'Не удалось скачать';

  @override
  String get downloadManagerTitle => 'Загрузки';

  @override
  String get currentDownloadSectionTitle => 'Текущая загрузка';

  @override
  String get queuedDownloadsSectionTitle => 'В очереди';

  @override
  String get failedDownloadsSectionTitle => 'Не удалось скачать';

  @override
  String get noDownloadActivity => 'Нет активных или неудачных загрузок.';

  @override
  String get cancelDownloadTooltip => 'Отменить скачивание';

  @override
  String get clearButton => 'Очистить';

  @override
  String get downloadQueuedStatus => 'В очереди';

  @override
  String get downloadInProgressStatus => 'Скачивается';

  @override
  String get downloadWaitingToRetryStatus => 'Ожидание новой попытки';

  @override
  String downloadProgressPercent(int percent) {
    return '$percent%';
  }

  @override
  String downloadsQueuedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'В очереди $count трека',
      many: 'В очереди $count треков',
      few: 'В очереди $count трека',
      one: 'В очереди $count трек',
      zero: 'В очереди нет треков',
    );
    return '$_temp0';
  }

  @override
  String downloadsFailedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Не удалось скачать $count трека',
      many: 'Не удалось скачать $count треков',
      few: 'Не удалось скачать $count трека',
      one: 'Не удалось скачать $count трек',
    );
    return '$_temp0';
  }

  @override
  String get downloadFailuresRemainMessage =>
      'Откройте загрузки, чтобы увидеть подробности, или очистите это сообщение.';

  @override
  String get downloadWaitingToStart => 'Ожидание начала';

  @override
  String downloadingTrackName(String trackName) {
    return 'Скачивается $trackName';
  }

  @override
  String downloadWaitingToRetryTrack(String trackName) {
    return 'Ожидание новой попытки скачать $trackName';
  }

  @override
  String get downloadFailureNetwork => 'Ошибка сети';

  @override
  String get downloadFailureServer => 'Ошибка сервера';

  @override
  String get downloadFailureStorage => 'Ошибка хранилища';

  @override
  String get downloadFailureInsufficientStorage => 'Недостаточно места';

  @override
  String get downloadFailureInvalidResponse => 'Некорректный ответ сервера';

  @override
  String get downloadFailureUnknown => 'Неизвестная ошибка';

  @override
  String get downloadAlbumButton => 'Скачать альбом';

  @override
  String get downloadPlaylistButton => 'Скачать плейлист';

  @override
  String get cancelDownloadButton => 'Отменить скачивание';

  @override
  String get removeDownloadButton => 'Удалить скачанное';

  @override
  String get deleteAllDownloadsTitle => 'Удалить все загрузки?';

  @override
  String deleteAllDownloadsMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Удалить $count скачанного трека? Текущая загрузка и очередь также будут отменены.',
      many:
          'Удалить $count скачанных треков? Текущая загрузка и очередь также будут отменены.',
      few:
          'Удалить $count скачанных трека? Текущая загрузка и очередь также будут отменены.',
      one:
          'Удалить $count скачанный трек? Текущая загрузка и очередь также будут отменены.',
      zero:
          'Удалить все скачанные материалы? Текущая загрузка и очередь также будут отменены.',
    );
    return '$_temp0';
  }

  @override
  String deleteAllDownloadsMessageWithSize(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Удалить $count скачанного трека ($size)? Текущая загрузка и очередь также будут отменены.',
      many:
          'Удалить $count скачанных треков ($size)? Текущая загрузка и очередь также будут отменены.',
      few:
          'Удалить $count скачанных трека ($size)? Текущая загрузка и очередь также будут отменены.',
      one:
          'Удалить $count скачанный трек ($size)? Текущая загрузка и очередь также будут отменены.',
      zero:
          'Удалить все скачанные материалы ($size)? Текущая загрузка и очередь также будут отменены.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAllDownloadsButton => 'Удалить всё';

  @override
  String downloadSizeBytes(int count) {
    return '$count Б';
  }

  @override
  String downloadSizeKilobytes(String value) {
    return '$value КБ';
  }

  @override
  String downloadSizeMegabytes(String value) {
    return '$value МБ';
  }

  @override
  String downloadSizeGigabytes(String value) {
    return '$value ГБ';
  }

  @override
  String get downloadsUnavailableMessage =>
      'Загрузки недоступны на этом устройстве.';

  @override
  String get noDownloadedTracksMessage => 'Скачанных треков пока нет.';

  @override
  String get noDownloadedAuthorsMessage =>
      'Авторов со скачанными треками пока нет.';

  @override
  String get noDownloadedAlbumsMessage =>
      'Альбомов со скачанными треками пока нет.';

  @override
  String get noDownloadedPlaylistsMessage => 'Скачанных плейлистов пока нет.';

  @override
  String get downloadedAuthorNotFound =>
      'Этот скачанный автор больше недоступен.';

  @override
  String get downloadedAlbumNotFound =>
      'Этот скачанный альбом больше недоступен.';

  @override
  String get downloadedPlaylistNotFound =>
      'Этот скачанный плейлист больше недоступен.';

  @override
  String get noDownloadedTracksForAuthor =>
      'У этого автора нет скачанных треков.';

  @override
  String get noDownloadedTracksInAlbum =>
      'В этом альбоме нет скачанных треков.';

  @override
  String get noDownloadedTracksInPlaylist =>
      'В этом плейлисте нет скачанных треков.';

  @override
  String get downloadedPlaylistLoadFailed =>
      'Не удалось загрузить скачанный плейлист.';

  @override
  String get downloadNotificationRunningTitle => 'Скачивание треков';

  @override
  String get downloadNotificationRunningBody => 'Прогресс скачивания';

  @override
  String get downloadNotificationFailedTitle => 'Загрузки завершены';

  @override
  String get downloadNotificationFailedBody =>
      'Некоторые треки скачать не удалось.';

  @override
  String get downloadNotificationCancelAction => 'Отменить';

  @override
  String get downloadNotificationChannelName => 'Скачивание треков';

  @override
  String get downloadNotificationChannelDescription =>
      'Прогресс и ошибки скачивания треков';

  @override
  String get downloadLowStorageNotificationTitle => 'Загрузки остановлены';

  @override
  String get downloadLowStorageNotificationBody =>
      'Недостаточно места. Освободите память перед новой попыткой.';

  @override
  String get tracksTitle => 'Треки';

  @override
  String get lastAddedTracksTitle => 'Последние добавленные';

  @override
  String get viewMoreButton => 'Показать ещё';

  @override
  String get noTracksYet => 'Треков пока нет.';

  @override
  String get lastAddedTracksLoadFailed =>
      'Не удалось загрузить последние добавленные треки.';

  @override
  String get noTracksInAlbumYet => 'В этом альбоме пока нет треков.';

  @override
  String get albumsTitle => 'Альбомы';

  @override
  String get noPublishedAlbumsYet => 'Опубликованных альбомов пока нет.';

  @override
  String get authorAlbumsDisplayModeMenu => 'Отображение альбомов';

  @override
  String get authorAlbumsDisplayModeExpandedOption => 'Развернуто';

  @override
  String get authorAlbumsDisplayModeCompactOption => 'Компактно';

  @override
  String get authorsTitle => 'Авторы';

  @override
  String get popularAuthorsTitle => 'Популярные авторы';

  @override
  String get playMyVibeButton => 'Включить мой вайб';

  @override
  String get playAuthorButton => 'Включить автора';

  @override
  String get noPlayableAuthorTracks =>
      'У этого исполнителя нет доступных треков. Включаем «Мой вайб».';

  @override
  String get noPublishedAuthorsYet => 'Опубликованных авторов пока нет.';

  @override
  String get authorNotFound => 'Автор не найден.';

  @override
  String get authorLoadFailed => 'Не удалось загрузить автора.';

  @override
  String get albumNotFound => 'Альбом не найден.';

  @override
  String get albumLoadFailed => 'Не удалось загрузить альбом.';

  @override
  String get searchHint => 'Искать авторов, альбомы, треки, плейлисты';

  @override
  String get clearSearchTooltip => 'Очистить поиск';

  @override
  String get recentSearchQueriesTitle => 'Недавние поисковые запросы';

  @override
  String searchResultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '$count результат',
      zero: '0 результатов',
    );
    return '$_temp0';
  }

  @override
  String noResultsFound(String query) {
    return 'По запросу \"$query\" ничего не найдено.';
  }

  @override
  String get endOfResults => 'Результаты закончились';

  @override
  String get authorTypeLabel => 'Автор';

  @override
  String get albumTypeLabel => 'Альбом';

  @override
  String albumWithReleaseDateLabel(String date) {
    return 'Альбом • $date';
  }

  @override
  String get releaseDateUnknown => 'Дата релиза неизвестна';

  @override
  String playlistTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count трека',
      many: '$count треков',
      few: '$count трека',
      one: '$count трек',
      zero: '0 треков',
    );
    return '$_temp0';
  }

  @override
  String get systemPlaylistLabel => 'Системный плейлист';

  @override
  String get playlistVisibilityPrivate => 'Приватный';

  @override
  String get playlistVisibilityPublic => 'Публичный';

  @override
  String get playlistVisibilityShared => 'Общий';

  @override
  String get addToPlaylistsTitle => 'Добавить в плейлисты';

  @override
  String get createCustomPlaylistFirst =>
      'Сначала создайте пользовательский плейлист.';

  @override
  String get addButton => 'Добавить';

  @override
  String get newPlaylistTitle => 'Новый плейлист';

  @override
  String get createButton => 'Создать';

  @override
  String get editPlaylistTitle => 'Редактировать плейлист';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get nameLabel => 'Название';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get coverImageUrlOrPathLabel => 'URL или путь к обложке';

  @override
  String get chooseCoverImageButton => 'Выбрать обложку';

  @override
  String selectedCoverImageLabel(String fileName) {
    return 'Обложка: $fileName';
  }

  @override
  String get clearCoverImageSelectionTooltip => 'Очистить выбор обложки';

  @override
  String get visibilityLabel => 'Видимость';

  @override
  String get nameRequired => 'Название обязательно.';

  @override
  String get descriptionRequired => 'Описание обязательно.';

  @override
  String get playlistFallbackTitle => 'Плейлист';

  @override
  String get playlistNotFound => 'Плейлист не найден.';

  @override
  String get playlistHasNoTracksYet => 'В этом плейлисте пока нет треков.';

  @override
  String get copyPlaylistLinkTooltip => 'Скопировать ссылку на плейлист';

  @override
  String get playlistLinkCopied => 'Ссылка на плейлист скопирована.';

  @override
  String get deletePlaylistTitle => 'Удалить плейлист?';

  @override
  String deletePlaylistMessage(String name) {
    return 'Удалить \"$name\"? Это действие нельзя отменить.';
  }

  @override
  String get deleteButton => 'Удалить';

  @override
  String get trackNotAvailable => 'Недоступно';

  @override
  String get trackNotFound => 'Трек не найден.';

  @override
  String get trackLoadFailed => 'Не удалось загрузить трек.';

  @override
  String get trackScreenTitle => 'Трек';

  @override
  String get trackScreenNowPlayingLabel => 'СЕЙЧАС ИГРАЕТ';

  @override
  String get trackScreenNoTrackSelectedMessage =>
      'Сейчас ни один трек не выбран.';

  @override
  String get trackScreenLyricsSectionTitle => 'Текст песни';

  @override
  String get trackScreenLyricsNotAvailable =>
      'Для этого трека текст песни недоступен.';

  @override
  String get trackScreenLyricsLoadFailed => 'Не удалось загрузить текст песни.';

  @override
  String get trackLyricsScreenTitle => 'Текст песни';

  @override
  String get trackScreenLyricsFullscreenTooltip =>
      'Открыть текст песни на весь экран';

  @override
  String get trackScreenGoToAlbumAction => 'Перейти к альбому';

  @override
  String get trackScreenGoToAuthorAction => 'Перейти к автору';

  @override
  String get trackScreenChooseAuthorTitle => 'Выберите автора';

  @override
  String get copyTrackLinkTooltip => 'Скопировать ссылку на трек';

  @override
  String get trackLinkCopied => 'Ссылка на трек скопирована.';

  @override
  String get removeFromFavoritesTooltip => 'Убрать из избранного';

  @override
  String get addToFavoritesTooltip => 'Добавить в избранное';

  @override
  String get removeFromDislikesTooltip => 'Убрать из дизлайков';

  @override
  String get addToDislikesTooltip => 'Добавить в дизлайки';

  @override
  String get trackDisliked => 'Не нравится';

  @override
  String get favoriteUpdateFailed => 'Не удалось обновить избранное.';

  @override
  String get dislikeUpdateFailed => 'Не удалось обновить дизлайк.';

  @override
  String get addToPlaylistsTooltip => 'Добавить в плейлисты';

  @override
  String get removeFromPlaylistTooltip => 'Убрать из плейлиста';

  @override
  String get saveTrackToDownloadsTooltip => 'Сохранить в загрузки';

  @override
  String get saveTrackToDownloadsFailed => 'Не удалось скачать этот трек.';
}
