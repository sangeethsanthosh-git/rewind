import 'package:flutter_test/flutter_test.dart';
import 'package:spool/core/utils/formatters.dart';
import 'package:spool/core/utils/audio_metadata_helper.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/collections/domain/playlist_model.dart';

void main() {
  group('Formatters Tests', () {
    test('formatDuration formats mm:ss correctly', () {
      expect(Formatters.formatDuration(const Duration(seconds: 75)), '1:15');
      expect(Formatters.formatDuration(const Duration(seconds: 9)), '0:09');
      expect(Formatters.formatDuration(const Duration(minutes: 4, seconds: 20)), '4:20');
      expect(Formatters.formatDuration(Duration.zero), '0:00');
    });

    test('formatTechnicalSpecs formats audio specs cleanly', () {
      final flacSpec = Formatters.formatTechnicalSpecs(
        extension: 'flac',
        sampleRate: 96000,
        bitDepth: 24,
        isLossless: true,
      );
      expect(flacSpec, contains('FLAC'));
      expect(flacSpec, contains('HI-RES 24-BIT'));
      expect(flacSpec, contains('96kHz'));

      final mp3Spec = Formatters.formatTechnicalSpecs(
        extension: 'mp3',
        bitrate: 320,
        sampleRate: 44100,
      );
      expect(mp3Spec, contains('MP3'));
      expect(mp3Spec, contains('44.1kHz'));
      expect(mp3Spec, contains('320kbps'));
    });
  });

  group('AudioMetadataHelper Tests', () {
    test('identifies lossless extensions', () {
      expect(AudioMetadataHelper.isLosslessFormat('flac'), isTrue);
      expect(AudioMetadataHelper.isLosslessFormat('wav'), isTrue);
      expect(AudioMetadataHelper.isLosslessFormat('aiff'), isTrue);
      expect(AudioMetadataHelper.isLosslessFormat('alac'), isTrue);
      expect(AudioMetadataHelper.isLosslessFormat('mp3'), isFalse);
      expect(AudioMetadataHelper.isLosslessFormat('aac'), isFalse);
    });

    test('identifies ExoPlayer native support', () {
      expect(AudioMetadataHelper.isCodecSupportedByExoPlayer('flac'), isTrue);
      expect(AudioMetadataHelper.isCodecSupportedByExoPlayer('mp3'), isTrue);
      expect(AudioMetadataHelper.isCodecSupportedByExoPlayer('wav'), isTrue);
      expect(AudioMetadataHelper.isCodecSupportedByExoPlayer('opus'), isTrue);
      expect(AudioMetadataHelper.isCodecSupportedByExoPlayer('ape'), isFalse);
    });
  });

  group('AudioTrack Serialization Tests', () {
    test('AudioTrack round trip through Map', () {
      const track = AudioTrack(
        id: 'ms_101',
        title: 'Come Together',
        artist: 'The Beatles',
        album: 'Abbey Road',
        albumId: 42,
        durationMs: 259000,
        uri: 'content://media/external/audio/101',
        path: '/storage/emulated/0/Music/AbbeyRoad/01.flac',
        fileExtension: 'flac',
        isLossless: true,
        bitDepth: 24,
        sampleRate: 96000,
        isFavorite: true,
        customArtPath: '/storage/emulated/0/Music/AbbeyRoad/cover.jpg',
      );

      final map = track.toMap();
      final restored = AudioTrack.fromMap(map);

      expect(restored.id, 'ms_101');
      expect(restored.title, 'Come Together');
      expect(restored.artist, 'The Beatles');
      expect(restored.album, 'Abbey Road');
      expect(restored.albumId, 42);
      expect(restored.durationMs, 259000);
      expect(restored.fileExtension, 'flac');
      expect(restored.isLossless, isTrue);
      expect(restored.bitDepth, 24);
      expect(restored.sampleRate, 96000);
      expect(restored.isFavorite, isTrue);
      expect(restored.customArtPath, '/storage/emulated/0/Music/AbbeyRoad/cover.jpg');
    });
  });

  group('PlaylistModel Tests', () {
    test('PlaylistModel parses correctly', () {
      final model = PlaylistModel.fromMap({
        'id': 'pl_1',
        'name': 'Mixtape 1984',
        'created_at': 1700000000,
        'color_accent': 0xFFFF5E36,
        'description': 'Analog tape tracks',
        'track_count': 12,
      });

      expect(model.id, 'pl_1');
      expect(model.name, 'Mixtape 1984');
      expect(model.colorAccent, 0xFFFF5E36);
      expect(model.trackCount, 12);
    });
  });
}
