import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_state.dart';
import '../models/tetromino.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'tetris_board_component.dart';
import 'tetris_effects_component.dart';
import 'tetris_world.dart';

/// 基于 Flame 的俄罗斯方块。
///
/// 方块下落、键盘/手势输入与暂停/结束浮层都由 Flame 承担；规则仍由
/// [GameProvider] 持有。
class TetrisGame extends FlameGame<TetrisWorld> with KeyboardEvents {
  TetrisGame({
    required this.provider,
    required this.surfaceColor,
    required this.gridColor,
    required this.gesturesEnabled,
  }) : super(
          world: TetrisWorld(),
          camera: CameraComponent.withFixedResolution(
            width: AppConstants.boardWidth * TetrisBoardComponent.cellSize,
            height: AppConstants.boardHeight * TetrisBoardComponent.cellSize,
          ),
        );

  static const String pauseOverlayId = 'tetrisPause';
  static const String gameOverOverlayId = 'tetrisGameOver';

  final GameProvider provider;
  final Color surfaceColor;
  final Color gridColor;
  final bool gesturesEnabled;

  final math.Random _random = math.Random();
  final Set<String> _activeOverlays = {};

  late final TetrisEffectsComponent _effects;
  late final Vector2 _cameraBase;

  double _shakeRemaining = 0;
  double _shakeDuration = 0;
  double _shakeStrength = 0;

  @override
  Color backgroundColor() => surfaceColor;

  @override
  Future<void> onLoad() async {
    _cameraBase = Vector2(
      AppConstants.boardWidth * TetrisBoardComponent.cellSize / 2,
      AppConstants.boardHeight * TetrisBoardComponent.cellSize / 2,
    );
    _effects = TetrisEffectsComponent(priority: 5);
    await world.addAll([
      TetrisBoardComponent(
        provider: provider,
        gridColor: gridColor,
        gesturesEnabled: gesturesEnabled,
        priority: 0,
      ),
      _effects,
    ]);
    camera.viewfinder.position = _cameraBase;
    camera.viewfinder.zoom = 1;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final state = provider.state;

    if (key == LogicalKeyboardKey.keyP) {
      provider.togglePause();
      return KeyEventResult.handled;
    }
    if (state.isGameOver) {
      if (key == LogicalKeyboardKey.keyR) {
        provider.start();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (state.isPaused) {
      return KeyEventResult.ignored;
    }

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        provider.moveLeft();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        provider.moveRight();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        provider.moveDown();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        provider.rotate();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        provider.hardDrop();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  void update(double dt) {
    final before = _Snapshot.of(provider.state);
    provider.tick(dt);
    final state = provider.state;

    if (!before.gameOver && state.isGameOver) {
      _effects.gameOver();
      _shake(0.4, 5);
    } else if (state.linesCleared > before.lines) {
      _effects.lineClear(state.linesCleared - before.lines);
      _shake(0.26, 4);
    } else if (!before.gameOver &&
        before.piece != null &&
        state.currentPiece != before.piece &&
        state.currentPiece.type != before.piece!.type) {
      _effects.landing(before.piece!, before.x, before.y);
    }

    _syncOverlays();
    _updateCamera(dt);
    super.update(dt);
  }

  void _syncOverlays() {
    final state = provider.state;
    _sync(pauseOverlayId, state.isPaused && !state.isGameOver, 100);
    _sync(gameOverOverlayId, state.isGameOver, 90);
  }

  void _sync(String id, bool visible, int priority) {
    if (visible && !_activeOverlays.contains(id)) {
      overlays.add(id, priority: priority);
      _activeOverlays.add(id);
    } else if (!visible && _activeOverlays.contains(id)) {
      overlays.remove(id);
      _activeOverlays.remove(id);
    }
  }

  void _shake(double duration, double strength) {
    _shakeRemaining = duration;
    _shakeDuration = duration;
    _shakeStrength = strength;
  }

  void _updateCamera(double dt) {
    if (_shakeRemaining <= 0) {
      camera.viewfinder.position = _cameraBase;
      return;
    }
    _shakeRemaining = math.max(0.0, _shakeRemaining - dt);
    final t = _shakeRemaining / _shakeDuration;
    final strength = _shakeStrength * t;
    camera.viewfinder.position = Vector2(
      _cameraBase.x + (_random.nextDouble() * 2 - 1) * strength,
      _cameraBase.y + (_random.nextDouble() * 2 - 1) * strength,
    );
  }
}

/// 单帧状态快照：用于在 provider 推进前后识别消行/落块/结束事件。
class _Snapshot {
  _Snapshot({
    required this.lines,
    required this.piece,
    required this.x,
    required this.y,
    required this.gameOver,
  });

  factory _Snapshot.of(GameState state) {
    final piece = state.currentPiece;
    final shapeRef = state.isGameOver ? null : piece;
    return _Snapshot(
      lines: state.linesCleared,
      piece: shapeRef,
      x: state.currentX,
      y: state.currentY,
      gameOver: state.isGameOver,
    );
  }

  final int lines;
  final Tetromino? piece;
  final int x;
  final int y;
  final bool gameOver;
}
