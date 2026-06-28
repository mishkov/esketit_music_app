import 'dart:js_interop';

import 'package:http/browser_client.dart';
import 'package:web/web.dart' as web;

Future<void> triggerTrackDownload(Uri uri, String fileName) async {
  final client = BrowserClient()..withCredentials = true;

  try {
    final response = await client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Download failed with status ${response.statusCode}.');
    }

    final blob = web.Blob(
      <web.BlobPart>[response.bodyBytes.toJS].toJS,
      web.BlobPropertyBag(
        type: response.headers['content-type'] ?? 'application/octet-stream',
      ),
    );
    final objectUrl = web.URL.createObjectURL(blob);

    try {
      final anchor = web.HTMLAnchorElement()
        ..href = objectUrl
        ..download = fileName
        ..style.display = 'none';

      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      await Future<void>.delayed(const Duration(seconds: 1));
      web.URL.revokeObjectURL(objectUrl);
    }
  } finally {
    client.close();
  }
}
