import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/file/abstract_file.dart';
import 'package:esketit_music_app/domain/track_info/track_info.dart';

class Album extends Equatable {
  final int id;
  final String title;
  final AbstractFile coverImage;
  final List<int> authorIds;
  final DateTime? releaseDate;
  final bool isPublished;
  final List<int> trackIds;
  final List<TrackInfo> additionalInfo;

  const Album({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.authorIds,
    required this.releaseDate,
    required this.isPublished,
    required this.trackIds,
    required this.additionalInfo,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    coverImage,
    authorIds,
    releaseDate,
    isPublished,
    trackIds,
    additionalInfo,
  ];
}
