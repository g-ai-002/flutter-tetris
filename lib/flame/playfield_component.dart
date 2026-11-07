import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/tetromino.dart';
import '../game/tetris_controller.dart';
import '../theme/block_painting.dart';
import '../theme/block_palette.dart';
import 'board_effects.dart';

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
      other.palette.skin == palette.skin &&
      other.showGhost == showGhost &&
      other.showGrid == showGrid;

  @override
  int get hashCode =>
      Object.hash(palette.dark, palette.skin, showGhost, showGrid);
}

/// Flame 渲染的游戏场地：网格、落定方块、幽灵块、消行动画与粒子特效。
class PlayfieldComponent extends PositionComponent {
  PlayfieldComponent({required this.controller, required this.style})
    : effects = BoardEffects(),
      _seenClear = controller.clearSequence,
      _seenLock = controller.lockSequence,
      _seenDrop = controller.hardDropSequence;

  final TetrisController controller;
  final ValueNotifier<PlayfieldStyle> style;
  final BoardEffects effects;

  int _seenClear;
  int _seenLock;
  int _seenDrop;
  double _time = 0;

  ui.Picture? _staticLayer;
  (double, double, BlockSkin, bool, bool, int)? _staticKey;

  @visibleForTesting
  int debugStaticLayerBuilds = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _syncEffects();
    effects.update(dt);
  }

  void _syncEffects() {
    final board = controller.board;
    final palette = style.value.palette;
    if (controller.clearSequence != _seenClear) {
      _seenClear = controller.clearSequence;
      effects.spawnClearBurst(
        board: board,
        rows: controller.lastClearRows,
        palette: palette,
        cellSize: _cellSize,
      );
    }
    if (controller.lockSequence != _seenLock) {
      _seenLock = controller.lockSequence;
      final type = controller.lastLockedType;
      if (type != null) {
        effects.spawnLockDust(
          blocks: controller.lastLockedBlocks,
          type: type,
          palette: palette,
          cellSize: _cellSize,
          hiddenRows: board.hiddenRows,
        );
      }
    }
    if (controller.hardDropSequence != _seenDrop) {
      _seenDrop = controller.hardDropSequence;
      effects.spawnDropTrail(
        board: board,
        column: controller.hardDropColumn,
        rows: controller.hardDropRows,
        blocks: controller.lastLockedBlocks,
        cellSize: _cellSize,
      );
    }
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
    final shake = effects.shake;
    if (shake > 0.2) {
      canvas.translate(
        math.sin(_time * 70) * shake * 0.5,
        math.cos(_time * 55) * shake * 0.25,
      );
    }

    _ensureStaticLayer(currentStyle);
    canvas.drawPicture(_staticLayer!);
    _paintGhostAndActive(canvas, palette, currentStyle);
    effects.paintTrails(
      canvas,
      hiddenRows: controller.board.hiddenRows,
      cellSize: _cellSize,
    );
    _paintClearFlash(canvas, palette);
    effects.paintParticles(canvas);
    canvas.restore();
  }

  /// 背景、网格、危险区与落定方块只在棋盘或外观变化时重绘，
  /// 其余帧复用同一张静态图层，避免每帧为两百格重建渐变。
  void _ensureStaticLayer(PlayfieldStyle currentStyle) {
    final palette = currentStyle.palette;
    final key = (
      size.x,
      size.y,
      palette.skin,
      palette.dark,
      currentStyle.showGrid,
      controller.boardRevision,
    );
    if (key == _staticKey) return;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    paintBoardBackground(canvas, Offset.zero & size.toSize(), palette);
    if (currentStyle.showGrid) _paintGrid(canvas, palette);
    _paintDangerZone(canvas, palette);
    _paintLocked(canvas, palette);
    _staticLayer?.dispose();
    _staticLayer = recorder.endRecording();
    _staticKey = key;
    debugStaticLayerBuilds++;
  }

  @override
  void onRemove() {
    _staticLayer?.dispose();
    super.onRemove();
  }

  double get _cellSize => size.x / controller.board.columns;

  Rect _cellRect(int x, int y, {double inset = 0}) {
    final cell = _cellSize;
    return Rect.fromLTWH(
      x * cell + inset,
      (y - controller.board.hiddenRows) * cell + inset,
      cell - inset * 2,
      cell - inset * 2,
    );
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
}
