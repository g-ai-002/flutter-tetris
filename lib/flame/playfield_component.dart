import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/tetromino.dart';
import '../game/tetris_controller.dart';
import '../theme/block_painting.dart';
import '../theme/block_palette.dart';

/// 棋盘外观：调色板与网格/幽灵块开关，随主题变化实时更新。
class PlayfieldStyle {
  const PlayfieldStyle({
    required this.palette,
    this.showGhost = true,
    this.showGrid = true,
  });

  final BlockPalette palette;
  final bool showGhost;
  final bool showGrid;

  @override
  bool operator ==(Object other) =>
      other is PlayfieldStyle &&
      other.palette.dark == palette.dark &&
      other.showGhost == showGhost &&
      other.showGrid == showGrid;

  @override
  int get hashCode => Object.hash(palette.dark, showGhost, showGrid);
}

/// Flame 渲染的游戏场地：网格、落定方块、幽灵块、消行动画与粒子特效。
class PlayfieldComponent extends PositionComponent {
  PlayfieldComponent({required this.controller, required this.style})
    : _seenClear = controller.clearSequence,
      _seenLock = controller.lockSequence,
      _seenDrop = controller.hardDropSequence;

  final TetrisController controller;
  final ValueNotifier<PlayfieldStyle> style;

  final List<_Particle> _particles = [];
  final List<_Trail> _trails = [];
  final math.Random _random = math.Random(20261104);

  int _seenClear;
  int _seenLock;
  int _seenDrop;
  double _time = 0;
  double _shake = 0;

  static const int _maxParticles = 260;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _syncEffects();

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

  void _syncEffects() {
    if (controller.clearSequence != _seenClear) {
      _seenClear = controller.clearSequence;
      _spawnClearBurst(controller.lastClearRows);
      _shake = controller.lastClearRows.length >= 4 ? 7 : 3.5;
    }
    if (controller.lockSequence != _seenLock) {
      _seenLock = controller.lockSequence;
      _spawnLockDust();
    }
    if (controller.hardDropSequence != _seenDrop) {
      _seenDrop = controller.hardDropSequence;
      _spawnDropTrail();
    }
  }

