import '../../audio_player/domain/audio_track.dart';

class AlbumModel {
  final String title;
  final String artist;
  final int? albumId;
  final List<AudioTrack> tracks;

  const AlbumModel({
    required this.title,
    required this.artist,
    this.albumId,
    required this.tracks,
  });

  int get trackCount => tracks.length;

  int get totalDurationMs =>
      tracks.fold(0, (sum, item) => sum + item.durationMs);

  String? get customArtPath {
    for (final track in tracks) {
      if (track.customArtPath != null && track.customArtPath!.isNotEmpty) {
        return track.customArtPath;
      }
    }
    return null;
  }
}
