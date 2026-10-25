import 'dart:async';
import 'dart:io';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/audio_metadata_helper.dart';
import '../../../core/utils/audio_tag_extractor.dart';
import '../../audio_player/domain/audio_track.dart';

class ScanProgress {
  final bool isScanning;
  final int scannedCount;
  final String statusMessage;

  const ScanProgress({
    required this.isScanning,
    required this.scannedCount,
    required this.statusMessage,
  });
}

class MusicScannerService {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final _progressController = StreamController<ScanProgress>.broadcast();

  Stream<ScanProgress> get progressStream => _progressController.stream;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) requires READ_MEDIA_AUDIO and POST_NOTIFICATIONS
      final audioStatus = await Permission.audio.request();
      await Permission.notification.request();

      if (audioStatus.isGranted) {
        return true;
      }

      // Check legacy storage permission for Android 12 and below
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    }
    return true;
  }

  Future<List<AudioTrack>> scanMediaStore({
    List<String> excludedFolders = const [],
    int minDurationMs = 15000, // Filter out ringtones/short clips (<15s)
  }) async {
    _progressController.add(const ScanProgress(
      isScanning: true,
      scannedCount: 0,
      statusMessage: 'Accessing local music storage...',
    ));

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _progressController.add(const ScanProgress(
        isScanning: false,
        scannedCount: 0,
        statusMessage: 'Permission denied. Please grant storage access.',
      ));
      return [];
    }

    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
      );


      final tracks = <AudioTrack>[];
      int processed = 0;

      for (final song in songs) {
        processed++;
        if (processed % 10 == 0 || processed == songs.length) {
          _progressController.add(ScanProgress(
            isScanning: true,
            scannedCount: tracks.length,
            statusMessage: 'Discovered $processed of ${songs.length} audio files...',
          ));
        }

        // Filter out short sounds/ringtones if minDurationMs is set
        final duration = song.duration ?? 0;
        if (duration < minDurationMs) continue;

        final filePath = song.data;
        // Check excluded folders
        bool isExcluded = false;
        for (final excluded in excludedFolders) {
          if (filePath.toLowerCase().contains(excluded.toLowerCase())) {
            isExcluded = true;
            break;
          }
        }
        if (isExcluded) continue;

        final ext = p.extension(filePath).replaceAll('.', '').toLowerCase();
        final effectiveExt = ext.isNotEmpty ? ext : 'mp3';
        final isLossless = AudioMetadataHelper.isLosslessFormat(effectiveExt);

        String? extractedArt;
        if (isLossless || song.albumId == null) {
          try {
            final meta = await AudioTagExtractor.extract(filePath);
            extractedArt = meta.artworkPath;
          } catch (_) {}
        }

        final track = AudioTrack(
          id: 'ms_${song.id}',
          title: song.title.trim().isNotEmpty ? song.title.trim() : p.basenameWithoutExtension(filePath),
          artist: song.artist != null && song.artist != '<unknown>' && song.artist!.trim().isNotEmpty
              ? song.artist!.trim()
              : 'Unknown Artist',
          album: song.album != null && song.album != '<unknown>' && song.album!.trim().isNotEmpty
              ? song.album!.trim()
              : 'Unknown Album',
          albumId: song.albumId,
          durationMs: duration,
          uri: song.uri ?? filePath,
          path: filePath,
          fileExtension: effectiveExt,
          trackNumber: song.track,
          dateAdded: song.dateAdded,
          genre: song.genre,
          isLossless: isLossless,
          bitrate: isLossless ? null : 320,
          customArtPath: extractedArt,
        );

        tracks.add(track);
      }

      // Upsert into local database
      await AppDatabase.instance.upsertSongs(tracks);

      _progressController.add(ScanProgress(
        isScanning: false,
        scannedCount: tracks.length,
        statusMessage: 'Scan complete. Indexed ${tracks.length} songs.',
      ));

      return tracks;
    } catch (e) {
      _progressController.add(ScanProgress(
        isScanning: false,
        scannedCount: 0,
        statusMessage: 'Error scanning library: $e',
      ));
      return [];
    }
  }

  Future<List<AudioTrack>> scanCustomFolder(
    String folderPath, {
    List<String> excludedFolders = const [],
  }) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    _progressController.add(ScanProgress(
      isScanning: true,
      scannedCount: 0,
      statusMessage: 'Scanning ${p.basename(folderPath)}...',
    ));

    final discoveredTracks = <AudioTrack>[];

    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).replaceAll('.', '').toLowerCase();
          if (AudioMetadataHelper.supportedExtensions.contains(ext)) {
            final fileName = p.basenameWithoutExtension(entity.path);
            final isLossless = AudioMetadataHelper.isLosslessFormat(ext);

            // Simple title/artist inference from standard "Artist - Title.ext" filenames
            String artist = 'Unknown Artist';
            String title = fileName;
            if (fileName.contains(' - ')) {
              final parts = fileName.split(' - ');
              if (parts.length >= 2) {
                artist = parts[0].trim();
                title = parts.sublist(1).join(' - ').trim();
              }
            }

            // Extract actual embedded metadata (Vorbis, ID3, embedded PICTURE)
            final meta = await AudioTagExtractor.extract(entity.path);

            final track = AudioTrack(
              id: 'file_${entity.path.hashCode.abs()}',
              title: (meta.title != null && meta.title!.trim().isNotEmpty)
                  ? meta.title!.trim()
                  : title,
              artist: (meta.artist != null && meta.artist!.trim().isNotEmpty)
                  ? meta.artist!.trim()
                  : artist,
              album: (meta.album != null && meta.album!.trim().isNotEmpty)
                  ? meta.album!.trim()
                  : p.basename(p.dirname(entity.path)),
              durationMs: 0,
              uri: entity.uri.toString(),
              path: entity.path,
              fileExtension: ext,
              isLossless: isLossless,
              genre: meta.genre,
              trackNumber: meta.trackNumber,
              customArtPath: meta.artworkPath,
            );
            discoveredTracks.add(track);
          }
        }
      }

      if (discoveredTracks.isNotEmpty) {
        await AppDatabase.instance.upsertSongs(discoveredTracks);
      }

      _progressController.add(ScanProgress(
        isScanning: false,
        scannedCount: discoveredTracks.length,
        statusMessage: 'Added ${discoveredTracks.length} tracks from folder.',
      ));

      return discoveredTracks;
    } catch (e) {
      _progressController.add(ScanProgress(
        isScanning: false,
        scannedCount: 0,
        statusMessage: 'Error scanning folder: $e',
      ));
      return [];
    }
  }

  void dispose() {
    _progressController.close();
  }
}
