import 'package:esketit_music_app/use_case/settings/fullscreen_player_inactive_controls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FullscreenPlayerInactiveControls', () {
    test('defaults preserve the existing inactive mode', () {
      expect(
        FullscreenPlayerInactiveControls.defaults,
        const FullscreenPlayerInactiveControls(
          showTrackName: true,
          showTrackAuthors: true,
          showTrackProgressIndicator: true,
          showTrackTiming: false,
          showPlaybackButtons: false,
          showFavoriteButton: false,
        ),
      );
    });

    test('turning progress indicator off also turns timing off', () {
      const controls = FullscreenPlayerInactiveControls(
        showTrackName: false,
        showTrackAuthors: false,
        showTrackProgressIndicator: true,
        showTrackTiming: true,
        showPlaybackButtons: false,
        showFavoriteButton: false,
      );

      final updatedControls = controls.copyWith(
        showTrackProgressIndicator: false,
      );

      expect(updatedControls.showTrackProgressIndicator, isFalse);
      expect(updatedControls.showTrackTiming, isFalse);
    });

    test('timing cannot be turned on while progress indicator is off', () {
      const controls = FullscreenPlayerInactiveControls(
        showTrackName: false,
        showTrackAuthors: false,
        showTrackProgressIndicator: false,
        showTrackTiming: false,
        showPlaybackButtons: false,
        showFavoriteButton: false,
      );

      final updatedControls = controls.copyWith(showTrackTiming: true);

      expect(updatedControls.showTrackProgressIndicator, isFalse);
      expect(updatedControls.showTrackTiming, isFalse);
    });
  });
}
