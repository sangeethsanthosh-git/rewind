import 'package:path/path.dart' as p;
import '../../audio_player/domain/audio_track.dart';

class FolderModel {
  final String path;
  final String name;
  final List<AudioTrack> tracks;

  const FolderModel({
    required this.path,
    required this.name,
    required this.tracks,
  });

  factory FolderModel.fromPath(String path, List<AudioTrack> tracks) {
    return FolderModel(
      path: path,
      name: p.basename(path),
      tracks: tracks,
    );
  }

  int get trackCount => tracks.length;
}
