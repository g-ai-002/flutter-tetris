import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../models/tetromino.dart';
import '../utils/constants.dart';
import 'tetris_board_component.dart';

/// 棋盘特效层：消行闪光、落块碎屑、结束时红色渐隐。
class TetrisEffectsComponent extends PositionComponent {
  TetrisEffectsComponent({int? priority})
      : super(
          priority: priority,
          size: Vector2(
            AppConstants.boardWidth * TetrisBoardComponent.cellSize,
            AppConstants.boardHeight * TetrisBoardComponent.cellSize,
          ),
        );

  static const double _flashDuration = 0.42;
  static const double _gameOverDuration = 0.9;

  final List<_RowFlash> _flashes = [];
  final List<_Spark> _sparks = [];
  final math.Random _random = math.Random();

  final Paint _paint = Paint();
  double _gameOver = 0;

  double get _cellSize => TetrisBoardComponent.cellSize;

  /// 消行时的白色横闪与火星。
  void lineClear(int clearedRows) {
    final height = AppConstants.boardHeight;
    for (var i = 0; i < clearedRows; i++) {
      final row = height - 1 - i;
      _flashes.add(_RowFlash(row, _flashDuration));
      for (var c = 0; c < AppConstants.boardWidth; c += 2) {
        _spawn(
          c * _cellSize + _cellSize / 2,
          row * _cellSize + _cellSize / 2,
          const Color(0xFFFFF59D),
        );
      }
    }
  }

  /// 方块锁定时的少量碎屑。
  void landing(Tetromino piece, int x, int y) {
    for (var row = 0; row < piece.shape.length; row++) {
      for (var col = 0; col < piece.shape[row].length; col++) {
        if (piece.shape[row][col] == 0) {
          continue;
        }
        final boardRow = y + row;
        if (boardRow < 0) {
          continue;
        }
        _spawn(
          (x + col) * _cellSize + _cellSize / 2,
          boardRow * _cellSize + _cellSize,
          Color(piece.color),
        );
      }
    }
  }

  void gameOver() {
    _gameOver = _gameOverDuration;
  }

  void _spawn(double x, double y, Color color) {
    _sparks.add(
      _Spark(
        position: Vector2(x, y),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 60,
          -40 - _random.nextDouble() * 90,
        ),
        color: color,
        life: 0.28 + _random.nextDouble() * 0.22,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final flash in _flashes) {
      flash.life -= dt;
    }
    _flashes.removeWhere((flash) => flash.life <= 0);

    for (final spark in _sparks) {
      spark.life -= dt;
      spark.position.add(spark.velocity * dt);
      spark.velocity.y += 260 * dt;
    }
    _sparks.removeWhere((spark) => spark.life <= 0);

    if (_gameOver > 0) {
      _gameOver = math.max(0.0, _gameOver - dt);
    }
  }

  @override
  void render(Canvas canvas) {
    for (final flash in _flashes) {
      final t = (flash.life / _flashDuration).clamp(0.0, 1.0).toDouble();
      _paint.color = Colors.white.withValues(alpha: 0.55 * t);
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          flash.row * _cellSize,
          AppConstants.boardWidth * _cellSize,
          _cellSize,
        ),
        _paint,
      );
    }

    for (final spark in _sparks) {
      final t = (spark.life / spark.maxLife).clamp(0.0, 1.0).toDouble();
      _paint.color = spark.color.withValues(alpha: 0.85 * t);
      canvas.drawCircle(
        Offset(spark.position.x, spark.position.y),
        2.2 * (0.5 + t),
        _paint,
      );
    }

    if (_gameOver > 0) {
      final t = _gameOver / _gameOverDuration;
      _paint.color = const Color(0xFFE53935).withValues(alpha: 0.32 * t);
      canvas.drawRect(
        Rect.fromLTWH(
          0,
          0,
          AppConstants.boardWidth * _cellSize,
          AppConstants.boardHeight * _cellSize,
        ),
        _paint,
      );
    }
  }
}

class _RowFlash {
  _RowFlash(this.row, this.life);

  final int row;
  double life;
}

class _Spark {
  _Spark({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
  }) : maxLife = life;

  final Vector2 position;
  final Vector2 velocity;
  final Color color;
  final double maxLife;
  double life;
}
