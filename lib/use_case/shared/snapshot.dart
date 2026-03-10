import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/errors/error_reporter/app_error.dart';

/// The reason of such class is that sometimes when we work with BLoC pattern we
/// have state with few data fields. Each data can be loaded synchronously so we
/// need somehow to handle each loading and error of each data. Previously in my
/// own projects I have used something like list of loadings and result
/// isLoading getter which returns true if that list is not empty but we still
/// cannot known which concrete data is loading or is broken so [Snapshot]
/// contains this information.
///
/// It’s experimental feature.
class Snapshot<T> extends Equatable {
  final T data;
  final AppError? error;
  final bool isLoading;

  const Snapshot.done(this.data) : error = null, isLoading = false;

  const Snapshot.loading(this.data) : error = null, isLoading = true;

  const Snapshot.error(this.error, {required this.data}) : isLoading = false;

  bool get hasError => error != null;

  @override
  List<Object?> get props => [data, error, isLoading];
}