  void _spawnClearBurst(List<int> rows) {
    final board = controller.board;
    final palette = style.value.palette;
    for (final row in rows) {
      for (var x = 0; x < board.columns; x++) {
        final type = board.at(x, row);
        if (type == null) continue;
        final center = _cellCenter(x, row);
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
              size: _cellSize * (0.18 + _random.nextDouble() * 0.22),
              spin: (_random.nextDouble() - 0.5) * 12,
            ),
          );
        }
      }
    }
    if (_particles.length > _maxParticles) {
      _particles.removeRange(0, _particles.length - _maxParticles);
    }
  }

  void _spawnLockDust() {
    final blocks = controller.lastLockedBlocks;
    final type = controller.lastLockedType;
    if (blocks.isEmpty || type == null) return;
    final color = style.value.palette.colorOf(type);
    for (final block in blocks) {
      if (_random.nextDouble() > 0.55) continue;
      final center = _cellCenter(block.x, block.y);
      _particles.add(
        _Particle(
          position: Vector2(center.dx, center.dy + _cellSize * 0.4),
          velocity: Vector2(
            (_random.nextDouble() - 0.5) * 70,
            -25 - _random.nextDouble() * 45,
          ),
          color: color,
          life: 0.2 + _random.nextDouble() * 0.15,
          maxLife: 0.35,
          size: _cellSize * 0.10,
          spin: 0,
        ),
      );
    }
  }

  void _spawnDropTrail() {
    final board = controller.board;
    final column = controller.hardDropColumn;
    final rows = controller.hardDropRows;
    if (rows <= 0) return;
    final piece = controller.lastLockedBlocks;
    var bottom = board.rows - 1;
    if (piece.isNotEmpty) {
      bottom = piece.map((block) => block.y).reduce(math.max);
    }
    final top = math.max(board.hiddenRows, bottom - rows);
    _trails.add(
      _Trail(
        x: column + 1.5,
        fromY: top,
        toY: bottom,
        life: 0.18,
        maxLife: 0.18,
        width: _cellSize * 0.35,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final currentStyle = style.value;
    final palette = currentStyle.palette;
    final boardRect = Offset.zero & size.toSize();
    final radius = Radius.circular(size.x * 0.035);
    final well = RRect.fromRectAndRadius(boardRect, radius);

    canvas.save();
    canvas.clipRRect(well);
    if (_shake > 0.2) {
      canvas.translate(
        math.sin(_time * 70) * _shake * 0.5,
        math.cos(_time * 55) * _shake * 0.25,
      );
    }

    _paintBackground(canvas, boardRect, palette);
    if (currentStyle.showGrid) _paintGrid(canvas, palette);
    _paintDangerZone(canvas, palette);
    _paintLocked(canvas, palette);
    _paintGhostAndActive(canvas, palette, currentStyle);

    for (final trail in _trails) {
      _paintTrail(canvas, trail);
    }
    _paintClearFlash(canvas, palette);
    _paintParticles(canvas);
    canvas.restore();
  }

  /// 供点击/拖拽换算列号。
  int columnAt(double localX) {
    if (_cellSize <= 0) return 0;
    return (localX / _cellSize).floor().clamp(0, controller.board.columns - 1);
  }

  double get _cellSize => size.x / controller.board.columns;

  Offset _cellCenter(int x, int y) => Offset(
    (x + 0.5) * _cellSize,
    (y - controller.board.hiddenRows + 0.5) * _cellSize,
  );

  Rect _cellRect(int x, int y, {double inset = 0}) {
    final cell = _cellSize;
    return Rect.fromLTWH(
      x * cell + inset,
      (y - controller.board.hiddenRows) * cell + inset,
      cell - inset * 2,
      cell - inset * 2,
    );
  }

  void _paintBackground(Canvas canvas, Rect rect, BlockPalette palette) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: palette.dark
          ? const [Color(0xFF23201A), Color(0xFF15120E)]
          : const [Color(0xFFFDFAF2), Color(0xFFF7EEDC)],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  void _paintGrid(Canvas canvas, BlockPalette palette) {
    final cell = _cellSize;
    final paint = Paint()
      ..color = palette.gridLine
      ..strokeWidth = 0.8;
    for (var x = 1; x < controller.board.columns; x++) {
      canvas.drawLine(Offset(x * cell, 0), Offset(x * cell, size.y), paint);
    }
    for (var y = 1; y < size.y / cell; y++) {
      canvas.drawLine(Offset(0, y * cell), Offset(size.x, y * cell), paint);
    }
  }

  void _paintDangerZone(Canvas canvas, BlockPalette palette) {
    if (controller.stackHeight < 17) return;
    final height = _cellSize * 2.4;
    final rect = Rect.fromLTWH(0, 0, size.x, height);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.dangerTint.withValues(alpha: 0.20),
            palette.dangerTint.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );
  }

  void _paintLocked(Canvas canvas, BlockPalette palette) {
    final board = controller.board;
    for (var y = board.hiddenRows; y < board.rows; y++) {
      for (var x = 0; x < board.columns; x++) {
        final type = board.at(x, y);
        if (type == null) continue;
        final color = board.isGarbage(x, y)
            ? palette.garbageBlock
            : palette.colorOf(type);
        paintBlock(canvas, _cellRect(x, y), color);
      }
    }
  }

  void _paintGhostAndActive(
    Canvas canvas,
    BlockPalette palette,
    PlayfieldStyle currentStyle,
  ) {
    final piece = controller.piece;
    if (piece == null) return;
    final color = palette.colorOf(piece.type);
    if (currentStyle.showGhost) {
      final ghost = controller.ghostPiece;
      if (ghost != null && ghost.y > piece.y) {
        for (final block in ghost.blocks) {
          if (block.y < controller.board.hiddenRows) continue;
          paintGhostBlock(canvas, _cellRect(block.x, block.y), color);
        }
      }
    }
    for (final block in piece.blocks) {
      if (block.y < controller.board.hiddenRows) continue;
      paintBlock(canvas, _cellRect(block.x, block.y), color, active: true);
    }
  }

  void _paintClearFlash(Canvas canvas, BlockPalette palette) {
    if (controller.clearingRows.isEmpty) return;
    final progress = controller.clearProgress;
    final flash = math.sin(progress * math.pi);
    if (flash <= 0) return;
    for (final row in controller.clearingRows) {
      final rect = Rect.fromLTWH(
        0,
        (row - controller.board.hiddenRows) * _cellSize,
        size.x,
        _cellSize,
      );
      canvas.drawRect(
        rect,
        Paint()..color = Colors.white.withValues(alpha: 0.55 * flash),
      );
      final lineHeight = math.max(1.2, _cellSize * 0.06);
      canvas.drawRect(
        Rect.fromLTWH(0, rect.center.dy - lineHeight / 2, size.x, lineHeight),
        Paint()
          ..color = palette
              .colorOf(TetrominoType.o)
              .withValues(alpha: 0.85 * flash),
      );
    }
  }

  void _paintTrail(Canvas canvas, _Trail trail) {
    final alpha = (trail.life / trail.maxLife).clamp(0.0, 1.0);
    final top = (trail.fromY - controller.board.hiddenRows) * _cellSize;
    final bottom = (trail.toY - controller.board.hiddenRows + 1) * _cellSize;
    final rect = Rect.fromLTWH(
      trail.x * _cellSize - trail.width / 2,
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

  void _paintParticles(Canvas canvas) {
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
