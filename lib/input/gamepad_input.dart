import 'dart:async';

import 'package:gamepads/gamepads.dart';

import '../services/log_service.dart';
import 'action_repeat.dart';
import 'key_bindings.dart';

/// 标准布局手柄的固定按钮映射，摇杆与十字键的连发由 [GamepadService] 处理。
///
/// 界面上的手柄说明也从这张表派生，避免帮助弹窗、设置页与 README 各写一份。
const Map<GamepadButton, GameAction> gamepadButtonActions = {
  GamepadButton.a: GameAction.rotateClockwise,
  GamepadButton.b: GameAction.rotateCounterClockwise,
  GamepadButton.x: GameAction.hold,
  GamepadButton.leftBumper: GameAction.hold,
  GamepadButton.y: GameAction.hardDrop,
  GamepadButton.rightBumper: GameAction.hardDrop,
  GamepadButton.dpadUp: GameAction.hardDrop,
  GamepadButton.dpadLeft: GameAction.moveLeft,
  GamepadButton.dpadRight: GameAction.moveRight,
  GamepadButton.dpadDown: GameAction.softDrop,
  GamepadButton.start: GameAction.pause,
};

/// 手柄说明的展示顺序：移动、软降、旋转、暂存、暂停。
const List<GameAction> gamepadGuideOrder = [
  GameAction.moveLeft,
  GameAction.moveRight,
  GameAction.softDrop,
  GameAction.hardDrop,
  GameAction.rotateClockwise,
  GameAction.rotateCounterClockwise,
  GameAction.hold,
  GameAction.pause,
];

/// 手柄按钮 → 游戏操作，未映射的按钮返回 null。
GameAction? gamepadActionForButton(GamepadButton button) =>
    gamepadButtonActions[button];

/// 映射到 [action] 的全部按钮，按 [gamepadButtonActions] 的声明顺序返回。
List<GamepadButton> gamepadButtonsFor(GameAction action) => [
  for (final entry in gamepadButtonActions.entries)
    if (entry.value == action) entry.key,
];

String formatGamepadButton(GamepadButton button) => switch (button) {
  GamepadButton.a => 'A',
  GamepadButton.b => 'B',
  GamepadButton.x => 'X',
  GamepadButton.y => 'Y',
  GamepadButton.leftBumper => 'LB',
  GamepadButton.rightBumper => 'RB',
  GamepadButton.dpadUp => '↑',
  GamepadButton.dpadDown => '↓',
  GamepadButton.dpadLeft => '←',
  GamepadButton.dpadRight => '→',
  GamepadButton.start => 'Start',
  _ => button.name,
};

/// 手柄按键在界面上的说明；未映射的操作返回 null。
///
/// 移动与软降同时支持左摇杆，因此在这三项后面补上「左摇杆」。
String? gamepadLabelsFor(GameAction action) {
  final buttons = gamepadButtonsFor(action);
  if (buttons.isEmpty) return null;
  final labels = buttons.map(formatGamepadButton).toList();
  if (action == GameAction.moveLeft ||
      action == GameAction.moveRight ||
      action == GameAction.softDrop) {
    labels.add('左摇杆');
  }
  return labels.join(' / ');
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
       _connectionStream = connections {
    _buttonRepeat = ActionRepeat(onRepeat: _fireButton);
    _stickRepeat = ActionRepeat(onRepeat: _fireStick);
  }

  final void Function(GameAction action) onAction;
  final double axisThreshold;
  final Duration moveRepeat;
  final Duration softDropRepeat;

  final Stream<NormalizedGamepadEvent>? _eventStream;
  final Stream<GamepadConnectionEvent>? _connectionStream;

  StreamSubscription<NormalizedGamepadEvent>? _events;
  StreamSubscription<GamepadConnectionEvent>? _connections;
  late final ActionRepeat _buttonRepeat;
  late final ActionRepeat _stickRepeat;
  GameAction? _buttonAction;
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
    final interval = _intervalFor(action);
    if (onStick) {
      _stickAction = action;
      _stickRepeat.start(interval: interval);
      return;
    }
    if (_buttonAction == action) return;
    _stopButtonRepeat();
    _buttonAction = action;
    _buttonRepeat.start(interval: interval);
  }

  void _fireButton() {
    final action = _buttonAction;
    if (action != null) onAction(action);
  }

  void _fireStick() {
    final action = _stickAction;
    if (action != null) onAction(action);
  }

  Duration _intervalFor(GameAction action) =>
      action == GameAction.softDrop ? softDropRepeat : moveRepeat;

  void _stopButtonRepeat() {
    _buttonRepeat.stop();
    _buttonAction = null;
  }

  void _stopStickRepeat() {
    _stickRepeat.stop();
    _stickAction = null;
  }
}
