import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../services/log_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  GameState _state;
  Timer? _tickTimer;
  final SharedPreferences _prefs;

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
    LogService.info('游戏开始');
    notifyListeners();
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(Duration(milliseconds: dropIntervalMs), (_) {
      if (_state.isPaused || _state.isGameOver) return;
      _state = _state.moveDown();
      if (_state.isGameOver) {
        _tickTimer?.cancel();
        _saveHighScore();
        LogService.info('游戏结束, 得分: ${_state.score}');
      }
      notifyListeners();
    });
  }

  void moveLeft() {
    _state = _state.moveLeft();
    notifyListeners();
  }

  void moveRight() {
    _state = _state.moveRight();
    notifyListeners();
  }

  void moveDown() {
    _state = _state.moveDown();
    if (_state.isGameOver) {
      _tickTimer?.cancel();
      _saveHighScore();
      LogService.info('游戏结束, 得分: ${_state.score}');
    }
    notifyListeners();
  }

  void hardDrop() {
    _state = _state.hardDrop();
    if (_state.isGameOver) {
      _tickTimer?.cancel();
      _saveHighScore();
      LogService.info('游戏结束, 得分: ${_state.score}');
    }
    notifyListeners();
  }

  void rotate() {
    _state = _state.rotateCW();
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

  void _saveHighScore() {
    _prefs.setInt(AppConstants.prefKeyHighScore, _state.highScore);
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
