import 'package:equatable/equatable.dart';

class FullscreenPlayerInactiveControls extends Equatable {
  const FullscreenPlayerInactiveControls({
    required this.showTrackName,
    required this.showTrackAuthors,
    required this.showTrackProgressIndicator,
    required this.showTrackTiming,
    required this.showPlaybackButtons,
    required this.showFavoriteButton,
  }) : assert(!showTrackTiming || showTrackProgressIndicator);

  static const defaults = FullscreenPlayerInactiveControls(
    showTrackName: true,
    showTrackAuthors: true,
    showTrackProgressIndicator: true,
    showTrackTiming: false,
    showPlaybackButtons: false,
    showFavoriteButton: false,
  );

  final bool showTrackName;
  final bool showTrackAuthors;
  final bool showTrackProgressIndicator;
  final bool showTrackTiming;
  final bool showPlaybackButtons;
  final bool showFavoriteButton;

  FullscreenPlayerInactiveControls copyWith({
    bool? showTrackName,
    bool? showTrackAuthors,
    bool? showTrackProgressIndicator,
    bool? showTrackTiming,
    bool? showPlaybackButtons,
    bool? showFavoriteButton,
  }) {
    final effectiveShowTrackProgressIndicator =
        showTrackProgressIndicator ?? this.showTrackProgressIndicator;
    final effectiveShowTrackTiming =
        effectiveShowTrackProgressIndicator &&
        (showTrackTiming ?? this.showTrackTiming);

    return FullscreenPlayerInactiveControls(
      showTrackName: showTrackName ?? this.showTrackName,
      showTrackAuthors: showTrackAuthors ?? this.showTrackAuthors,
      showTrackProgressIndicator: effectiveShowTrackProgressIndicator,
      showTrackTiming: effectiveShowTrackTiming,
      showPlaybackButtons: showPlaybackButtons ?? this.showPlaybackButtons,
      showFavoriteButton: showFavoriteButton ?? this.showFavoriteButton,
    );
  }

  @override
  List<Object> get props => [
    showTrackName,
    showTrackAuthors,
    showTrackProgressIndicator,
    showTrackTiming,
    showPlaybackButtons,
    showFavoriteButton,
  ];
}
