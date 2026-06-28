import 'package:flutter/foundation.dart';

/// Central default for showing track downloads in the UI.
///
/// Change this getter when download availability should include more platforms
/// or depend on app configuration.
bool get showTrackSaveToDownloadsActionByDefault => kIsWeb;
