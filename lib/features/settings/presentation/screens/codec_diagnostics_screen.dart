import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/audio_metadata_helper.dart';
import '../providers/settings_provider.dart';

class CodecDiagnosticsScreen extends ConsumerWidget {
  const CodecDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final themePalette = AppColors.getThemePalette(settings.backgroundTheme);
    const testCodecs = [
      {'ext': 'flac', 'name': 'FLAC (Free Lossless Audio Codec)', 'category': 'Lossless', 'status': 'Native ExoPlayer / Hardware'},
      {'ext': 'wav', 'name': 'WAV / LPCM (16/24/32-bit)', 'category': 'Lossless PCM', 'status': 'Native Android Media3'},
      {'ext': 'mp3', 'name': 'MP3 (MPEG-1/2 Audio Layer III)', 'category': 'Lossy', 'status': 'Universal Support'},
      {'ext': 'm4a', 'name': 'M4A / AAC (Advanced Audio Coding)', 'category': 'Lossy', 'status': 'Universal Support'},
      {'ext': 'ogg', 'name': 'OGG Vorbis', 'category': 'Lossy', 'status': 'Native Android Media3'},
      {'ext': 'opus', 'name': 'Opus Audio Codec', 'category': 'Lossy High-Efficiency', 'status': 'Native Android (API 21+)'},
      {'ext': 'alac', 'name': 'ALAC (Apple Lossless in M4A)', 'category': 'Lossless', 'status': 'Device & Extractor Dependent'},
      {'ext': 'aiff', 'name': 'AIFF (Audio Interchange File Format)', 'category': 'Lossless Uncompressed', 'status': 'Device Audio Track Dependent'},
      {'ext': 'wma', 'name': 'WMA (Windows Media Audio)', 'category': 'Legacy Lossy', 'status': 'OEM Dependent (May fail)'},
      {'ext': 'ape', 'name': "APE (Monkey's Audio)", 'category': 'Lossless Compression', 'status': 'Third-party / Non-Native'},
      {'ext': 'dsd', 'name': 'DSD / DSF / DFF', 'category': 'Direct Stream Digital', 'status': 'High-End DAC / Custom Decoder Required'},
    ];

    return Scaffold(
      backgroundColor: themePalette.background,
      appBar: AppBar(
        title: Text(
          'AUDIO CODEC DIAGNOSTICS',
          style: AppTypography.displaySmall.copyWith(fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.tapeAmber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'PLAYBACK ENGINE: ANDROID MEDIA3 / EXOPLAYER',
                      style: AppTypography.monoSmall.copyWith(color: AppColors.tapeAmber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rewind directly taps into low-latency Android native audio pipelines without lossy downsampling. Android platform codec support varies depending on OEM hardware decoders.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('SUPPORTED FORMAT MATRIX', style: AppTypography.monoSmall.copyWith(letterSpacing: 2, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          ...testCodecs.map((codec) {
            final isNative = AudioMetadataHelper.isCodecSupportedByExoPlayer(codec['ext']!);
            final isLossless = AudioMetadataHelper.isLosslessFormat(codec['ext']!);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isNative ? AppColors.tapeGreen.withAlpha(80) : AppColors.borderSubtle,
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLossless ? AppColors.tapeAmber.withAlpha(30) : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      codec['ext']!.toUpperCase(),
                      style: AppTypography.monoSmall.copyWith(
                        color: isLossless ? AppColors.tapeAmber : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          codec['name']!,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          '${codec['category']} â€¢ ${codec['status']}',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isNative ? Icons.check_circle_outline : Icons.help_outline,
                    color: isNative ? AppColors.tapeGreen : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
