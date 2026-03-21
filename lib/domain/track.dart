import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track_info/track_info.dart';

class Track extends Equatable {
  final int id;
  final String name;
  final List<Author> authors;
  final AbstractFile file;
  final AbstractFile image;
  final bool isFavorite;
  final bool isAvailable;

  /// Any related info like history of track, who inspired, how it was written,
  /// link to videos, link to tik toks, link to covers etc.
  final List<TrackInfo> addionalInfo;

  const Track({
    required this.id,
    required this.name,
    required this.authors,
    required this.addionalInfo,
    required this.file,
    required this.image,
    required this.isFavorite,
    required this.isAvailable,
  });

  Track copyWith({
    int? id,
    String? name,
    List<Author>? authors,
    AbstractFile? file,
    AbstractFile? image,
    List<TrackInfo>? addionalInfo,
    bool? isFavorite,
    bool? isAvailable,
  }) {
    return Track(
      id: id ?? this.id,
      name: name ?? this.name,
      authors: authors ?? this.authors,
      addionalInfo: addionalInfo ?? this.addionalInfo,
      file: file ?? this.file,
      image: image ?? this.image,
      isFavorite: isFavorite ?? this.isFavorite,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object> get props => [
    id,
    name,
    authors,
    file,
    addionalInfo,
    image,
    isFavorite,
    isAvailable,
  ];
}
