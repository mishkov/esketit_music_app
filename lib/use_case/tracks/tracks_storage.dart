import 'package:esketit_music_app/domain/track.dart';
import 'package:equatable/equatable.dart';

enum TracksSort { id, addedAt }

enum TracksSortOrder { ascending, descending }

class PaginatedTracks extends Equatable {
  final List<Track> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  const PaginatedTracks({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  @override
  List<Object> get props => [items, page, pageSize, totalItems, totalPages];
}

abstract class TracksStorage {
  Future<PaginatedTracks> getTracks({
    required int page,
    required int pageSize,
    TracksSort sort = TracksSort.id,
    TracksSortOrder order = TracksSortOrder.ascending,
  });
}
