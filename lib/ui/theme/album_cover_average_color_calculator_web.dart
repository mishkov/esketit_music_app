import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

extension type _AverageColorWorkerRequest(JSObject _) implements JSObject {
  external factory _AverageColorWorkerRequest.create({
    int id,
    JSUint8Array pixels,
  });
}

extension type _AverageColorWorkerResponse(JSObject _) implements JSObject {
  external int get id;
  external int? get rgbValue;
  external String? get error;
}

class _AverageColorWorkerClient {
  static const String _workerPath =
      'album_cover_average_color_calculator_worker.js';

  final Map<int, Completer<int?>> _pendingRequests = <int, Completer<int?>>{};
  final web.Worker _worker;
  int _nextRequestId = 0;

  _AverageColorWorkerClient()
    : _worker = web.Worker(Uri.base.resolve(_workerPath).toString().toJS) {
    _worker.addEventListener('message', _handleMessage.toJS);
    _worker.addEventListener('error', _handleError.toJS);
  }

  Future<int?> calculateAverageRgbValue(Uint8List rgbaPixels) {
    final requestId = _nextRequestId++;
    final completer = Completer<int?>();
    _pendingRequests[requestId] = completer;

    try {
      _worker.postMessage(
        _AverageColorWorkerRequest.create(
          id: requestId,
          pixels: rgbaPixels.toJS,
        ),
      );
    } catch (error, stackTrace) {
      _pendingRequests.remove(requestId);
      completer.completeError(error, stackTrace);
    }

    return completer.future;
  }

  void _handleMessage(web.Event event) {
    final messageEvent = event as web.MessageEvent;
    final data = messageEvent.data;
    if (data == null) {
      return;
    }

    final response = _AverageColorWorkerResponse(data as JSObject);
    final completer = _pendingRequests.remove(response.id);
    if (completer == null || completer.isCompleted) {
      return;
    }

    final error = response.error;
    if (error != null) {
      completer.completeError(StateError(error));

      return;
    }

    completer.complete(response.rgbValue);
  }

  void _handleError(web.Event event) {
    final error = StateError('Album cover average color worker failed.');
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingRequests.clear();
  }
}

final _AverageColorWorkerClient _workerClient = _AverageColorWorkerClient();

Future<int?> calculatePlatformAverageRgbValue(Uint8List rgbaPixels) {
  return _workerClient.calculateAverageRgbValue(rgbaPixels);
}
