import 'package:equatable/equatable.dart';

enum TrackLyricsType { plain, synced }

class TrackLyrics extends Equatable {
  final int trackId;
  final TrackLyricsType type;
  final String? languageCode;
  final bool isVerified;
  final String? source;
  final String? plainText;
  final List<SyncedTrackLyricsLine> lines;

  const TrackLyrics({
    required this.trackId,
    required this.type,
    required this.languageCode,
    required this.isVerified,
    required this.source,
    required this.plainText,
    required this.lines,
  });

  String get displayText {
    final trimmedPlainText = plainText?.trim() ?? '';
    if (trimmedPlainText.isNotEmpty) {
      return trimmedPlainText;
    }

    return lines.map((line) => line.text.trim()).join('\n').trim();
  }

  bool get hasContent => displayText.isNotEmpty;

  int? syncedLineIndexAt(Duration position) {
    if (type != TrackLyricsType.synced || lines.isEmpty) {
      return null;
    }

    final positionMilliseconds = position.inMilliseconds;
    for (var index = 0; index < lines.length; index += 1) {
      final line = lines[index];
      final nextLine = index + 1 < lines.length ? lines[index + 1] : null;
      final lineEndMilliseconds = line.endMs ?? nextLine?.startMs;
      if (lineEndMilliseconds == null) {
        if (positionMilliseconds >= line.startMs) {
          return index;
        }

        continue;
      }

      if (positionMilliseconds >= line.startMs &&
          positionMilliseconds < lineEndMilliseconds) {
        return index;
      }
    }

    return null;
  }

  @override
  List<Object?> get props => [
    trackId,
    type,
    languageCode,
    isVerified,
    source,
    plainText,
    lines,
  ];
}

class SyncedTrackLyricsLine extends Equatable {
  final int startMs;
  final int? endMs;
  final String text;

  const SyncedTrackLyricsLine({
    required this.startMs,
    required this.endMs,
    required this.text,
  });

  @override
  List<Object?> get props => [startMs, endMs, text];
}
