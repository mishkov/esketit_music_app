import 'package:esketit_music_app/domain/file/abstract_file.dart';

/// A file stored in the application's private local storage.
///
/// The path is resolved by the outer storage layer. Domain and use-case code
/// can distinguish cached media without depending on `dart:io`.
class LocalFile extends AbstractFile {
  LocalFile({required this.path});

  final String path;

  @override
  List<Object> get props => [path];
}
