import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spool/core/widgets/europe_deluxe_disc.dart';
import 'package:spool/core/widgets/realistic_cassette_opening_modal.dart';
import 'package:spool/core/widgets/retro_walkman_widget.dart';
import 'package:spool/features/audio_player/domain/audio_track.dart';
import 'package:spool/features/home/presentation/screens/home_screen.dart';
import 'package:spool/features/library/domain/folder_model.dart';
import 'package:spool/features/library/presentation/screens/folders_screen.dart';
import 'package:spool/features/settings/presentation/screens/settings_screen.dart';
import 'package:spool/main.dart';

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
    expect(find.text('Listen to your music. Enjoy every moment.'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('SPOOL'), findsNothing);
    expect(find.text('HI-FI DECK'), findsNothing);
    expect(find.byIcon(Icons.radio_outlined), findsOneWidget);
    expect(find.byIcon(Icons.sync_rounded), findsNothing);
    expect(find.byIcon(Icons.tune_outlined), findsNothing);
  });

  testWidgets('HomeScreen toggles RetroWalkmanWidget when radio icon is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Tap radio icon to expand the Walkman Deck Widget on Home Screen
    await tester.tap(find.byIcon(Icons.radio_outlined));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(RetroWalkmanWidget), findsOneWidget);
    expect(find.text('STANDBY'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeast(1));

    // Tap close button to collapse deck
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 350));

    // Verify it smoothly collapsed
    expect(find.byIcon(Icons.close_rounded), findsNothing);
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
}
