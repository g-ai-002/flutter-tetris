import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_mode.dart';
import '../models/game_state.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  GameState _state;
  Timer? _tickTimer;
  Timer? _secondTimer;
  final SharedPreferences _prefs;
  final SoundService _sound = SoundService();
  GameMode _selectedMode = GameMode.classic;

  GameProvider(this._prefs)
      : _state = GameState.initial(
          highScore: _prefs.getInt(AppConstants.prefKeyHighScore) ?? 0,
        );

  GameState get state => _state;
  GameMode get selectedMode => _selectedMode;

  int get dropIntervalMs => max(100, 800 - (_state.level - 1) * 70);

  void selectMode(GameMode mode) {
    _selectedMode = mode;
    _state = GameState.initial(
      highScore: _prefs.getInt(AppConstants.prefKeyHighScore) ?? 0,
      mode: mode,
    );
    _tickTimer?.cancel();
    _secondTimer?.cancel();
    _sound.stopMusic();
    notifyListeners();
  }

  void start() {
    if (_state.isGameOver) {
      _state = GameState.initial(
        highScore: _state.highScore,
        mode: _selectedMode,
      );
    } else if (_state.isPaused) {
      _state = _state.togglePause();
    }
    _startTick();
    if (_state.gameMode == GameMode.timed) _startSecondTimer();
    _sound.startMusicIfEnabled();
    LogService.info('游戏开始, 模式: ${_state.gameMode.label}');
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

  void _startSecondTimer() {
    _secondTimer?.cancel();
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isPaused || _state.isGameOver) return;
      _state = _state.tickSecond();
      if (_state.isGameOver) {
        _secondTimer?.cancel();
        _checkGameOver();
      }
      notifyListeners();
    });
  }

  void _checkGameOver() {
    if (_state.isGameOver) {
      _tickTimer?.cancel();
      _secondTimer?.cancel();
      _saveHighScore();
      _sound.playGameOver();
      HistoryService.addRecord(
        score: _state.score,
        level: _state.level,
        linesCleared: _state.linesCleared,
      );
      LogService.info('游戏结束, 得分: ${_state.score}, 完成: ${_state.isCompleted}');
    }
  }

  void moveLeft() => _moveHorizontal(_state.moveLeft);
  void moveRight() => _moveHorizontal(_state.moveRight);

  void _moveHorizontal(GameState Function() moveAction) {
    final prev = _state;
    _state = moveAction();
    if (_state.currentX != prev.currentX) _sound.playMove();
    notifyListeners();
  }

  void moveDown() {
    if (_state.isGameOver) return;
    final prev = _state;
    _state = _state.moveDown();
    _checkSoundEffects(prev);
    _checkGameOver();
    notifyListeners();
  }

  void hardDrop() {
    if (_state.isGameOver) return;
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
      _secondTimer?.cancel();
    } else {
      _startTick();
      if (_state.gameMode == GameMode.timed) _startSecondTimer();
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
    _secondTimer?.cancel();
    super.dispose();
  }
}
