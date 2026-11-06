import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';

import '../game/board.dart';
import '../game/tetromino.dart';
import '../theme/block_palette.dart';

/// 场地特效：消行碎屑、落定微尘与硬降拖影的生成、推进与绘制。
///
/// 只保存特效自身的状态，场地几何由调用方按帧传入，
/// 便于在测试中独立驱动而不依赖 Flame 组件的尺寸。
class BoardEffects {
  BoardEffects({math.Random? random})
    : _random = random ?? math.Random(20261104);

  static const int maxParticles = 260;

  final math.Random _random;
  final List<_Particle> _particles = [];
  final List<_Trail> _trails = [];

  double _shake = 0;

  /// 当前震屏幅度，0 表示不震动。
  double get shake => _shake;

  int get particleCount => _particles.length;
  int get trailCount => _trails.length;

  /// 消行碎屑：四行消除时每格翻倍并加强震屏。
  void spawnClearBurst({
    required Board board,
    required List<int> rows,
    required BlockPalette palette,
    required double cellSize,
  }) {
    for (final row in rows) {
      for (var x = 0; x < board.columns; x++) {
        final type = board.at(x, row);
        if (type == null) continue;
        final center = _cellCenter(x, row, board.hiddenRows, cellSize);
        final color = board.isGarbage(x, row)
            ? palette.garbageBlock
            : palette.colorOf(type);
        final count = rows.length >= 4 ? 2 : 1;
        for (var i = 0; i < count; i++) {
          _particles.add(
            _Particle(
              position: Vector2(center.dx, center.dy),
              velocity: Vector2(
                (_random.nextDouble() - 0.5) * 200,
                -70 - _random.nextDouble() * 190,
              ),
              color: color,
              life: 0.45 + _random.nextDouble() * 0.4,
              maxLife: 0.85,
              size: cellSize * (0.18 + _random.nextDouble() * 0.22),
              spin: (_random.nextDouble() - 0.5) * 12,
            ),
          );
        }
      }
    }
    if (_particles.length > maxParticles) {
      _particles.removeRange(0, _particles.length - maxParticles);
    }
    _shake = rows.length >= 4 ? 7 : 3.5;
  }

  /// 方块落定时的细碎微尘。
  void spawnLockDust({
    required List<Block> blocks,
    required TetrominoType type,
    required BlockPalette palette,
    required double cellSize,
    required int hiddenRows,
  }) {
    if (blocks.isEmpty) return;
    final color = palette.colorOf(type);
    for (final block in blocks) {
      if (_random.nextDouble() > 0.55) continue;
      final center = _cellCenter(block.x, block.y, hiddenRows, cellSize);
      _particles.add(
        _Particle(
          position: Vector2(center.dx, center.dy + cellSize * 0.4),
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 70,
            -25 - _random.nextDouble() * 45,
          ),
          color: color,
          life: 0.2 + _random.nextDouble() * 0.15,
          maxLife: 0.35,
          size: cellSize * 0.10,
          spin: 0,
        ),
      );
    }
  }

  /// 硬降拖影：从落点向上延伸，随时间淡出。
  void spawnDropTrail({
    required Board board,
    required int column,
    required int rows,
    required List<Block> blocks,
    required double cellSize,
  }) {
    if (rows <= 0) return;
    var bottom = board.rows - 1;
    if (blocks.isNotEmpty) {
      bottom = blocks.map((block) => block.y).reduce(math.max);
    }
    final top = math.max(board.hiddenRows, bottom - rows);
    _trails.add(
      _Trail(
        x: column + 1.5,
        fromY: top,
        toY: bottom,
        life: 0.18,
        maxLife: 0.18,
        width: cellSize * 0.35,
      ),
    );
  }

  void update(double dt) {
    for (final particle in _particles) {
      particle
        ..velocity.y += 620 * dt
        ..position += particle.velocity * dt
        ..life -= dt
        ..rotation += particle.spin * dt;
    }
    _particles.removeWhere((particle) => particle.life <= 0);

    for (final trail in _trails) {
      trail.life -= dt;
    }
    _trails.removeWhere((trail) => trail.life <= 0);
    if (_shake > 0) _shake = math.max(0, _shake - dt * 26);
  }

  void paintTrails(
    Canvas canvas, {
    required int hiddenRows,
    required double cellSize,
  }) {
    for (final trail in _trails) {
      final alpha = (trail.life / trail.maxLife).clamp(0.0, 1.0);
      final top = (trail.fromY - hiddenRows) * cellSize;
      final bottom = (trail.toY - hiddenRows + 1) * cellSize;
      final rect = Rect.fromLTWH(
        trail.x * cellSize - trail.width / 2,
        top,
        trail.width,
        math.max(0, bottom - top),
      );
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.30 * alpha),
            ],
          ).createShader(rect),
      );
    }
  }

  void paintParticles(Canvas canvas) {
    for (final particle in _particles) {
      final alpha = (particle.life / particle.maxLife).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(particle.position.x, particle.position.y);
      canvas.rotate(particle.rotation);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(particle.size * 0.22)),
        Paint()..color = particle.color.withValues(alpha: alpha),
      );
      canvas.restore();
    }
  }

  Offset _cellCenter(int x, int y, int hiddenRows, double cellSize) =>
      Offset((x + 0.5) * cellSize, (y - hiddenRows + 0.5) * cellSize);
}

class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.spin,
  });

  Vector2 position;
  Vector2 velocity;
  final Color color;
  double life;
  final double maxLife;
  final double size;
  final double spin;
  double rotation = 0;
}

class _Trail {
  _Trail({
    required this.x,
    required this.fromY,
    required this.toY,
    required this.life,
    required this.maxLife,
    required this.width,
  });

  /// 以格为单位的列号（可为小数，用于居中）。
  final double x;
  final int fromY;
  final int toY;
  double life;
  final double maxLife;
  final double width;
}
