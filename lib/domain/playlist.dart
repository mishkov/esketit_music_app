import 'package:equatable/equatable.dart';

enum PlaylistVisibility { private, public, shared }

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.coverImagePath,
    required this.visibility,
    required this.trackCount,
    required this.system,
    required this.isFavorites,
    this.shareToken,
  });

  final int id;
  final int userId;
  final String name;
  final String description;
  final String coverImagePath;
  final PlaylistVisibility visibility;
  final int trackCount;
  final bool system;
  final bool isFavorites;
  final String? shareToken;

  Playlist copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? coverImagePath,
    PlaylistVisibility? visibility,
    int? trackCount,
    bool? system,
    bool? isFavorites,
    String? shareToken,
  }) {
    return Playlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      visibility: visibility ?? this.visibility,
      trackCount: trackCount ?? this.trackCount,
      system: system ?? this.system,
      isFavorites: isFavorites ?? this.isFavorites,
      shareToken: shareToken ?? this.shareToken,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    description,
    coverImagePath,
    visibility,
    trackCount,
    system,
    isFavorites,
    shareToken,
  ];
}
