class Formatters {
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDurationMs(int ms) {
    return formatDuration(Duration(milliseconds: ms));
  }

  static String formatTechnicalSpecs({
    required String extension,
    int? bitrate,
    int? sampleRate,
    int? bitDepth,
    bool isLossless = false,
  }) {
    final parts = <String>[];
    final extUpper = extension.toUpperCase();
    parts.add(extUpper);

    if (isLossless) {
      if (bitDepth != null && bitDepth > 16) {
        parts.add('HI-RES $bitDepth-BIT');
      } else if (bitDepth != null) {
        parts.add('$bitDepth-BIT');
      } else {
        parts.add('LOSSLESS');
      }
    }

    if (sampleRate != null && sampleRate > 0) {
      if (sampleRate >= 1000) {
        final khz = (sampleRate / 1000).toStringAsFixed(1).replaceAll('.0', '');
        parts.add('${khz}kHz');
      } else {
        parts.add('${sampleRate}Hz');
      }
    }

    if (bitrate != null && bitrate > 0) {
      parts.add('${bitrate}kbps');
    }

    return parts.join(' \u2022 ');
  }
}
