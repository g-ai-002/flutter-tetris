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
  final SharedPreferences _prefs;
  final SoundService _sound = SoundService();
  GameMode _selectedMode = GameMode.classic;

  /// 由 Flame 的游戏循环驱动，累积到自动下落/倒计时所需的时长。
  double _dropAccumulator = 0;
  double _secondAccumulator = 0;
  bool _running = false;

  GameProvider(this._prefs)
      : _state = GameState.initial(
          highScore: _prefs.getInt(AppConstants.prefKeyHighScore) ?? 0,
        );

  GameState get state => _state;
  GameMode get selectedMode => _selectedMode;

  /// 是否已开局（开局后才接受游戏循环推进）。
  bool get isRunning => _running;

  int get dropIntervalMs => max(100, 800 - (_state.level - 1) * 70);

  void selectMode(GameMode mode) {
    _selectedMode = mode;
    _state = GameState.initial(
      highScore: _prefs.getInt(AppConstants.prefKeyHighScore) ?? 0,
      mode: mode,
    );
    _running = false;
    _dropAccumulator = 0;
    _secondAccumulator = 0;
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
    _running = true;
    _dropAccumulator = 0;
    _secondAccumulator = 0;
    _sound.startMusicIfEnabled();
    LogService.info('游戏开始, 模式: ${_state.gameMode.label}');
    notifyListeners();
  }

  /// 由 Flame 的 [FlameGame.update] 每帧调用，替代原来的两个 Timer。
  void tick(double dt) {
    if (!_running || _state.isPaused || _state.isGameOver) {
      return;
    }

    _dropAccumulator += dt;
    var guard = 0;
    while (_running && !_state.isPaused && !_state.isGameOver) {
      final step = dropIntervalMs / 1000.0;
      if (_dropAccumulator < step) {
        break;
      }
      _dropAccumulator -= step;
      final prev = _state;
      _state = _state.moveDown();
      _checkSoundEffects(prev);
      _checkGameOver();
      notifyListeners();
      if (++guard >= 4) {
        // 卡顿后不要一次补太多步，避免瞬间结束对局
        _dropAccumulator = 0;
        break;
      }
    }

    if (_state.gameMode != GameMode.timed ||
        !_running ||
        _state.isPaused ||
        _state.isGameOver) {
      return;
    }

    _secondAccumulator += dt;
    while (_secondAccumulator >= 1 && _running && !_state.isGameOver) {
      _secondAccumulator -= 1;
      _state = _state.tickSecond();
      if (_state.isGameOver) {
        _checkGameOver();
      }
      notifyListeners();
    }
  }

  void _checkGameOver() {
    if (_state.isGameOver) {
      _running = false;
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
    if (_state.isGameOver) return;
    _state = _state.togglePause();
    _dropAccumulator = 0;
    _secondAccumulator = 0;
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
    _running = false;
    super.dispose();
  }
}
