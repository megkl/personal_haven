import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays a quiet, offline ambient chord while a journal entry is being written.
///
/// The WAV is generated in memory so the app does not stream audio or bundle a
/// copyrighted music file.
class JournalAmbientAudio {
  final AudioPlayer _player = AudioPlayer(
    playerId: 'personal_haven_journal_ambient',
  );

  bool _prepared = false;
  bool _disposed = false;
  bool _playRequested = false;
  File? _audioFile;

  Future<bool> play() async {
    if (_disposed) return false;
    _playRequested = true;
    try {
      if (!_prepared) {
        final audioFile = await _writeAudioFile();
        await _player.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.media,
              audioFocus: AndroidAudioFocus.gain,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: {AVAudioSessionOptions.mixWithOthers},
            ),
          ),
        );
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(
          DeviceFileSource(audioFile.path, mimeType: 'audio/wav'),
          volume: 0.28,
        );
        _prepared = true;
      } else {
        await _player.resume();
      }

      if (!_playRequested) {
        await _player.pause();
      }
      return true;
    } catch (error, stackTrace) {
      // Ambient audio is optional and must never interrupt journal writing.
      debugPrint('Unable to play journal ambience: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> pause() async {
    _playRequested = false;
    if (!_prepared || _disposed) return;
    try {
      await _player.pause();
    } catch (_) {
      // Ignore optional audio failures.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _playRequested = false;
    await _player.dispose();
    try {
      await _audioFile?.delete();
    } catch (_) {
      // The operating system may already have cleared its temporary file.
    }
  }

  Future<File> _writeAudioFile() async {
    final file = File(
      '${Directory.systemTemp.path}/personal_haven_journal_ambient.wav',
    );
    await file.writeAsBytes(_ambientWav, flush: true);
    _audioFile = file;
    return file;
  }

  static final Uint8List _ambientWav = _buildAmbientWav();

  static Uint8List _buildAmbientWav() {
    const sampleRate = 22050;
    const seconds = 12;
    const channels = 1;
    const bitsPerSample = 16;
    const sampleCount = sampleRate * seconds;
    const bytesPerSample = bitsPerSample ~/ 8;
    const dataLength = sampleCount * bytesPerSample;

    final bytes = ByteData(44 + dataLength);
    var offset = 0;

    void ascii(String value) {
      for (final codeUnit in value.codeUnits) {
        bytes.setUint8(offset++, codeUnit);
      }
    }

    ascii('RIFF');
    bytes.setUint32(offset, 36 + dataLength, Endian.little);
    offset += 4;
    ascii('WAVE');
    ascii('fmt ');
    bytes.setUint32(offset, 16, Endian.little);
    offset += 4;
    bytes.setUint16(offset, 1, Endian.little);
    offset += 2;
    bytes.setUint16(offset, channels, Endian.little);
    offset += 2;
    bytes.setUint32(offset, sampleRate, Endian.little);
    offset += 4;
    bytes.setUint32(
      offset,
      sampleRate * channels * bytesPerSample,
      Endian.little,
    );
    offset += 4;
    bytes.setUint16(offset, channels * bytesPerSample, Endian.little);
    offset += 2;
    bytes.setUint16(offset, bitsPerSample, Endian.little);
    offset += 2;
    ascii('data');
    bytes.setUint32(offset, dataLength, Endian.little);
    offset += 4;

    const frequencies = [130.81, 164.81, 196.00, 261.63];
    for (var index = 0; index < sampleCount; index++) {
      final time = index / sampleRate;
      final breathing = 0.72 + 0.28 * math.sin(2 * math.pi * time / 6);
      final shimmer = 0.88 + 0.12 * math.sin(2 * math.pi * time / 4);
      final fadeSamples = sampleRate ~/ 3;
      final edgeFade = index < fadeSamples
          ? index / fadeSamples
          : index > sampleCount - fadeSamples
          ? (sampleCount - index) / fadeSamples
          : 1.0;

      var wave = 0.0;
      for (var tone = 0; tone < frequencies.length; tone++) {
        final weight = tone == 0 ? 0.42 : 0.18;
        wave +=
            weight *
            math.sin(
              2 * math.pi * frequencies[tone] * time + tone * math.pi / 5,
            );
      }
      wave +=
          0.08 *
          math.sin(2 * math.pi * 392 * time) *
          math.sin(2 * math.pi * time / 8);

      final sample = (wave * breathing * shimmer * edgeFade * 0.34 * 32767)
          .round()
          .clamp(-32768, 32767);
      bytes.setInt16(offset, sample, Endian.little);
      offset += 2;
    }

    return bytes.buffer.asUint8List();
  }
}
