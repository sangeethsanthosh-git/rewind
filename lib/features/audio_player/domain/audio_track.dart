class AudioTrack {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int? albumId;
  final int durationMs;
  final String uri;
  final String path;
  final String fileExtension;
  final int? bitrate;
  final int? sampleRate;
  final int? bitDepth;
  final bool isLossless;
  final int? trackNumber;
  final int? dateAdded;
  final String? genre;
  final bool isFavorite;
  final int playCount;
  final String? customArtPath;
  final String? lyrics;

  const AudioTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.albumId,
    required this.durationMs,
    required this.uri,
    required this.path,
    required this.fileExtension,
    this.bitrate,
    this.sampleRate,
    this.bitDepth,
    this.isLossless = false,
    this.trackNumber,
    this.dateAdded,
    this.genre,
    this.isFavorite = false,
    this.playCount = 0,
    this.customArtPath,
    this.lyrics,
  });

  AudioTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    int? albumId,
    int? durationMs,
    String? uri,
    String? path,
    String? fileExtension,
    int? bitrate,
    int? sampleRate,
    int? bitDepth,
    bool? isLossless,
    int? trackNumber,
    int? dateAdded,
    String? genre,
    bool? isFavorite,
    int? playCount,
    String? customArtPath,
    String? lyrics,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      durationMs: durationMs ?? this.durationMs,
      uri: uri ?? this.uri,
      path: path ?? this.path,
      fileExtension: fileExtension ?? this.fileExtension,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      isLossless: isLossless ?? this.isLossless,
      trackNumber: trackNumber ?? this.trackNumber,
      dateAdded: dateAdded ?? this.dateAdded,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      customArtPath: customArtPath ?? this.customArtPath,
      lyrics: lyrics ?? this.lyrics,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'album_id': albumId,
      'duration_ms': durationMs,
      'uri': uri,
      'path': path,
      'file_extension': fileExtension,
      'bitrate': bitrate,
      'sample_rate': sampleRate,
      'bit_depth': bitDepth,
      'is_lossless': isLossless ? 1 : 0,
      'track_number': trackNumber,
      'date_added': dateAdded,
      'genre': genre,
      'is_favorite': isFavorite ? 1 : 0,
      'play_count': playCount,
      'custom_art_path': customArtPath,
      'lyrics': lyrics,
    };
  }

  factory AudioTrack.fromMap(Map<String, dynamic> map) {
    return AudioTrack(
      id: map['id']?.toString() ?? '',
      title: (map['title'] as String?)?.isNotEmpty == true
          ? map['title'] as String
          : 'Unknown Title',
      artist: (map['artist'] as String?)?.isNotEmpty == true
          ? map['artist'] as String
          : 'Unknown Artist',
      album: (map['album'] as String?)?.isNotEmpty == true
          ? map['album'] as String
          : 'Unknown Album',
      albumId: map['album_id'] is int ? map['album_id'] as int : int.tryParse(map['album_id']?.toString() ?? ''),
      durationMs: map['duration_ms'] as int? ?? 0,
      uri: map['uri'] as String? ?? '',
      path: map['path'] as String? ?? '',
      fileExtension: (map['file_extension'] as String? ?? 'mp3').toLowerCase(),
      bitrate: map['bitrate'] as int?,
      sampleRate: map['sample_rate'] as int?,
      bitDepth: map['bit_depth'] as int?,
      isLossless: (map['is_lossless'] as int? ?? 0) == 1,
      trackNumber: map['track_number'] as int?,
      dateAdded: map['date_added'] as int?,
      genre: map['genre'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      playCount: map['play_count'] as int? ?? 0,
      customArtPath: map['custom_art_path'] as String?,
      lyrics: map['lyrics'] as String?,
    );
  }
}
