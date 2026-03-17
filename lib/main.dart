import 'package:esketit_music_app/errors/error_reporter/app_errors_bloc_observer.dart';
import 'package:esketit_music_app/errors/error_reporter/encrypter_stub.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter.dart';
import 'package:esketit_music_app/errors/error_reporter/error_reporter_console_logger_proxy.dart';
import 'package:esketit_music_app/errors/error_reporter/sentry_error_reporter.dart';
import 'package:esketit_music_app/esketit_rest_api/tracks/esketit_rest_api_tracks_storage.dart';
import 'package:esketit_music_app/ui/esketit_app.dart';
import 'package:esketit_music_app/unassigned_layer/http_package_http_client.dart';
import 'package:esketit_music_app/unassigned_layer/just_audio_audio_player.dart';
import 'package:esketit_music_app/use_case/player/bloc/player_bloc.dart';
import 'package:esketit_music_app/use_case/tracks/tracks_list/bloc/tracks_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  final errorReporter = SentryErrorReporter(encrypter: EncrypterStub());
  await errorReporter.init(
    // TODO: move it to move safe place.
    dsn:
        'https://0a6197a22adaf0913a6a7b0ddd853210@o4504197551554560.ingest.us.sentry.io/4511020270419968',
    appRunner: () async => await _runEsketitApp(
      ErrorReporterConsoleLoggerProxy(delegate: errorReporter),
    ),
  );
}

Future<void> _runEsketitApp(ErrorReporter errorReporter) async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.esketit_music_app.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  Bloc.observer = AppErrorsBlocObserver(reporter: errorReporter);

  final baseUri =
      // This is comment just for formatting.
      // Uri.parse('http://10.0.2.2:8080');
      Uri.parse('http://192.168.1.6:8080');
  //  Uri.parse('http://localhost:8080');

  final httpClient = HttpPackageHttpClient(baseUri: baseUri);
  final tracksStorage = EsketitRestApiTracksStorage(httpClient: httpClient);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TracksListBloc(
            initialState: TracksListState(tracks: [], tracksPerPage: 10),
            errorReporter: errorReporter,
            tracksStorage: tracksStorage,
          ),
        ),
        BlocProvider(
          create: (context) => PlayerBloc(
            initialState: PlayerState(selectedTrack: null, isPlaying: false),
            player: JustAudioAudioPlayer(baseUri: baseUri),
          ),
        ),
        BlocProvider(
          create: (context) => TracksListBloc(
            initialState: TracksListState(tracks: [], tracksPerPage: 10),
            errorReporter: errorReporter,
            tracksStorage: tracksStorage,
          ),
        ),
      ],
      child: const EsketitApp(),
    ),
  );
}

// class Song {
//   Song({
//     required this.name,
//     required this.sizeBytes,
//     required this.lastModified,
//     required this.url,
//   });

//   final String name;
//   final int sizeBytes;
//   final DateTime? lastModified;
//   final String url;

//   factory Song.fromJson(Map<String, dynamic> json) {
//     return Song(
//       name: json['name'] as String? ?? 'Unknown',
//       sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
//       lastModified: DateTime.tryParse(json['lastModified'] as String? ?? ''),
//       url: json['url'] as String? ?? '',
//     );
//   }
// }

// class MusicApi {
//   MusicApi(this.baseUrl);

//   final String baseUrl;

//   Uri _uri(String path) {
//     final cleanedBase = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
//     return Uri.parse('$cleanedBase$path');
//   }

//   Future<List<Song>> fetchSongs() async {
//     final response = await http.get(_uri('/songs'));
//     if (response.statusCode != 200) {
//       throw Exception('Failed to load songs: ${response.statusCode}');
//     }

//     final decoded = jsonDecode(response.body) as List<dynamic>;
//     return decoded
//         .whereType<Map<String, dynamic>>()
//         .map(Song.fromJson)
//         .toList(growable: false);
//   }

//   String toSongUrl(Song song) {
//     final songUri = Uri.parse(song.url);
//     if (songUri.hasScheme) {
//       return song.url;
//     }
//     return _uri(song.url).toString();
//   }
// }

// class MusicPlayerPage extends StatefulWidget {
//   const MusicPlayerPage({super.key});

//   @override
//   State<MusicPlayerPage> createState() => _MusicPlayerPageState();
// }

