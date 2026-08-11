import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/author.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track_info/track_info.dart';

class Track extends Equatable {
  final int id;
  final int? albumId;
  final String name;
  final List<Author> authors;
  final AbstractFile file;
  final AbstractFile image;
  final bool isFavorite;
  final bool isDisliked;
  final bool isAvailable;
  final DateTime? createdAt;

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
    required this.isDisliked,
    required this.isAvailable,
    this.albumId,
    this.createdAt,
  });

  Track copyWith({
    int? id,
    int? albumId,
    String? name,
    List<Author>? authors,
    AbstractFile? file,
    AbstractFile? image,
    List<TrackInfo>? addionalInfo,
    bool? isFavorite,
    bool? isDisliked,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Track(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      name: name ?? this.name,
      authors: authors ?? this.authors,
      addionalInfo: addionalInfo ?? this.addionalInfo,
      file: file ?? this.file,
      image: image ?? this.image,
      isFavorite: isFavorite ?? this.isFavorite,
      isDisliked: isDisliked ?? this.isDisliked,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    albumId,
    name,
    authors,
    file,
    addionalInfo,
    image,
    isFavorite,
    isDisliked,
    isAvailable,
    createdAt,
  ];
}
