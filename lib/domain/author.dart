import 'package:equatable/equatable.dart';

class Author extends Equatable {
  final int id;

  /// Because Author can change their name (for example due to cesonrship).
  final String currentName;
  final List<String> photos;

  const Author({
    required this.id,
    required this.currentName,
    required this.photos,
  });

  String? get primaryPhotoUrl => photos.firstOrNull;

  @override
  List<Object> get props => [id, currentName, photos];
}
