import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/log_service.dart';
import '../utils/constants.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  AudioPlayer? _player;
  AudioPlayer? _musicPlayer;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _initialized = false;
  bool _testing = false;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  AudioPlayer get _safePlayer {
    _player ??= AudioPlayer();
    return _player!;
  }

  AudioPlayer get _safeMusicPlayer {
    _musicPlayer ??= AudioPlayer();
    return _musicPlayer!;
  }

  Future<void> init(SharedPreferences prefs) async {
    if (_initialized) return;
    _soundEnabled = prefs.getBool(AppConstants.prefKeySoundEnabled) ?? true;
    _musicEnabled = prefs.getBool(AppConstants.prefKeyMusicEnabled) ?? true;
    _initialized = true;
    LogService.info('音效服务初始化: 音效=$_soundEnabled, 音乐=$_musicEnabled');
  }

  Future<void> setSoundEnabled(bool enabled, SharedPreferences prefs) async {
    _soundEnabled = enabled;
    await prefs.setBool(AppConstants.prefKeySoundEnabled, enabled);
    if (!enabled) {
      try { await _player?.stop(); } catch (_) {}
    }
  }

  Future<void> setMusicEnabled(bool enabled, SharedPreferences prefs) async {
    _musicEnabled = enabled;
    await prefs.setBool(AppConstants.prefKeyMusicEnabled, enabled);
    if (enabled) {
      await _startMusic();
    } else {
      try { await _musicPlayer?.stop(); } catch (_) {}
    }
  }

  void _play(Uint8List wavData) {
    if (_testing || !_soundEnabled) return;
    try { _safePlayer.play(BytesSource(wavData)); } catch (_) {}
  }

  void playMove() => _play(_tone(200, 0.04, 0.3));
  void playRotate() => _play(_tone(300, 0.06, 0.4));
  void playHardDrop() => _play(_tone(80, 0.12, 0.6));
  void playClear() => _play(_tone(500, 0.15, 0.5));
  void playLevelUp() => _play(_sweep(300, 600, 0.2, 0.5));
  void playGameOver() => _play(_sweep(400, 100, 0.5, 0.4));

  Future<void> _startMusic() async {
    if (_testing || !_musicEnabled) return;
    try {
      await _safeMusicPlayer.stop();
      await _safeMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _safeMusicPlayer.play(BytesSource(_musicLoop()));
    } catch (_) {}
  }

  Future<void> startMusicIfEnabled() async {
    if (_musicEnabled) await _startMusic();
  }

  Future<void> stopMusic() async {
    try { await _musicPlayer?.stop(); } catch (_) {}
  }

  void dispose() {
    try { _player?.dispose(); } catch (_) {}
    try { _musicPlayer?.dispose(); } catch (_) {}
  }

  @visibleForTesting
  void resetForTest() {
    _player = null;
    _musicPlayer = null;
    _soundEnabled = true;
    _musicEnabled = true;
    _initialized = false;
    _testing = true;
  }

  // ---- WAV generators ----

  static const _sampleRate = 22050;
  static const _maxAmplitude = 32767;
  static const _wavHeaderSize = 44;
  static const _bitsPerSample = 16;
  static const _numChannels = 1;
  static const _audioFormatPcm = 1;
  static const _musicVolume = 0.15;
  static const _musicDurationSec = 8.0;
  static const _musicNoteCount = 8;

  static Uint8List _generateWav(
    int numSamples,
    double Function(int i, double t) freqFn,
    double volume,
  ) {
    final data = Int16List(numSamples);
    for (var i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final envelope = 1.0 - (i / numSamples);
      data[i] = (sin(2 * pi * freqFn(i, t) * t) * volume * envelope * _maxAmplitude).toInt();
    }
    return _wavBytes(data);
  }

  static Uint8List _tone(double freq, double durationSec, double volume) {
    final numSamples = (_sampleRate * durationSec).toInt();
    return _generateWav(numSamples, (_, __) => freq, volume);
  }

  static Uint8List _sweep(double startFreq, double endFreq, double durationSec, double volume) {
    final numSamples = (_sampleRate * durationSec).toInt();
    return _generateWav(
      numSamples,
      (i, _) => startFreq + (endFreq - startFreq) * (i / numSamples),
      volume,
    );
  }

  static Uint8List _musicLoop() {
    final numSamples = (_sampleRate * _musicDurationSec).toInt();
    final data = Int16List(numSamples);

    const notes = <double>[262, 294, 330, 349, 392, 349, 330, 294];
    const noteLen = _musicDurationSec / _musicNoteCount;

    for (var i = 0; i < numSamples; i++) {
      final t = i / _sampleRate;
      final noteIdx = (t / noteLen).toInt() % notes.length;
      final noteT = t - noteIdx * noteLen;
      final freq = notes[noteIdx];
      final envelope = (1.0 - noteT / noteLen).clamp(0.0, 1.0);
      data[i] = (sin(2 * pi * freq * t) * _musicVolume * envelope * _maxAmplitude).toInt();
    }
    return _wavBytes(data);
  }

  static Uint8List _wavBytes(Int16List samples) {
    final dataBytes = samples.buffer.asUint8List();
    final fileSize = _wavHeaderSize + dataBytes.length;
    final buffer = ByteData(fileSize);
    final byteRate = _sampleRate * _numChannels * (_bitsPerSample ~/ 8);
    final blockAlign = _numChannels * (_bitsPerSample ~/ 8);

    // RIFF header
    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, fileSize - 8, Endian.little);
    buffer.setUint8(8, 0x57); // W
    buffer.setUint8(9, 0x41); // A
    buffer.setUint8(10, 0x56); // V
    buffer.setUint8(11, 0x45); // E

    // fmt chunk
    buffer.setUint8(12, 0x66); // f
    buffer.setUint8(13, 0x6D); // m
    buffer.setUint8(14, 0x74); // t
    buffer.setUint8(15, 0x20); // space
    buffer.setUint32(16, 16, Endian.little); // chunk size
    buffer.setUint16(20, _audioFormatPcm, Endian.little);
    buffer.setUint16(22, _numChannels, Endian.little);
    buffer.setUint32(24, _sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, blockAlign, Endian.little);
    buffer.setUint16(34, _bitsPerSample, Endian.little);

    // data chunk
    buffer.setUint8(36, 0x64); // d
    buffer.setUint8(37, 0x61); // a
    buffer.setUint8(38, 0x74); // t
    buffer.setUint8(39, 0x61); // a
    buffer.setUint32(40, dataBytes.length, Endian.little);

    final result = Uint8List(fileSize);
    result.setRange(0, _wavHeaderSize, buffer.buffer.asUint8List().sublist(0, _wavHeaderSize));
    result.setRange(_wavHeaderSize, fileSize, dataBytes);
    return result;
  }
}
