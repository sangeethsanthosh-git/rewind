import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spool/core/widgets/cassette_tape_widget.dart';
import 'package:spool/core/widgets/europe_deluxe_disc.dart';
import 'package:spool/core/widgets/realistic_cassette_opening_modal.dart';
import 'package:spool/core/widgets/retro_walkman_widget.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/audio_player/data/audio_player_service.dart';
import 'package:spool/features/audio_player/domain/playback_state.dart';
import 'package:spool/features/audio_player/presentation/providers/audio_player_provider.dart';
import 'package:spool/features/audio_player/presentation/screens/now_playing_screen.dart';
import 'package:spool/features/audio_player/presentation/screens/walkman_player_screen.dart';
import 'package:spool/features/home/presentation/screens/home_screen.dart';
import 'package:spool/features/library/domain/folder_model.dart';
import 'package:spool/features/library/presentation/screens/folders_screen.dart';
import 'package:spool/features/settings/presentation/screens/settings_screen.dart';
import 'package:spool/features/navigation/presentation/screens/main_shell_screen.dart';
import 'package:spool/main.dart';

class _QuietTestAudioService extends AudioPlayerService {
  final SpoolPlaybackState initialState;
  _QuietTestAudioService([this.initialState = const SpoolPlaybackState()]);

  @override
  SpoolPlaybackState get currentState => initialState;

  @override
  Stream<SpoolPlaybackState> get stateStream => const Stream.empty();
}

