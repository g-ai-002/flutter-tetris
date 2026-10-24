import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/services/sound_service.dart';
import 'package:flutter_tetris/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    test('has sensible defaults', () async {
      final settings = (await createTestProviders()).settings;
      expect(settings.darkMode, false);
      expect(settings.soundEnabled, true);
      expect(settings.musicEnabled, true);
      expect(settings.controlMode, ControlMode.both);
    });

    test('restores persisted values', () async {
      final settings = (await createTestProviders(values: {
        AppConstants.prefKeyDarkMode: true,
        AppConstants.prefKeySoundEnabled: false,
        AppConstants.prefKeyMusicEnabled: false,
        AppConstants.prefKeyControlMode: 'buttons',
      })).settings;
      expect(settings.darkMode, true);
      expect(settings.soundEnabled, false);
      expect(settings.musicEnabled, false);
      expect(settings.controlMode, ControlMode.buttons);
    });

    test('setDarkMode persists the value', () async {
      final settings = (await createTestProviders()).settings;
      await settings.setDarkMode(true);
      expect(settings.darkMode, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppConstants.prefKeyDarkMode), true);
    });

    test('setControlMode persists the value', () async {
      final settings = (await createTestProviders()).settings;
      await settings.setControlMode(ControlMode.gesture);
      expect(settings.controlMode, ControlMode.gesture);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AppConstants.prefKeyControlMode), 'gesture');
    });

    test('unknown stored control mode falls back to both', () async {
      final settings = (await createTestProviders(
        values: {AppConstants.prefKeyControlMode: 'bogus'},
      )).settings;
      expect(settings.controlMode, ControlMode.both);
    });

    test('setSoundEnabled syncs SoundService and notifies', () async {
      final settings = (await createTestProviders()).settings;
      var notified = 0;
      settings.addListener(() => notified++);
      await settings.setSoundEnabled(false);
      expect(settings.soundEnabled, false);
      expect(SoundService().soundEnabled, false);
      expect(notified, 1);
    });
  });
}
