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
  String get signOutButton => 'Выйти';

  @override
  String get signInToSeeYourPlaylists =>
      'Войдите, чтобы увидеть свои плейлисты.';

  @override
  String get yourPlaylistsTitle => 'Ваши плейлисты';

  @override
  String get newPlaylistButton => 'Новый';

  @override
  String get playlistsDescription =>
      'Избранное управляется автоматически. Все остальное можно редактировать.';

  @override
  String get noPlaylistsYet => 'Плейлистов пока нет. Создайте первый.';

  @override
  String get tracksTitle => 'Треки';

  @override
  String get noTracksInAlbumYet => 'В этом альбоме пока нет треков.';

  @override
  String get albumsTitle => 'Альбомы';

  @override
  String get noPublishedAlbumsYet => 'Опубликованных альбомов пока нет.';

  @override
  String get featuredAuthorsTitle => 'Избранные авторы';

  @override
  String get noPublishedAuthorsYet => 'Опубликованных авторов пока нет.';

  @override
  String get searchHint => 'Искать авторов, альбомы, треки';

  @override
  String get clearSearchTooltip => 'Очистить поиск';

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
  String get removeFromFavoritesTooltip => 'Убрать из избранного';

  @override
  String get addToFavoritesTooltip => 'Добавить в избранное';

  @override
  String get addToPlaylistsTooltip => 'Добавить в плейлисты';

  @override
  String get removeFromPlaylistTooltip => 'Убрать из плейлиста';
}
