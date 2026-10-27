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
import 'board_camera.dart';
import 'canvas_gesture_layer.dart';
import 'tetris_board_component.dart';
import 'tetris_effects_component.dart';
import 'tetris_input.dart';
import 'tetris_world.dart';

/// 基于 Flame 的俄罗斯方块。
///
/// 方块下落、键盘输入、触摸手势与暂停/结束浮层都由 Flame 承担；画布铺满整个
/// 游戏页，棋盘由相机对齐到 Flutter 侧给出的槽位。规则仍由 [GameProvider] 持有。
class TetrisGame extends FlameGame<TetrisWorld> with KeyboardEvents {
  TetrisGame({
    required this.provider,
    required this.surfaceColor,
    required this.gridColor,
    this.gesturesEnabled = true,
  }) : super(
          world: TetrisWorld(),
          camera: CameraComponent(),
        );

  static const String pauseOverlayId = 'tetrisPause';
  static const String gameOverOverlayId = 'tetrisGameOver';

  static const double _worldWidth =
      AppConstants.boardWidth * TetrisBoardComponent.cellSize;
  static const double _worldHeight =
      AppConstants.boardHeight * TetrisBoardComponent.cellSize;

  final GameProvider provider;
  final Color surfaceColor;
  final Color gridColor;

  /// 仅虚拟按键模式下为 false，此时画布手势不响应。
  bool gesturesEnabled;

  final math.Random _random = math.Random();
  final Set<String> _activeOverlays = {};

  late final TetrisEffectsComponent _effects;
  late final CanvasGestureLayer _gestures;

  /// 主循环是否已因暂停/结算停掉，避免重复调用 [pauseEngine]。
  bool _enginePaused = false;

  /// 组件树是否已加载完成，加载前不碰主循环与 provider 监听。
  bool _ready = false;

  Vector2 _cameraBase = Vector2(_worldWidth / 2, _worldHeight / 2);
  Size _canvasSize = Size.zero;
  Rect _boardRect = Rect.zero;
  double _baseZoom = 1;

  double _shakeRemaining = 0;
  double _shakeDuration = 0;
  double _shakeStrength = 0;

  @override
  Color backgroundColor() => surfaceColor;

  @override
  Future<void> onLoad() async {
    _effects = TetrisEffectsComponent(priority: 5);
    await world.addAll([
      TetrisBoardComponent(
        provider: provider,
        gridColor: gridColor,
        priority: 0,
      ),
      _effects,
    ]);

    _gestures = CanvasGestureLayer(
      onTap: handleTap,
      onSwipe: handleSwipe,
    );
    camera.viewport.add(_gestures);

    _canvasSize = Size(size.x, size.y);
    _applyCamera();
    _ready = true;
    provider.addListener(_handleProviderChange);
  }

  @override
  void onRemove() {
    detachProvider();
    super.onRemove();
  }

  /// 断开对 provider 的监听；GameWidget 销毁时显式调用一次。
  void detachProvider() {
    provider.removeListener(_handleProviderChange);
  }

  /// 暂停后主循环已停，必须靠 provider 通知才能收到「继续」并重启。
  void _handleProviderChange() {
    if (!_ready) return;
    final state = provider.state;
    if (!state.isPaused && !state.isGameOver) {
      _resumeEngine();
    }
  }

  /// 浮层的「继续 / 重新开始」回调里显式恢复主循环（与监听互为兜底）。
  void resumeFromOverlay() {
    _resumeEngine();
  }

  void _resumeEngine() {
    if (!_enginePaused) return;
    _enginePaused = false;
    resumeEngine();
  }

  /// 暂停或结算浮层已显示时停掉主循环，画面完全静止后不再逐帧重绘。
  void _syncEnginePause() {
    final state = provider.state;
    final shouldPause = state.isPaused ||
        (state.isGameOver && _activeOverlays.contains(gameOverOverlayId));
    if (shouldPause && !_enginePaused) {
      _enginePaused = true;
      pauseEngine();
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _canvasSize = Size(size.x, size.y);
    _applyCamera();
  }

  /// Flutter 侧把棋盘槽位的页面矩形同步过来，相机据此把世界棋盘画在槽位里。
  void updateBoardLayout({required Rect boardRect, required Size canvasSize}) {
    if (_boardRect == boardRect && _canvasSize == canvasSize) {
      return;
    }
    _boardRect = boardRect;
    _canvasSize = canvasSize;
    _applyCamera();
  }

  /// 点击画布任意位置：进行中旋转，结束后重新开局。
  void handleTap() {
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

  /// 画布上的滑动：按位移映射到旋转/硬降/左右移动。
  void handleSwipe(Offset delta) {
    if (!gesturesEnabled) {
      return;
    }
    final action = TetrisInput.actionFromDelta(delta);
    if (action == null) {
      return;
    }

    final state = provider.state;
    if (state.isGameOver || state.isPaused) {
      return;
    }
    switch (action) {
      case SwipeAction.rotate:
        provider.rotate();
      case SwipeAction.hardDrop:
        provider.hardDrop();
      case SwipeAction.moveLeft:
        provider.moveLeft();
      case SwipeAction.moveRight:
        provider.moveRight();
    }
  }

  void _applyCamera() {
    if (_boardRect.isEmpty || _canvasSize.isEmpty) {
      return;
    }
    final layout = cameraLayoutForBoard(
      canvasSize: _canvasSize,
      boardRect: _boardRect,
      worldBoardRect: const Rect.fromLTWH(0, 0, _worldWidth, _worldHeight),
    );
    _baseZoom = layout.zoom;
    _cameraBase = layout.position;
    camera.viewfinder.zoom = _baseZoom;
    camera.viewfinder.position = _cameraBase;
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
    _syncEnginePause();
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
