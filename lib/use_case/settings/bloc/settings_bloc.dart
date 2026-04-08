import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/use_case/settings/app_locale.dart';
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

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsStorage _settingsStorage;

  SettingsBloc({
    required SettingsState initialState,
    required SettingsStorage settingsStorage,
  }) : _settingsStorage = settingsStorage,
       super(initialState) {
    on<SetServerUri>((event, emit) async {
      try {
        await _settingsStorage.setServerUri(event.uri);
        emit(state.copyWith(serverUri: event.uri));
      } catch (error) {
        // TODO: report error.
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
      } catch (error) {
        // TODO: report error.
      }
    });
  }
}

class SettingsState extends Equatable {
  final Uri serverUri;
  final AppLocale? locale;

  const SettingsState({required this.serverUri, required this.locale});

  SettingsState copyWith({Uri? serverUri, NullableOption<AppLocale>? locale}) {
    return SettingsState(
      serverUri: serverUri ?? this.serverUri,
      locale: locale == null ? this.locale : locale.value,
    );
  }

  @override
  List<Object?> get props => [serverUri, locale];
}
