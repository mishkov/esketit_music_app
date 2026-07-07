import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';
import 'package:esketit_music_app/errors/error_reporter/breadcrumb.dart';
import 'package:esketit_music_app/errors/error_reporter/category.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
import 'package:esketit_music_app/use_case/settings/app_theme_mode.dart';
import 'package:esketit_music_app/use_case/settings/author_albums_display_mode.dart';
import 'package:esketit_music_app/use_case/shared/nullable_option.dart';
import 'package:esketit_music_app/use_case/settings/settings_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SettingsEvent extends Equatable {}

final class SetServerUri extends SettingsEvent {
  final Uri uri;

  SetServerUri(this.uri);

  @override
  List<Object?> get props => [uri];
}

final class SetLocale extends SettingsEvent {
  final AppLocale? locale;

  SetLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

final class SetThemeMode extends SettingsEvent {
  final AppThemeMode themeMode;

  SetThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

final class SetAuthorAlbumsDisplayMode extends SettingsEvent {
  final AuthorAlbumsDisplayMode displayMode;

  SetAuthorAlbumsDisplayMode(this.displayMode);

  @override
  List<Object?> get props => [displayMode];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsStorage _settingsStorage;
  final ErrorReporter _errorReporter;

  SettingsBloc({
    required SettingsState initialState,
    required SettingsStorage settingsStorage,
    required ErrorReporter errorReporter,
  }) : _settingsStorage = settingsStorage,
       _errorReporter = errorReporter,
       super(initialState) {
    on<SetServerUri>((event, emit) async {
      try {
        await _settingsStorage.setServerUri(event.uri);
        emit(state.copyWith(serverUri: event.uri));
      } catch (error, stackTrace) {
        await _reportError('Failed to set server URI', error, stackTrace);
      }
    });
    on<SetLocale>((event, emit) async {
      try {
        await _settingsStorage.setLocale(event.locale);
        emit(
          state.copyWith(
            locale: event.locale == null
                ? NullableOption.nullable()
                : NullableOption.value(event.locale!),
          ),
        );
      } catch (error, stackTrace) {
        await _reportError('Failed to set locale', error, stackTrace);
      }
    });
    on<SetThemeMode>((event, emit) async {
      try {
        await _settingsStorage.setThemeMode(event.themeMode);
        emit(state.copyWith(themeMode: event.themeMode));
      } catch (error, stackTrace) {
        await _reportError('Failed to set theme mode', error, stackTrace);
      }
    });
    on<SetAuthorAlbumsDisplayMode>((event, emit) async {
      try {
        await _errorReporter.addBreadcrumb(
          Breadcrumb(
            message: 'Set author albums display mode',
            category: Category.uiClick,
            data: {'displayMode': event.displayMode.name},
          ),
        );
        await _settingsStorage.setAuthorAlbumsDisplayMode(event.displayMode);
        emit(state.copyWith(authorAlbumsDisplayMode: event.displayMode));
      } catch (error, stackTrace) {
        await _reportError(
          'Failed to set author albums display mode',
          error,
          stackTrace,
        );
      }
    });
  }

  Future<void> _reportError(
    String message,
    Object error,
    StackTrace stackTrace,
  ) {
    return _errorReporter.reportError(
      AppError(message, cause: error, stackTrace: stackTrace),
    );
  }
}

class SettingsState extends Equatable {
  final Uri serverUri;
  final AppLocale? locale;
  final AppThemeMode themeMode;
  final AuthorAlbumsDisplayMode authorAlbumsDisplayMode;

  const SettingsState({
    required this.serverUri,
    required this.locale,
    required this.themeMode,
    required this.authorAlbumsDisplayMode,
  });

  SettingsState copyWith({
    Uri? serverUri,
    NullableOption<AppLocale>? locale,
    AppThemeMode? themeMode,
    AuthorAlbumsDisplayMode? authorAlbumsDisplayMode,
  }) {
    return SettingsState(
      serverUri: serverUri ?? this.serverUri,
      locale: locale == null ? this.locale : locale.value,
      themeMode: themeMode ?? this.themeMode,
      authorAlbumsDisplayMode:
          authorAlbumsDisplayMode ?? this.authorAlbumsDisplayMode,
    );
  }

  @override
  List<Object?> get props => [
    serverUri,
    locale,
    themeMode,
    authorAlbumsDisplayMode,
  ];
}
