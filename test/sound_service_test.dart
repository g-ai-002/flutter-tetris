import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tetris/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SoundService().resetForTest();
    });

    test('singleton returns same instance', () {
      final a = SoundService();
      final b = SoundService();
      expect(identical(a, b), true);
    });

    test('init sets defaults', () async {
      final prefs = await SharedPreferences.getInstance();
      final sound = SoundService();
      await sound.init(prefs);
      expect(sound.soundEnabled, true);
      expect(sound.musicEnabled, true);
    });

    test('init respects saved preferences', () async {
      SharedPreferences.setMockInitialValues({
        'sound_enabled': false,
        'music_enabled': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final sound = SoundService();
      await sound.init(prefs);
      expect(sound.soundEnabled, false);
      expect(sound.musicEnabled, false);
    });

    test('setSoundEnabled toggles and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final sound = SoundService();
      await sound.init(prefs);
      await sound.setSoundEnabled(false, prefs);
      expect(sound.soundEnabled, false);
      expect(prefs.getBool('sound_enabled'), false);
      await sound.setSoundEnabled(true, prefs);
      expect(sound.soundEnabled, true);
    });

    test('setMusicEnabled toggles and persists', () async {
      final prefs = await SharedPreferences.getInstance();
      final sound = SoundService();
      await sound.init(prefs);
      await sound.setMusicEnabled(false, prefs);
      expect(sound.musicEnabled, false);
      expect(prefs.getBool('music_enabled'), false);
      await sound.setMusicEnabled(true, prefs);
      expect(sound.musicEnabled, true);
    });

    test('play methods do not throw', () {
      final sound = SoundService();
      sound.playMove();
      sound.playRotate();
      sound.playHardDrop();
      sound.playClear();
      sound.playLevelUp();
      sound.playGameOver();
    });

    test('dispose does not throw', () {
      final sound = SoundService();
      sound.dispose();
    });
  });
}
