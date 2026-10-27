import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'core/constants/app_theme.dart';
import 'core/database/app_database.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Android background media service & notification controls
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.antigravity.rewind.channel.audio',
      androidNotificationChannelName: 'Rewind Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_music',
    );
  } catch (e) {
    debugPrint('JustAudioBackground init warning: $e');
  }

  // Pre-initialize SQLite Database
  try {
    await AppDatabase.instance.database;
  } catch (e) {
    debugPrint('Database init warning: $e');
  }

  // System UI overlay configuration for immersive black background
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF09090B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: RewindApp(),
    ),
  );
}

class RewindApp extends ConsumerWidget {
  const RewindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    return MaterialApp(
      title: 'Rewind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(accentColor: settings.accentColor),
      home: const SplashScreen(),
    );
  }
}

// Retain alias for test backwards-compatibility
typedef SpoolApp = RewindApp;
