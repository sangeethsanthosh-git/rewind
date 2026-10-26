import '../../audio_player/domain/audio_track.dart';

class ArtistModel {
  final String name;
  final List<AudioTrack> tracks;

  const ArtistModel({
    required this.name,
    required this.tracks,
  });

  int get trackCount => tracks.length;

  int get albumCount {
    return tracks.map((t) => t.album).toSet().length;
  }
}
