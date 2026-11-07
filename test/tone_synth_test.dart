import 'dart:typed_data';

import 'package:flutter_tetris/services/sound_service.dart';
import 'package:flutter_tetris/services/tone_synth.dart';
import 'package:flutter_test/flutter_test.dart';

int _uint32(Uint8List bytes, int offset) {
  final data = ByteData.sublistView(bytes);
  return data.getUint32(offset, Endian.little);
}

String _ascii(Uint8List bytes, int offset, int length) {
  return String.fromCharCodes(bytes.sublist(offset, offset + length));
}

void main() {
  group('程序化音频', () {
    test('合成结果是合法的 16 位单声道 WAV', () {
      final bytes = synthesizeWav([
        const SynthNote(frequency: 440, start: 0, duration: 0.1),
      ]);
      expect(_ascii(bytes, 0, 4), 'RIFF');
      expect(_ascii(bytes, 8, 4), 'WAVE');
      expect(_ascii(bytes, 36, 4), 'data');
      expect(_uint32(bytes, 24), kSynthSampleRate);
      expect(bytes.length, greaterThan(44));
      final hasSignal = bytes.sublist(44).any((value) => value != 0);
      expect(hasSignal, isTrue);
    });

    test('音效之间长度与配方不同', () {
      SoundService.reset();
      expect(
        SoundService.clipOf(Sfx.tetris).length,
        greaterThan(SoundService.clipOf(Sfx.move).length),
      );
      expect(
        SoundService.clipOf(Sfx.gameOver).length,
        greaterThan(SoundService.clipOf(Sfx.rotate).length),
      );
      for (final sfx in Sfx.values) {
        final clip = SoundService.clipOf(sfx);
        expect(clip.length, greaterThan(44), reason: sfx.name);
      }
    });

    test('音效放大到可听清的音量且不超出满刻度', () {
      SoundService.reset();
      for (final sfx in Sfx.values) {
        final bytes = SoundService.clipOf(sfx);
        final data = ByteData.sublistView(bytes);
        var peak = 0;
        for (var i = 44; i + 1 < bytes.length; i += 2) {
          final value = data.getInt16(i, Endian.little).abs();
          if (value > peak) peak = value;
        }
        expect(peak, greaterThan(16000), reason: sfx.name);
        expect(peak, lessThanOrEqualTo(32767), reason: sfx.name);
      }
      SoundService.reset();
    });

    test('静音与震动开关只影响播放，不影响音效生成', () {
      SoundService.reset();
      final played = <Sfx>[];
      SoundService.sink = played.add;
      SoundService.configure(sound: false, haptics: false);
      SoundService.play(Sfx.move);
      expect(played, isEmpty);

      SoundService.configure(sound: true, haptics: false);
      SoundService.play(Sfx.move);
      expect(played, [Sfx.move]);
      SoundService.reset();
    });

    test('背景音乐是 16 秒的无缝循环', () {
      final bytes = synthesizeMusicWav();
      expect(_ascii(bytes, 0, 4), 'RIFF');
      expect(_uint32(bytes, 24), kMusicSampleRate);
      final samples = (kMusicLoopSeconds * kMusicSampleRate).round();
      expect(_uint32(bytes, 40), samples * 2);
      expect(bytes.length, 44 + samples * 2);
    });
  });
}
