import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spool/core/widgets/realistic_cassette_opening_modal.dart';
import 'package:spool/features/audio_player/data/audio_player_service.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/audio_player/domain/playback_state.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';

const track = AudioTrack(
  id: 'regression',
  title: 'Tape One',
  artist: 'Artist',
  album: 'Album',
  durationMs: 180000,
  uri: 'content://media/external/audio/media/42',
  path: '/music/tape.flac',
  fileExtension: 'flac',
);

class QuietAudioService extends AudioPlayerService {
  @override
  Stream<SpoolPlaybackState> get stateStream => const Stream.empty();
}

class RecordingPlaybackNotifier extends PlaybackNotifier {
  RecordingPlaybackNotifier(super.service) {
    state = const SpoolPlaybackState(
      currentTrack: track,
      queue: [track],
      currentIndex: 0,
      isBuffering: true,
    );
  }
  int loads = 0;
  @override
  Future<void> playTrack(AudioTrack track, {List<AudioTrack>? queue}) async {
    loads++;
  }
}

void main() {
  testWidgets(
    'opening a loading tape does not replace its pending audio load',
    (tester) async {
      final service = QuietAudioService();
      final playback = RecordingPlaybackNotifier(service);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [playbackNotifierProvider.overrideWith((ref) => playback)],
          child: MaterialApp(
            home: CassettePage(song: Song.fromAudioTrack(track, 0)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2800));
      expect(playback.loads, 0);
      expect(find.text('THREADING TAPE...'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    },
  );

  test('paused cassette repaints when the real seek position changes', () {
    final song = Song.fromAudioTrack(track, 0);
    final before = CassettePainter(
      song,
      const AlwaysStoppedAnimation(0.0),
      const AlwaysStoppedAnimation(0.1),
    );
    final after = CassettePainter(
      song,
      const AlwaysStoppedAnimation(0.0),
      const AlwaysStoppedAnimation(0.8),
    );
    expect(after.shouldRepaint(before), isTrue);
  });
}
