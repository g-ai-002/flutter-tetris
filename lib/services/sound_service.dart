import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'log_service.dart';
import 'tone_synth.dart';

/// 游戏内会发声的动作。
enum Sfx {
  move,
  rotate,
  hold,
  lock,
  lineClear,
  tetris,
  perfectClear,
  levelUp,
  gameOver,
  win,
}

/// 音效与触感反馈：音频在运行时合成，三个平台共用同一套配方。
class SoundService {
  SoundService._();

  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// 测试注入的音频出口，非空时不再触碰平台播放器。
  @visibleForTesting
  static void Function(Sfx sfx)? sink;

  static final Map<Sfx, AudioSource> _sources = {};
  static final Map<Sfx, Uint8List> _clips = {};
  static Future<void>? _loading;
  static bool _loadFailed = false;

  static const Map<Sfx, List<SynthNote>> _presets = {
    Sfx.move: [
      SynthNote(frequency: 820, start: 0, duration: 0.028, gain: 0.30),
      SynthNote(frequency: 610, start: 0.003, duration: 0.035, gain: 0.20),
    ],
    Sfx.rotate: [
      SynthNote(frequency: 740, start: 0, duration: 0.045, gain: 0.34),
      SynthNote(frequency: 990, start: 0.035, duration: 0.06, gain: 0.32),
    ],
    Sfx.hold: [
      SynthNote(frequency: 520, start: 0, duration: 0.07, gain: 0.34),
      SynthNote(frequency: 392, start: 0.055, duration: 0.1, gain: 0.26),
    ],
    Sfx.lock: [
      SynthNote(
        frequency: 190,
        start: 0,
        duration: 0.075,
        gain: 0.62,
        noise: 0.38,
      ),
      SynthNote(
        frequency: 120,
        start: 0.006,
        duration: 0.12,
        gain: 0.55,
        noise: 0.22,
      ),
    ],
    Sfx.lineClear: [
      SynthNote(frequency: 523.25, start: 0, duration: 0.11, gain: 0.42),
      SynthNote(frequency: 659.25, start: 0.06, duration: 0.12, gain: 0.42),
      SynthNote(frequency: 783.99, start: 0.12, duration: 0.16, gain: 0.40),
    ],
    Sfx.tetris: [
      SynthNote(frequency: 523.25, start: 0, duration: 0.12, gain: 0.45),
      SynthNote(frequency: 659.25, start: 0.07, duration: 0.12, gain: 0.45),
      SynthNote(frequency: 783.99, start: 0.14, duration: 0.12, gain: 0.45),
      SynthNote(frequency: 1046.50, start: 0.21, duration: 0.32),
      SynthNote(frequency: 783.99, start: 0.21, duration: 0.2, gain: 0.24),
    ],
    Sfx.perfectClear: [
      SynthNote(frequency: 1046.50, start: 0, duration: 0.12, gain: 0.38),
      SynthNote(frequency: 1318.51, start: 0.08, duration: 0.14, gain: 0.36),
      SynthNote(frequency: 1567.98, start: 0.17, duration: 0.2, gain: 0.34),
      SynthNote(frequency: 2093.00, start: 0.26, duration: 0.28, gain: 0.30),
    ],
    Sfx.levelUp: [
      SynthNote(frequency: 440, start: 0, duration: 0.08, gain: 0.38),
      SynthNote(frequency: 587.33, start: 0.08, duration: 0.08, gain: 0.38),
      SynthNote(frequency: 880, start: 0.16, duration: 0.18, gain: 0.42),
    ],
    Sfx.gameOver: [
      SynthNote(frequency: 440, start: 0, duration: 0.16, gain: 0.4),
      SynthNote(frequency: 349.23, start: 0.15, duration: 0.18, gain: 0.4),
      SynthNote(frequency: 261.63, start: 0.31, duration: 0.22, gain: 0.4),
      SynthNote(frequency: 196.00, start: 0.5, duration: 0.4, gain: 0.36),
    ],
    Sfx.win: [
      SynthNote(frequency: 523.25, start: 0, duration: 0.14, gain: 0.45),
      SynthNote(frequency: 659.25, start: 0.12, duration: 0.14, gain: 0.45),
      SynthNote(frequency: 783.99, start: 0.24, duration: 0.14, gain: 0.45),
      SynthNote(frequency: 1046.50, start: 0.36, duration: 0.45),
    ],
  };

  static void configure({required bool sound, required bool haptics}) {
    soundEnabled = sound;
    hapticsEnabled = haptics;
  }

  /// 预合成音效并载入 SoLoud 音源；失败时保持静默，不影响游戏。
  static Future<void> init() => _ensureLoaded();

  static Future<void> _ensureLoaded() {
    if (_loadFailed || _sources.isNotEmpty) return Future.value();
    return _loading ??= _load();
  }

  static Future<void> _load() async {
    try {
      final soloud = SoLoud.instance;
      if (!soloud.isInitialized) await soloud.init();
      for (final sfx in Sfx.values) {
        _sources[sfx] = await soloud.loadMem(
          'tetris-${sfx.name}.wav',
          clipOf(sfx),
        );
      }
    } catch (error) {
      _loadFailed = true;
      _disposeAll();
      debugPrint('[SoundService] 音效初始化失败，已静音: $error');
      LogService.warning('音效初始化失败，已静音: $error');
    }
  }

  /// 某个动作对应的合成音频，供测试校验音效配方。
  @visibleForTesting
  static Uint8List clipOf(Sfx sfx) =>
      _clips.putIfAbsent(sfx, () => synthesizeWav(_presets[sfx]!));

  static void play(Sfx sfx) {
    if (soundEnabled) {
      final target = sink;
      if (target != null) {
        target(sfx);
      } else {
        unawaited(_play(sfx));
      }
    }
    if (!hapticsEnabled) return;
    final haptic = switch (sfx) {
      Sfx.move || Sfx.rotate || Sfx.hold => HapticFeedback.selectionClick,
      Sfx.lock || Sfx.lineClear => HapticFeedback.lightImpact,
      Sfx.tetris || Sfx.perfectClear => HapticFeedback.mediumImpact,
      Sfx.levelUp || Sfx.win => HapticFeedback.heavyImpact,
      Sfx.gameOver => HapticFeedback.vibrate,
    };
    haptic();
  }

  static Future<void> _play(Sfx sfx) async {
    try {
      await _ensureLoaded();
      final source = _sources[sfx];
      if (source == null) return;
      final soloud = SoLoud.instance;
      soloud.stopAudioSource(source);
      soloud.play(source);
    } catch (error) {
      debugPrint('[SoundService] 播放失败: $error');
    }
  }

  static void _disposeAll() {
    final sources = _sources.values.toList();
    _sources.clear();
    for (final source in sources) {
      unawaited(_dispose(source));
    }
  }

  static Future<void> _dispose(AudioSource source) async {
    try {
      await SoLoud.instance.disposeSource(source);
    } catch (_) {
      // 音源已失效时无需再处理。
    }
  }

  @visibleForTesting
  static void reset() {
    sink = null;
    _disposeAll();
    _clips.clear();
    _loading = null;
    _loadFailed = false;
    soundEnabled = true;
    hapticsEnabled = true;
  }
}