class _FixedTrackPlaybackNotifier extends PlaybackNotifier {
  _FixedTrackPlaybackNotifier(super.service);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Spool App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SpoolApp(),
      ),
    );

    // Allow splash screen animations and navigation timer to settle
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify SpoolApp root renders
    expect(find.byType(SpoolApp), findsOneWidget);
  });

  testWidgets('HomeScreen header displays REWIND, wording image, and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('REWIND'), findsAtLeast(1));
    expect(find.text('YOUR MUSIC. PRESERVED ON TAPE.'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('SPOOL'), findsNothing);
    expect(find.text('HI-FI DECK'), findsNothing);
    expect(find.byIcon(Icons.radio_outlined), findsNothing);
    expect(find.byIcon(Icons.sync_rounded), findsNothing);
    expect(find.byIcon(Icons.tune_outlined), findsNothing);
  });

  testWidgets('RetroWalkmanWidget renders STANDBY and controls cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RetroWalkmanWidget(),
          ),
        ),
      ),
    );

    expect(find.byType(RetroWalkmanWidget), findsOneWidget);
    expect(find.text('STANDBY'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeast(1));
  });

  testWidgets('EuropeDeluxeDisc renders cleanly and handles tap', (WidgetTester tester) async {
    const testTrack = AudioTrack(
      id: 'test_track_1',
      title: 'Bad Eyes Villain Theme',
      artist: 'Anirudh Ravichander',
      album: 'Kaththi',
      durationMs: 90000,
      uri: 'content://test',
      path: '/test/path.flac',
      fileExtension: 'flac',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 600,
            child: EuropeDeluxeDisc(
              title: 'DOWNLOADS',
              subtitle: '1 TRACK • LOCAL REEL',
              tracks: const [testTrack],
              onTrackTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(EuropeDeluxeDisc), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);
  });

  testWidgets('RealisticCassetteOpeningModal renders J-card and cassette controls', (WidgetTester tester) async {
    const testTrack = AudioTrack(
      id: 'test_track_2',
      title: 'Innate Melancholy',
      artist: 'Jos Eckert',
      album: 'Melancholy (Deluxe Edition)',
      durationMs: 120000,
      uri: 'content://test2',
      path: '/test/path2.flac',
      fileExtension: 'flac',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RealisticCassetteOpeningModal(
            track: testTrack,
            allTracks: [testTrack],
            initialIndex: 0,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));

    expect(find.textContaining('Innate Melancholy'), findsAtLeast(1));
    expect(find.text('Jos Eckert'), findsOneWidget);
    expect(find.text('SIDE A'), findsOneWidget);
  });

  testWidgets('SettingsScreen displays wallpaper canvas, accent swatches, and developer info', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('CUSTOM IMAGE BACKGROUND & CANVAS'), findsOneWidget);
    expect(find.text('Custom Image Wallpaper'), findsOneWidget);
    expect(find.text('Dynamic Song Canvas'), findsOneWidget);
    expect(find.text('Background Blur'), findsOneWidget);
    expect(find.text('BUTTON & ACCENT COLOR'), findsOneWidget);
    expect(find.text('Neon Orange'), findsOneWidget);
    expect(find.text('Cyber Lime'), findsOneWidget);

    // Tap Cyber Lime accent color
    await tester.tap(find.text('Cyber Lime'));
    await tester.pumpAndSettle();

    // Scroll down to Developer & Support Section
    await tester.scrollUntilVisible(find.text('DEVELOPER & SUPPORT'), 300);
    await tester.pumpAndSettle();

    expect(find.text('DEVELOPER & SUPPORT'), findsOneWidget);
    expect(find.text('Sangeeth Santhosh'), findsOneWidget);
    expect(find.text('Buy Me a Coffee'), findsOneWidget);
    expect(find.text('GitHub Profile & Source'), findsOneWidget);

    // Allow async settings persistence and sqflite lock timer to settle
    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('FoldersScreen renders empty state and supports EuropeDeluxeDisc folders', (WidgetTester tester) async {
    const testTrack = AudioTrack(
      id: 'test_track_3',
      title: 'Villain Theme',
      artist: 'Anirudh',
      album: 'Soundtrack',
      durationMs: 80000,
      uri: 'content://test3',
      path: '/Downloads/Music/theme.flac',
      fileExtension: 'flac',
    );

    const testFolder = FolderModel(
      path: '/Downloads/Music',
      name: 'Music',
      tracks: [testTrack],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: EuropeDeluxeDisc(
                title: 'FOLDERS REEL',
                subtitle: '1 FOLDER INDEXED',
                folders: const [testFolder],
                onFolderTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(EuropeDeluxeDisc), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);

    // Verify FoldersScreen root widget renders
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FoldersScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    expect(find.byType(FoldersScreen), findsOneWidget);
  });

  testWidgets('NowPlayingScreen and CassettePage render realistic opening animation with real audio track', (WidgetTester tester) async {
    const testTrack = AudioTrack(
      id: 'test_track_banner',
      title: 'Aaromal',
      artist: 'Vishal Chandrashekhar',
      album: 'Sita Ramam',
      durationMs: 240000,
      uri: 'content://test/aaromal',
      path: '/test/aaromal.mp3',
      fileExtension: 'mp3',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CassettePage(
              song: Song(
                'Aaromal',
                'Vishal Chandrashekhar',
                'Sita Ramam',
                Color(0xFFD9582B),
                Colors.white,
                2,
                audioTrack: testTrack,
              ),
              allTracks: [testTrack],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify CassettePage is rendered with the title and artist
    expect(find.byType(CassettePage), findsOneWidget);
    expect(find.text('Aaromal'), findsWidgets);
    expect(find.text('Vishal Chandrashekhar'), findsWidgets);

    await tester.pump(const Duration(seconds: 11));
  });

  testWidgets('CassetteTapeWidget renders photo-realistic cassette with rotating spools and album art sticker', (WidgetTester tester) async {
    const testTrack = AudioTrack(
      id: '999',
      title: 'Bethlehem Kudumba Unit',
      artist: 'Nivin Pauly, Mamitha Baiju',
      album: 'Bethlehem Kudumba Unit',
      durationMs: 240000,
      uri: 'content://test/bethlehem',
      path: '/test/bethlehem.mp3',
      fileExtension: 'mp3',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: CassetteTapeWidget(
                  track: testTrack,
                  isPlaying: true,
                  position: Duration(seconds: 45),
                  duration: Duration(seconds: 240),
                  accentColor: Color(0xFF1DF74B),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(CassetteTapeWidget), findsOneWidget);
    expect(find.text('Bethlehem Kudumba Unit'), findsOneWidget);
    expect(find.text('SIDE A'), findsOneWidget);
    expect(find.text('100 • 50 • 0'), findsOneWidget);
  });

  testWidgets('WalkmanPlayerScreen renders 3D hinged door, spools, tactile keys and customizer modal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WalkmanPlayerScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(WalkmanPlayerScreen), findsOneWidget);
    expect(find.text('PORTABLE STEREO CASSETTE PLAYER'), findsOneWidget);
    expect(find.text('SONY'), findsOneWidget);
    expect(find.text('WALKMAN'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('REW'), findsOneWidget);
    expect(find.text('FF'), findsOneWidget);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

    // Open Customizer Modal
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    expect(find.text('WALKMAN CUSTOMIZER'), findsOneWidget);
    expect(find.text('Classic TPS-L2'), findsOneWidget);
    expect(find.text('Solar Yellow'), findsOneWidget);
    expect(find.text('Stealth Black'), findsOneWidget);
  });

  testWidgets('MainShellScreen contains WALKMAN tab in navbar and switches cleanly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainShellScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('WALKMAN'), findsOneWidget);
    await tester.tap(find.text('WALKMAN'));
    await tester.pumpAndSettle();
    expect(find.byType(WalkmanPlayerScreen), findsOneWidget);
    expect(find.text('SONY'), findsOneWidget);
    expect(find.text('WALKMAN'), findsWidgets);
  });

  testWidgets('NowPlayingScreen conditionally shows or hides lyrics tab based on track metadata', (WidgetTester tester) async {
    const trackNoLyrics = AudioTrack(
      id: 'track_1',
      title: 'Instrumental',
      artist: 'Retro Artist',
      album: 'Tape 1',
      durationMs: 120000,
      uri: 'test://track_1',
      path: '/test/track_1.mp3',
      fileExtension: 'mp3',
      lyrics: null,
    );

    final service = _QuietTestAudioService(const SpoolPlaybackState(
      currentTrack: trackNoLyrics,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration(seconds: 120),
    ));

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('no_lyrics_scope'),
        overrides: [
          playbackNotifierProvider.overrideWith((ref) => _FixedTrackPlaybackNotifier(service)),
        ],
        child: const MaterialApp(
          home: NowPlayingScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('LYRICS'), findsNothing);

    const trackWithLyrics = AudioTrack(
      id: 'track_2',
      title: 'Song with Words',
      artist: 'Retro Artist',
      album: 'Tape 2',
      durationMs: 120000,
      uri: 'test://track_2',
      path: '/test/track_2.mp3',
      fileExtension: 'mp3',
      lyrics: 'Line 1: Memory on magnetic tape\nLine 2: Rewinding back to start',
    );

    final service2 = _QuietTestAudioService(const SpoolPlaybackState(
      currentTrack: trackWithLyrics,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration(seconds: 120),
    ));

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('with_lyrics_scope'),
        overrides: [
          playbackNotifierProvider.overrideWith((ref) => _FixedTrackPlaybackNotifier(service2)),
        ],
        child: const MaterialApp(
          home: NowPlayingScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
  });

  testWidgets('WalkmanPlayerScreen supports swapping cassettes when open in case', (WidgetTester tester) async {
    const track1 = AudioTrack(
      id: 'tape_a',
      title: 'Cassette Track A',
      artist: 'Artist A',
      album: 'Album A',
      durationMs: 180000,
      uri: 'test://tape_a',
      path: '/test/tape_a.mp3',
      fileExtension: 'mp3',
    );
    const track2 = AudioTrack(
      id: 'tape_b',
      title: 'Cassette Track B',
      artist: 'Artist B',
      album: 'Album B',
      durationMs: 200000,
      uri: 'test://tape_b',
      path: '/test/tape_b.mp3',
      fileExtension: 'mp3',
    );

    final service = _QuietTestAudioService(const SpoolPlaybackState(
      currentTrack: null,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
      queue: [track1, track2],
    ));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackNotifierProvider.overrideWith((ref) => _FixedTrackPlaybackNotifier(service)),
        ],
        child: const MaterialApp(
          home: WalkmanPlayerScreen(),
        ),
      ),
    );

    await tester.pump();
    // At start, currentTrack is null, so _step is 0
    expect(find.text('OPEN LID'), findsOneWidget);
    // Open lid
    await tester.tap(find.text('OPEN LID'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    // Now in Step 1: case is open, swapper pill is visible
    expect(find.text('TAPE 1/2'), findsOneWidget);
    expect(find.text('Cassette Track A'), findsWidgets);

    // Tap NEXT to swap to Tape 2
    await tester.tap(find.text('NEXT'));
    await tester.pump();
    expect(find.text('TAPE 2/2'), findsOneWidget);
    expect(find.text('Cassette Track B'), findsWidgets);

    // Tap INSERT TAPE to load it into the bay
    await tester.tap(find.text('INSERT TAPE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('CLOSE LID'), findsOneWidget);
  });
}
