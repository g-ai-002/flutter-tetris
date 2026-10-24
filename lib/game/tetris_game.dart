import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/tetromino.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'tetris_board_component.dart';
import 'tetris_effects_component.dart';
import 'tetris_world.dart';

/// 基于 Flame 的俄罗斯方块。
///
/// 方块下落由 [FlameGame.update] 驱动（替代原来的两个 Timer），棋盘由
/// [TetrisBoardComponent] 绘制，消行/落块/结束的反馈由
/// [TetrisEffectsComponent] 承担；规则仍由 [GameProvider] 持有。
class TetrisGame extends FlameGame<TetrisWorld> {
  TetrisGame({
    required this.provider,
    required this.surfaceColor,
    required this.gridColor,
  }) : super(
          world: TetrisWorld(),
          camera: CameraComponent.withFixedResolution(
            width: AppConstants.boardWidth * TetrisBoardComponent.cellSize,
            height: AppConstants.boardHeight * TetrisBoardComponent.cellSize,
          ),
        );

  final GameProvider provider;
  final Color surfaceColor;
  final Color gridColor;

  final math.Random _random = math.Random();

  late final TetrisEffectsComponent _effects;
  late final Vector2 _cameraBase;

  double _shakeRemaining = 0;
  double _shakeDuration = 0;

  @override
  Color backgroundColor() => surfaceColor;

  @override
  Future<void> onLoad() async {
    _cameraBase = Vector2(size.x / 2, size.y / 2);
    _effects = TetrisEffectsComponent(priority: 5);
    await world.addAll([
      TetrisBoardComponent(
        provider: provider,
        gridColor: gridColor,
        priority: 0,
      ),
      _effects,
    ]);
    camera.viewfinder.position = _cameraBase;
    camera.viewfinder.zoom = 1;
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

    _updateCamera(dt);
    super.update(dt);
  }

  void _shake(double duration, double strength) {
    _shakeRemaining = duration;
    _shakeDuration = duration;
    _shakeStrength = strength;
  }

  double _shakeStrength = 0;

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
