import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  GameState _state;
  Timer? _tickTimer;
  final SharedPreferences _prefs;
  final SoundService _sound = SoundService();

  GameProvider(this._prefs)
      : _state = GameState.initial(
          highScore: _prefs.getInt(AppConstants.prefKeyHighScore) ?? 0,
        );

  GameState get state => _state;

  int get dropIntervalMs => max(100, 800 - (_state.level - 1) * 70);

  void start() {
    if (_state.isGameOver) {
      _state = GameState.initial(highScore: _state.highScore);
    } else if (_state.isPaused) {
      _state = _state.togglePause();
    }
    _startTick();
    _sound.startMusicIfEnabled();
    LogService.info('游戏开始');
    notifyListeners();
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(Duration(milliseconds: dropIntervalMs), (_) {
      if (_state.isPaused || _state.isGameOver) return;
      final prev = _state;
      _state = _state.moveDown();
      _checkSoundEffects(prev);
      _checkGameOver();
      notifyListeners();
    });
  }

  void _checkGameOver() {
    if (_state.isGameOver) {
      _tickTimer?.cancel();
      _saveHighScore();
      _sound.playGameOver();
      LogService.info('游戏结束, 得分: ${_state.score}');
    }
  }

  void moveLeft() {
    final prev = _state;
    _state = _state.moveLeft();
    if (_state.currentX != prev.currentX) _sound.playMove();
    notifyListeners();
  }

  void moveRight() {
    final prev = _state;
    _state = _state.moveRight();
    if (_state.currentX != prev.currentX) _sound.playMove();
    notifyListeners();
  }

  void moveDown() {
    final prev = _state;
    _state = _state.moveDown();
    _checkSoundEffects(prev);
    _checkGameOver();
    notifyListeners();
  }

  void hardDrop() {
    final prev = _state;
    _state = _state.hardDrop();
    _sound.playHardDrop();
    _checkSoundEffects(prev);
    _checkGameOver();
    notifyListeners();
  }

  void rotate() {
    final prev = _state;
    _state = _state.rotateCW();
    if (_state.currentPiece.shape != prev.currentPiece.shape) {
      _sound.playRotate();
    }
    notifyListeners();
  }

  void togglePause() {
    _state = _state.togglePause();
    if (_state.isPaused) {
      _tickTimer?.cancel();
    } else {
      _startTick();
    }
    notifyListeners();
  }

  void _checkSoundEffects(GameState prev) {
    if (_state.isGameOver) return;
    if (_state.linesCleared > prev.linesCleared) {
      if (_state.level > prev.level) {
        _sound.playLevelUp();
      } else {
        _sound.playClear();
      }
    }
  }

  void _saveHighScore() {
    _prefs.setInt(AppConstants.prefKeyHighScore, _state.highScore);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