// class _MusicPlayerPageState extends State<MusicPlayerPage> {
//   final TextEditingController _baseUrlController = TextEditingController(
//     text: 'http://192.168.1.5:8080',
//   );
//   final AudioPlayer _audioPlayer = AudioPlayer();

//   List<Song> _songs = const [];
//   Song? _selectedSong;
//   String? _errorMessage;
//   bool _isLoading = false;
//   bool _isStartingPlayback = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadSongs();
//   }

//   @override
//   void dispose() {
//     _baseUrlController.dispose();
//     _audioPlayer.dispose();
//     super.dispose();
//   }

//   Future<void> _loadSongs() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final api = MusicApi(_baseUrlController.text);
//       final songs = await api.fetchSongs();
//       setState(() {
//         _songs = songs;
//         if (_selectedSong != null &&
//             !songs.any((song) => song.name == _selectedSong!.name)) {
//           _selectedSong = null;
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = e.toString();
//         _songs = const [];
//         _selectedSong = null;
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _playSong(Song song) async {
//     setState(() {
//       _isStartingPlayback = true;
//       _errorMessage = null;
//     });

//     try {
//       final api = MusicApi(_baseUrlController.text);
//       await _audioPlayer.setUrl(api.toSongUrl(song));
//       await _audioPlayer.play();
//       setState(() {
//         _selectedSong = song;
//       });
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Playback failed: $e';
//       });
//     } finally {
//       setState(() {
//         _isStartingPlayback = false;
//       });
//     }
//   }

//   Future<void> _stopSong() async {
//     await _audioPlayer.stop();
//     setState(() {
//       _selectedSong = null;
//     });
//   }

//   String _formatBytes(int bytes) {
//     if (bytes < 1024) {
//       return '$bytes B';
//     }
//     final kb = bytes / 1024;
//     if (kb < 1024) {
//       return '${kb.toStringAsFixed(1)} KB';
//     }
//     final mb = kb / 1024;
//     return '${mb.toStringAsFixed(1)} MB';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Esketit Music Player'),
//         actions: [
//           IconButton(
//             onPressed: _isLoading ? null : _loadSongs,
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _baseUrlController,
//                     decoration: const InputDecoration(
//                       labelText: 'Server URL',
//                       hintText: 'http://10.0.2.2:8080',
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => _loadSongs(),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 FilledButton(
//                   onPressed: _isLoading ? null : () => _loadSongs(),
//                   child: const Text('Load'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             if (_errorMessage != null)
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   _errorMessage!,
//                   style: TextStyle(color: Theme.of(context).colorScheme.error),
//                 ),
//               ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     _selectedSong == null
//                         ? 'No song selected'
//                         : 'Now playing: ${_selectedSong!.name}',
//                   ),
//                 ),
//                 StreamBuilder<bool>(
//                   stream: _audioPlayer.playingStream,
//                   builder: (context, snapshot) {
//                     final isPlaying = snapshot.data ?? false;
//                     return IconButton(
//                       onPressed: _selectedSong == null
//                           ? null
//                           : () async {
//                               if (isPlaying) {
//                                 await _audioPlayer.pause();
//                               } else {
//                                 await _audioPlayer.play();
//                               }
//                             },
//                       icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
//                     );
//                   },
//                 ),
//                 IconButton(
//                   onPressed: _selectedSong == null ? null : _stopSong,
//                   icon: const Icon(Icons.stop),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Expanded(
//               child: _isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : _songs.isEmpty
//                   ? const Center(child: Text('No songs found'))
//                   : ListView.separated(
//                       itemCount: _songs.length,
//                       separatorBuilder: (_, _) => const Divider(height: 1),
//                       itemBuilder: (context, index) {
//                         final song = _songs[index];
//                         final isCurrent = _selectedSong?.name == song.name;
//                         return ListTile(
//                           title: Text(song.name),
//                           subtitle: Text(
//                             '${_formatBytes(song.sizeBytes)}'
//                             '${song.lastModified != null ? ' • ${song.lastModified}' : ''}',
//                           ),
//                           trailing: _isStartingPlayback && isCurrent
//                               ? const SizedBox(
//                                   width: 20,
//                                   height: 20,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : Icon(
//                                   isCurrent
//                                       ? Icons.equalizer
//                                       : Icons.play_arrow,
//                                 ),
//                           onTap: () => _playSong(song),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
