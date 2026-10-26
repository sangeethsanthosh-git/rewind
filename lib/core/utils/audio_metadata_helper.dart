class AudioMetadataHelper {
  static const Set<String> supportedExtensions = {
    'mp3',
    'aac',
    'm4a',
    'flac',
    'wav',
    'ogg',
    'opus',
    'aiff',
    'alac',
    'wma',
    'ape',
  };

  static const Set<String> losslessExtensions = {
    'flac',
    'wav',
    'aiff',
    'alac',
    'ape',
  };

  static bool isLosslessFormat(String extension) {
    return losslessExtensions.contains(extension.toLowerCase());
  }

  static String getCodecCategory(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'flac':
        return 'FLAC Lossless';
      case 'wav':
        return 'PCM Uncompressed';
      case 'aiff':
        return 'AIFF Uncompressed';
      case 'alac':
        return 'Apple Lossless';
      case 'mp3':
        return 'MPEG-1 Audio Layer III';
      case 'aac':
        return 'Advanced Audio Coding';
      case 'm4a':
        return 'MPEG-4 Audio';
      case 'ogg':
        return 'Ogg Vorbis';
      case 'opus':
        return 'Opus Interactive';
      case 'ape':
        return "Monkey's Audio Lossless";
      case 'wma':
        return 'Windows Media Audio';
      default:
        return ext.toUpperCase();
    }
  }

  static bool isCodecSupportedByExoPlayer(String extension) {
    final ext = extension.toLowerCase();
    // Android ExoPlayer / Media3 native codecs:
    return [
      'mp3',
      'aac',
      'm4a',
      'flac',
      'wav',
      'ogg',
      'opus',
    ].contains(ext);
  }
}
