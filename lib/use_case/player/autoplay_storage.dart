import 'package:equatable/equatable.dart';
import 'package:esketit_music_app/domain/track.dart';

enum AutoplaySourceType { myVibe, playlist, album, track }

class AutoplayContext extends Equatable {
  const AutoplayContext({
    required this.sourceType,
    required this.sourceId,
    this.profile = 'default',
  });

  const AutoplayContext.myVibe({this.profile = 'default'})
    : sourceType = AutoplaySourceType.myVibe,
      sourceId = null;

  final AutoplaySourceType sourceType;
  final int? sourceId;
  final String profile;

  @override
  List<Object?> get props => [sourceType, sourceId, profile];
}

class AutoplayTracksBatch extends Equatable {
  const AutoplayTracksBatch({
    required this.context,
    required this.strategy,
    required this.tracks,
  });

  final AutoplayContext context;
  final String strategy;
  final List<Track> tracks;

  @override
  List<Object?> get props => [context, strategy, tracks];
}

abstract class AutoplayStorage {
  Future<AutoplayTracksBatch> getNextTracks({
    required AutoplayContext context,
    required int count,
    required List<int> recentTrackIds,
    required List<int> excludedTrackIds,
  });
}
