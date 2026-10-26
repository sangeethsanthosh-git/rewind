import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioMetadataResult {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? trackNumber;
  final String? artworkPath;
  final String? lyrics;

  const AudioMetadataResult({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.trackNumber,
    this.artworkPath,
    this.lyrics,
  });
}

class AudioTagExtractor {
  static Directory? _artCacheDir;

  static Future<Directory> _getCacheDir() async {
    if (_artCacheDir != null && await _artCacheDir!.exists()) {
      return _artCacheDir!;
    }
    final baseDir = await getApplicationSupportDirectory();
    final cacheDir = Directory(p.join(baseDir.path, 'spool_art_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _artCacheDir = cacheDir;
    return cacheDir;
  }

  /// Extracts metadata and embedded album artwork from an audio file.
  static Future<AudioMetadataResult> extract(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const AudioMetadataResult();
    }

    final ext = p.extension(filePath).replaceAll('.', '').toLowerCase();
    try {
      if (ext == 'flac') {
        return await _extractFlac(file);
      } else if (ext == 'mp3') {
        return await _extractId3(file);
      } else if (ext == 'm4a' || ext == 'aac' || ext == 'mp4') {
        return await _extractMp4(file);
      }
    } catch (_) {
      // Graceful fallback on malformed or unsupported file headers
    }

    return const AudioMetadataResult();
  }

  /// FLAC Metadata Parser (Block 4: Vorbis Comments, Block 6: Picture)
  static Future<AudioMetadataResult> _extractFlac(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final header = await raf.read(4);
      if (header.length < 4 || String.fromCharCodes(header) != 'fLaC') {
        return const AudioMetadataResult();
      }

      String? title;
      String? artist;
      String? album;
      String? genre;
      int? trackNumber;
      String? artworkPath;
      String? lyrics;

      while (true) {
        final blockHeader = await raf.read(4);
        if (blockHeader.length < 4) break;

        final isLast = (blockHeader[0] & 0x80) != 0;
        final blockType = blockHeader[0] & 0x7F;
        final blockLength = (blockHeader[1] << 16) | (blockHeader[2] << 8) | blockHeader[3];

        if (blockType == 6) {
          // PICTURE metadata block
          final data = await raf.read(blockLength);
          if (data.length >= blockLength) {
            final bd = ByteData.sublistView(data);
            int offset = 4; // skip picture type
            if (offset + 4 <= data.length) {
              final mimeLen = bd.getUint32(offset);
              offset += 4 + mimeLen;
              if (offset + 4 <= data.length) {
                final descLen = bd.getUint32(offset);
                offset += 4 + descLen + 16; // skip desc + 16 bytes (w, h, depth, colors)
                if (offset + 4 <= data.length) {
                  final picLen = bd.getUint32(offset);
                  offset += 4;
                  if (offset + picLen <= data.length && picLen > 0) {
                    final picBytes = data.sublist(offset, offset + picLen);
                    artworkPath = await _saveArtBytes(file.path, picBytes);
                  }
                }
              }
            }
          }
        } else if (blockType == 4) {
          // VORBIS_COMMENT metadata block
          final data = await raf.read(blockLength);
          if (data.length >= blockLength) {
            final bd = ByteData.sublistView(data);
            int offset = 0;
            if (offset + 4 <= data.length) {
              final vendorLen = bd.getUint32(offset, Endian.little);
              offset += 4 + vendorLen;
              if (offset + 4 <= data.length) {
                final numComments = bd.getUint32(offset, Endian.little);
                offset += 4;
                for (int i = 0; i < numComments && offset + 4 <= data.length; i++) {
                  final clen = bd.getUint32(offset, Endian.little);
                  offset += 4;
                  if (offset + clen <= data.length) {
                    final comment = String.fromCharCodes(data.sublist(offset, offset + clen));
                    offset += clen;
                    final eqIdx = comment.indexOf('=');
                    if (eqIdx != -1) {
                      final key = comment.substring(0, eqIdx).toUpperCase().trim();
                      final val = comment.substring(eqIdx + 1).trim();
                      if (key == 'TITLE' && title == null) title = val;
                      if (key == 'ARTIST' && artist == null) artist = val;
                      if (key == 'ALBUM' && album == null) album = val;
                      if (key == 'GENRE' && genre == null) genre = val;
                      if ((key == 'LYRICS' || key == 'UNSYNCEDLYRICS') && lyrics == null) {
                        lyrics = val;
                      }
                      if (key == 'TRACKNUMBER' && trackNumber == null) {
                        trackNumber = int.tryParse(val.split('/')[0].trim());
                      }
                    }
                  } else {
                    break;
                  }
                }
              }
            }
          }
        } else {
          // Skip other block types
          await raf.setPosition(await raf.position() + blockLength);
        }

        if (isLast) break;
      }

      return AudioMetadataResult(
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        trackNumber: trackNumber,
        artworkPath: artworkPath,
        lyrics: lyrics,
      );
    } finally {
      await raf.close();
    }
  }

