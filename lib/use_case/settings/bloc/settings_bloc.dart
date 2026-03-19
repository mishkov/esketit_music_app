import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/use_case/settings/settings_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SettingsEvent extends Equatable {}

class SetServerUri extends SettingsEvent {
  final Uri uri;

  SetServerUri(this.uri);

  @override
  List<Object?> get props => [uri];
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
  }
}

class SettingsState extends Equatable {
  final Uri serverUri;

  const SettingsState({required this.serverUri});

  SettingsState copyWith({Uri? serverUri}) {
    return SettingsState(serverUri: serverUri ?? this.serverUri);
  }

  @override
  List<Object?> get props => [serverUri];
}
