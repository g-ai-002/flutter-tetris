import 'dart:async';

import 'package:gamepads/gamepads.dart';

import '../services/log_service.dart';
import 'key_bindings.dart';

/// 手柄按钮到游戏操作的固定映射，摇杆与十字键由 [GamepadService] 处理。
GameAction? gamepadActionForButton(GamepadButton button) {
  return switch (button) {
    GamepadButton.a => GameAction.rotateClockwise,
    GamepadButton.b => GameAction.rotateCounterClockwise,
    GamepadButton.x || GamepadButton.leftBumper => GameAction.hold,
    GamepadButton.y ||
    GamepadButton.rightBumper ||
    GamepadButton.dpadUp => GameAction.hardDrop,
    GamepadButton.dpadLeft => GameAction.moveLeft,
    GamepadButton.dpadRight => GameAction.moveRight,
    GamepadButton.dpadDown => GameAction.softDrop,
    GamepadButton.start => GameAction.pause,
    _ => null,
  };
}

/// 把标准布局手柄的按钮与左摇杆转成与键盘一致的操作流。
///
/// 十字键与左摇杆支持长按连发；面板按钮只在按下时触发一次。
/// 未连接手柄或平台不支持时静默降级，不影响键盘与触屏操作。
class GamepadService {
  GamepadService({
    required this.onAction,
    Stream<NormalizedGamepadEvent>? events,
    Stream<GamepadConnectionEvent>? connections,
    this.axisThreshold = 0.55,
    this.moveRepeat = const Duration(milliseconds: 110),
    this.softDropRepeat = const Duration(milliseconds: 55),
  }) : _eventStream = events,
       _connectionStream = connections;

  final void Function(GameAction action) onAction;
  final double axisThreshold;
  final Duration moveRepeat;
  final Duration softDropRepeat;

  final Stream<NormalizedGamepadEvent>? _eventStream;
  final Stream<GamepadConnectionEvent>? _connectionStream;

  StreamSubscription<NormalizedGamepadEvent>? _events;
  StreamSubscription<GamepadConnectionEvent>? _connections;
  Timer? _buttonTimer;
  GameAction? _buttonAction;
  Timer? _stickTimer;
  GameAction? _stickAction;
  double _stickX = 0;
  double _stickY = 0;
  final Set<GamepadButton> _pressedButtons = {};
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _events = (_eventStream ?? Gamepads.normalizedEvents).listen(
        _handleEvent,
        onError: (Object error, StackTrace stack) {
          LogService.warning('手柄输入不可用: $error');
          unawaited(_dropEvents());
        },
      );
      _connections = (_connectionStream ?? Gamepads.onConnected).listen(
        (event) => LogService.info('手柄已连接: ${event.name}'),
        onError: (Object error) => LogService.warning('手柄连接监听失败: $error'),
      );
    } catch (error) {
      LogService.warning('初始化手柄失败: $error');
    }
  }

  Future<void> stop() async {
    _started = false;
    _stopButtonRepeat();
    _stopStickRepeat();
    _pressedButtons.clear();
    final events = _events;
    final connections = _connections;
    _events = null;
    _connections = null;
    await events?.cancel();
    await connections?.cancel();
  }

  Future<void> _dropEvents() async {
    final events = _events;
    _events = null;
    await events?.cancel();
  }

  void _handleEvent(NormalizedGamepadEvent event) {
    final button = event.button;
    if (button != null) {
      _handleButton(button, event.value);
      return;
    }
    final axis = event.axis;
    if (axis != null) _handleAxis(axis, event.value);
  }

  void _handleButton(GamepadButton button, double value) {
    final action = gamepadActionForButton(button);
    if (action == null) return;
    if (value >= 0.5) {
      if (!_pressedButtons.add(button)) return;
      if (action.repeatable) {
        _startRepeat(action, onStick: false);
      } else {
        onAction(action);
      }
      return;
    }
    _pressedButtons.remove(button);
    if (_buttonAction == action) _stopButtonRepeat();
  }

  void _handleAxis(GamepadAxis axis, double value) {
    if (axis == GamepadAxis.leftStickX) {
      _stickX = value;
    } else if (axis == GamepadAxis.leftStickY) {
      _stickY = value;
    } else {
      return;
    }
    // 斜向推杆时优先保持水平移动，避免两个轴事件交替触发不同动作。
    final action = _stickX >= axisThreshold
        ? GameAction.moveRight
        : _stickX <= -axisThreshold
        ? GameAction.moveLeft
        : _stickY <= -axisThreshold
        ? GameAction.softDrop
        : null;
    _setStickAction(action);
  }

  void _setStickAction(GameAction? action) {
    if (_stickAction == action) return;
    _stopStickRepeat();
    if (action == null) return;
    _startRepeat(action, onStick: true);
  }

  void _startRepeat(GameAction action, {required bool onStick}) {
    if (onStick) {
      _stickAction = action;
      onAction(action);
      _stickTimer = Timer.periodic(
        _intervalFor(action),
        (_) => onAction(action),
      );
      return;
    }
    if (_buttonAction == action) return;
    _stopButtonRepeat();
    _buttonAction = action;
    onAction(action);
    _buttonTimer = Timer.periodic(
      _intervalFor(action),
      (_) => onAction(action),
    );
  }

  Duration _intervalFor(GameAction action) =>
      action == GameAction.softDrop ? softDropRepeat : moveRepeat;

  void _stopButtonRepeat() {
    _buttonTimer?.cancel();
    _buttonTimer = null;
    _buttonAction = null;
  }

  void _stopStickRepeat() {
    _stickTimer?.cancel();
    _stickTimer = null;
    _stickAction = null;
  }
}
