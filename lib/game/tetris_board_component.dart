import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'tetris_input.dart';

/// 棋盘渲染组件：网格、已锁定方块、幽灵块与当前方块，并处理点击/滑动手势。
class TetrisBoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  TetrisBoardComponent({
    required this.provider,
    required this.gridColor,
    required this.gesturesEnabled,
    int? priority,
  }) : super(
          priority: priority,
          size: Vector2(
            AppConstants.boardWidth * cellSize,
            AppConstants.boardHeight * cellSize,
          ),
        );

  /// 世界坐标下的单格边长。
  static const double cellSize = 30;

  final GameProvider provider;
  final Color gridColor;
  final bool gesturesEnabled;

  Vector2 _dragDelta = Vector2.zero();

  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  final Paint _grid = Paint();
  final Paint _highlight = Paint()
    ..color = Colors.white.withValues(alpha: 0.25);

  @override
  void onTapUp(TapUpEvent event) {
    if (!gesturesEnabled) {
      return;
    }
    final state = provider.state;
    if (state.isGameOver) {
      provider.start();
    } else if (!state.isPaused) {
      provider.rotate();
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _dragDelta = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _dragDelta += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final delta = _dragDelta;
    _dragDelta = Vector2.zero();
    if (!gesturesEnabled || delta.length < TetrisInput.swipeThreshold) {
      return;
    }

    final state = provider.state;
    if (state.isGameOver || state.isPaused) {
      return;
    }
    final direction =
        TetrisInput.directionFromDelta(Offset(delta.x, delta.y));
    switch (direction) {
      case SwipeDirection.up:
        provider.rotate();
      case SwipeDirection.down:
        provider.hardDrop();
      case SwipeDirection.left:
        provider.moveLeft();
      case SwipeDirection.right:
        provider.moveRight();
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragDelta = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    final state = provider.state;
    final width = state.width * cellSize;
    final height = state.height * cellSize;

    _grid
      ..color = gridColor
      ..strokeWidth = 0.6;
    for (var row = 0; row <= state.height; row++) {
      canvas.drawLine(
        Offset(0, row * cellSize),
        Offset(width, row * cellSize),
        _grid,
      );
    }
    for (var col = 0; col <= state.width; col++) {
      canvas.drawLine(
        Offset(col * cellSize, 0),
        Offset(col * cellSize, height),
        _grid,
      );
    }

    for (var row = 0; row < state.height; row++) {
      for (var col = 0; col < state.width; col++) {
        final color = state.board[row][col];
        if (color != 0) {
          _drawCell(canvas, col, row, Color(color));
        }
      }
    }

    _drawGhost(canvas, state);
    _drawCurrentPiece(canvas, state);
  }

  void _drawGhost(Canvas canvas, GameState state) {
    final ghostY = state.ghostY;
    if (ghostY == state.currentY) {
      return;
    }
    final color = Color(state.currentPiece.color);
    final shape = state.currentPiece.shape;
    for (var row = 0; row < shape.length; row++) {
      for (var col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) {
          continue;
        }
        final rect = _cellRect(state.currentX + col, ghostY + row);
        canvas.drawRRect(
          rect,
          Paint()..color = color.withValues(alpha: 0.16),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  void _drawCurrentPiece(Canvas canvas, GameState state) {
    final shape = state.currentPiece.shape;
    final color = Color(state.currentPiece.color);
    for (var row = 0; row < shape.length; row++) {
      for (var col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 0) {
          continue;
        }
        final boardRow = state.currentY + row;
        if (boardRow < 0) {
          continue;
        }
        _drawCell(canvas, state.currentX + col, boardRow, color);
      }
    }
  }

  void _drawCell(Canvas canvas, int col, int row, Color color) {
    final rect = _cellRect(col, row);
    _fill.color = color;
    canvas.drawRRect(rect, _fill);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          col * cellSize + 1,
          row * cellSize + 1,
          cellSize - 2,
          (cellSize - 2) / 2,
        ),
        const Radius.circular(3),
      ),
      _highlight,
    );

    _stroke
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    canvas.drawRRect(rect.deflate(0.5), _stroke);
  }

  RRect _cellRect(int col, int row) => RRect.fromRectAndRadius(
        Rect.fromLTWH(
          col * cellSize + 1,
          row * cellSize + 1,
          cellSize - 2,
          cellSize - 2,
        ),
        const Radius.circular(3),
      );
}
