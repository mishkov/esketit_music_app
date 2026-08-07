import 'package:esketit_music_app/ui/shared/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('falls back to an HTML image when a web byte fetch fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RemoteImage(
          imageUrl: 'https://example.invalid/cover.jpg',
          icon: Icons.music_note_rounded,
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final imageProvider = image.image as NetworkImage;

    expect(
      imageProvider.webHtmlElementStrategy,
      WebHtmlElementStrategy.fallback,
    );
  });
}
