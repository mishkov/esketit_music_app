import 'package:esketit_music_app/use_case/downloads/download_queue_storage.dart';
import 'package:esketit_music_app/use_case/downloads/download_request_storage.dart';
import 'package:esketit_music_app/use_case/downloads/downloaded_library_storage.dart';

abstract class DownloadsStorage
    implements
        DownloadRequestStorage,
        DownloadQueueStorage,
        DownloadedLibraryStorage {}
