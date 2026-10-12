import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';

/// 应用级设置（外观 / 音效 / 操控方式），统一读写 SharedPreferences。
class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final SoundService _sound;

  SettingsProvider(this._prefs, {SoundService? sound})
      : _sound = sound ?? SoundService() {
    _darkMode = _prefs.getBool(AppConstants.prefKeyDarkMode) ?? false;
    _soundEnabled = _prefs.getBool(AppConstants.prefKeySoundEnabled) ?? true;
    _musicEnabled = _prefs.getBool(AppConstants.prefKeyMusicEnabled) ?? true;
    _controlMode = ControlMode.fromName(
      _prefs.getString(AppConstants.prefKeyControlMode),
    );
  }

  late bool _darkMode;
  late bool _soundEnabled;
  late bool _musicEnabled;
  late ControlMode _controlMode;

  bool get darkMode => _darkMode;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  ControlMode get controlMode => _controlMode;

  Future<void> setDarkMode(bool value) async {
    if (_darkMode == value) return;
    _darkMode = value;
    await _prefs.setBool(AppConstants.prefKeyDarkMode, value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled == value) return;
    _soundEnabled = value;
    await _sound.setSoundEnabled(value, _prefs);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    if (_musicEnabled == value) return;
    _musicEnabled = value;
    await _sound.setMusicEnabled(value, _prefs);
    notifyListeners();
  }

  Future<void> setControlMode(ControlMode value) async {
    if (_controlMode == value) return;
    _controlMode = value;
    await _prefs.setString(AppConstants.prefKeyControlMode, value.name);
    notifyListeners();
  }
}