  /// ID3v2 Parser for MP3 files (APIC frame, TIT2, TPE1, TALB)
  static Future<AudioMetadataResult> _extractId3(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final header = await raf.read(10);
      if (header.length < 10 ||
          header[0] != 0x49 || // 'I'
          header[1] != 0x44 || // 'D'
          header[2] != 0x33) {  // '3'
        return const AudioMetadataResult();
      }

      final version = header[3]; // e.g. 3 or 4
      final tagSize = ((header[6] & 0x7F) << 21) |
          ((header[7] & 0x7F) << 14) |
          ((header[8] & 0x7F) << 7) |
          (header[9] & 0x7F);

      final tagData = await raf.read(tagSize);
      int offset = 0;

      String? title;
      String? artist;
      String? album;
      String? artworkPath;
      String? lyrics;

      while (offset + 10 < tagData.length) {
        final frameId = String.fromCharCodes(tagData.sublist(offset, offset + 4));
        if (frameId.codeUnits.any((c) => c == 0)) break;

        int frameSize;
        if (version == 4) {
          // ID3v2.4 syncsafe frame size
          frameSize = ((tagData[offset + 4] & 0x7F) << 21) |
              ((tagData[offset + 5] & 0x7F) << 14) |
              ((tagData[offset + 6] & 0x7F) << 7) |
              (tagData[offset + 7] & 0x7F);
        } else {
          // ID3v2.3 standard big endian
          frameSize = (tagData[offset + 4] << 24) |
              (tagData[offset + 5] << 16) |
              (tagData[offset + 6] << 8) |
              tagData[offset + 7];
        }

        offset += 10;
        if (frameSize <= 0 || offset + frameSize > tagData.length) break;

        final frameBytes = tagData.sublist(offset, offset + frameSize);
        offset += frameSize;

        if (frameId == 'APIC' && artworkPath == null) {
          // Attached Picture frame
          // [encoding (1)] [mime (null terminated)] [picType (1)] [desc (null terminated)] [data]
          int pOffset = 1;
          while (pOffset < frameBytes.length && frameBytes[pOffset] != 0) {
            pOffset++;
          }
          pOffset++; // Skip null terminator
          pOffset++; // Skip picture type (1 byte)
          // Skip description null terminator
          while (pOffset < frameBytes.length && frameBytes[pOffset] != 0) {
            pOffset++;
          }
          pOffset++;

          if (pOffset < frameBytes.length) {
            // Find start of JPEG (FF D8 FF) or PNG (89 50 4E 47)
            int picStart = pOffset;
            for (int i = pOffset; i < frameBytes.length - 3; i++) {
              if (frameBytes[i] == 0xFF && frameBytes[i + 1] == 0xD8 && frameBytes[i + 2] == 0xFF) {
                picStart = i;
                break;
              } else if (frameBytes[i] == 0x89 &&
                  frameBytes[i + 1] == 0x50 &&
                  frameBytes[i + 2] == 0x4E &&
                  frameBytes[i + 3] == 0x47) {
                picStart = i;
                break;
              }
            }
            final picData = frameBytes.sublist(picStart);
            if (picData.length > 32) {
              artworkPath = await _saveArtBytes(file.path, picData);
            }
          }
        } else if (frameId == 'TIT2' && title == null) {
          title = _decodeTextFrame(frameBytes);
        } else if (frameId == 'TPE1' && artist == null) {
          artist = _decodeTextFrame(frameBytes);
        } else if (frameId == 'TALB' && album == null) {
          album = _decodeTextFrame(frameBytes);
        } else if ((frameId == 'USLT' || frameId == 'SYLT' || frameId == 'ULT') && lyrics == null) {
          if (frameBytes.length > 4) {
            int lOffset = 4; // skip encoding byte + 3-char language
            while (lOffset < frameBytes.length && frameBytes[lOffset] != 0) {
              lOffset++;
            }
            lOffset++; // skip null descriptor terminator
            if (lOffset < frameBytes.length) {
              try {
                lyrics = _decodeTextFrame(Uint8List.fromList([frameBytes[0], ...frameBytes.sublist(lOffset)]));
              } catch (_) {
                lyrics = String.fromCharCodes(frameBytes.sublist(lOffset));
              }
            }
          }
        }
      }

      return AudioMetadataResult(
        title: title,
        artist: artist,
        album: album,
        artworkPath: artworkPath,
        lyrics: lyrics,
      );
    } finally {
      await raf.close();
    }
  }

  /// MP4 / M4A Parser for 'covr' artwork atom
  static Future<AudioMetadataResult> _extractMp4(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      final length = await raf.length();
      // Look for 'covr' and 'data' atoms in the first 2 MB or entire file if smaller
      final searchLength = length > 2000000 ? 2000000 : length;
      final bytes = await raf.read(searchLength);

      for (int i = 0; i < bytes.length - 8; i++) {
        // Look for 'covr'
        if (bytes[i] == 0x63 && bytes[i + 1] == 0x6F && bytes[i + 2] == 0x76 && bytes[i + 3] == 0x72) {
          // Look for 'data' atom following 'covr'
          for (int j = i + 4; j < i + 40 && j < bytes.length - 8; j++) {
            if (bytes[j] == 0x64 && bytes[j + 1] == 0x61 && bytes[j + 2] == 0x74 && bytes[j + 3] == 0x61) {
              final picStart = j + 12; // skip 'data' + flags
              // Find JPEG or PNG magic
              for (int k = picStart; k < picStart + 24 && k < bytes.length - 3; k++) {
                if ((bytes[k] == 0xFF && bytes[k + 1] == 0xD8) ||
                    (bytes[k] == 0x89 && bytes[k + 1] == 0x50 && bytes[k + 2] == 0x4E)) {
                  // Found picture start!
                  final bd = ByteData.sublistView(bytes);
                  final dataAtomLen = bd.getUint32(j - 4);
                  final picLen = dataAtomLen - 16;
                  if (k + picLen <= bytes.length) {
                    final picData = bytes.sublist(k, k + picLen);
                    final artPath = await _saveArtBytes(file.path, picData);
                    return AudioMetadataResult(artworkPath: artPath);
                  }
                }
              }
            }
          }
        }
      }
      return const AudioMetadataResult();
    } finally {
      await raf.close();
    }
  }

  static String _decodeTextFrame(Uint8List bytes) {
    if (bytes.isEmpty) return '';
    final encoding = bytes[0];
    final textBytes = bytes.sublist(1);
    if (encoding == 0) {
      // ISO-8859-1
      return String.fromCharCodes(textBytes).replaceAll('\x00', '').trim();
    } else {
      // UTF-8 or UTF-16
      try {
        return String.fromCharCodes(textBytes).replaceAll('\x00', '').trim();
      } catch (_) {
        return '';
      }
    }
  }

  static Future<String> _saveArtBytes(String sourcePath, Uint8List bytes) async {
    final cacheDir = await _getCacheDir();
    final hash = sourcePath.hashCode.abs();
    final artFile = File(p.join(cacheDir.path, 'art_$hash.jpg'));
    await artFile.writeAsBytes(bytes, flush: true);
    return artFile.path;
  }
}
