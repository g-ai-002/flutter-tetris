import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/input/gamepad_input.dart';
import 'package:flutter_tetris/input/key_bindings.dart';
import 'package:gamepads/gamepads.dart';

NormalizedGamepadEvent buttonEvent(GamepadButton button, double value) {
  return NormalizedGamepadEvent(
    gamepadId: 'pad',
    timestamp: 0,
    value: value,
    button: button,
    rawEvent: GamepadEvent(
      gamepadId: 'pad',
      timestamp: 0,
      type: KeyType.button,
      key: button.name,
      value: value,
    ),
  );
}

NormalizedGamepadEvent axisEvent(GamepadAxis axis, double value) {
  return NormalizedGamepadEvent(
    gamepadId: 'pad',
    timestamp: 0,
    value: value,
    axis: axis,
    rawEvent: GamepadEvent(
      gamepadId: 'pad',
      timestamp: 0,
      type: KeyType.analog,
      key: axis.name,
      value: value,
    ),
  );
}

void main() {
  test('标准手柄按钮映射到对应操作', () {
    expect(gamepadActionForButton(GamepadButton.a), GameAction.rotateClockwise);
    expect(
      gamepadActionForButton(GamepadButton.b),
      GameAction.rotateCounterClockwise,
    );
    expect(gamepadActionForButton(GamepadButton.x), GameAction.hold);
    expect(gamepadActionForButton(GamepadButton.leftBumper), GameAction.hold);
    expect(gamepadActionForButton(GamepadButton.y), GameAction.hardDrop);
    expect(gamepadActionForButton(GamepadButton.dpadUp), GameAction.hardDrop);
    expect(gamepadActionForButton(GamepadButton.dpadLeft), GameAction.moveLeft);
    expect(
      gamepadActionForButton(GamepadButton.dpadRight),
      GameAction.moveRight,
    );
    expect(gamepadActionForButton(GamepadButton.dpadDown), GameAction.softDrop);
    expect(gamepadActionForButton(GamepadButton.start), GameAction.pause);
    expect(gamepadActionForButton(GamepadButton.back), isNull);
  });

  testWidgets('手柄按钮触发一次，摇杆长按连发并在回中后停止', (tester) async {
    final actions = <GameAction>[];
    final events = StreamController<NormalizedGamepadEvent>.broadcast();
    addTearDown(events.close);
    final service = GamepadService(
      onAction: actions.add,
      events: events.stream,
      connections: const Stream<GamepadConnectionEvent>.empty(),
      moveRepeat: const Duration(milliseconds: 100),
      softDropRepeat: const Duration(milliseconds: 50),
    );
    addTearDown(service.stop);
    await service.start();

    events.add(buttonEvent(GamepadButton.a, 1));
    await tester.pump();
    expect(actions, [GameAction.rotateClockwise]);

    // 平台重复上报按下状态时不会连续旋转。
    events.add(buttonEvent(GamepadButton.a, 1));
    await tester.pump();
    expect(actions, [GameAction.rotateClockwise]);
    events.add(buttonEvent(GamepadButton.a, 0));
    await tester.pump();

    events.add(axisEvent(GamepadAxis.leftStickX, 0.9));
    await tester.pump();
    expect(actions.last, GameAction.moveRight);
    await tester.pump(const Duration(milliseconds: 110));
    expect(actions.where((action) => action == GameAction.moveRight).length, 2);

    // 斜向推杆时优先保持水平移动，不会在两个轴之间反复切换。
    events.add(axisEvent(GamepadAxis.leftStickY, -0.9));
    await tester.pump();
    expect(actions.last, GameAction.moveRight);
    await tester.pump(const Duration(milliseconds: 110));
    expect(actions.where((action) => action == GameAction.moveRight).length, 3);
    expect(actions.where((action) => action == GameAction.softDrop), isEmpty);

    // 松开水平方向后转为软降，竖直回中后停止连发。
    events.add(axisEvent(GamepadAxis.leftStickX, 0));
    await tester.pump();
    expect(actions.last, GameAction.softDrop);
    await tester.pump(const Duration(milliseconds: 60));
    expect(actions.where((action) => action == GameAction.softDrop).length, 2);

    events.add(axisEvent(GamepadAxis.leftStickY, 0));
    await tester.pump();
    final settled = actions.length;
    await tester.pump(const Duration(milliseconds: 250));
    expect(actions.length, settled);

    // 取消订阅用不阻塞的方式，避免在组件测试的假时钟里等待流关闭。
    unawaited(service.stop());
    await tester.pump();
  });

  testWidgets('十字键长按移动，松开即停止', (tester) async {
    final actions = <GameAction>[];
    final events = StreamController<NormalizedGamepadEvent>.broadcast();
    addTearDown(events.close);
    final service = GamepadService(
      onAction: actions.add,
      events: events.stream,
      connections: const Stream<GamepadConnectionEvent>.empty(),
      moveRepeat: const Duration(milliseconds: 100),
    );
    addTearDown(service.stop);
    await service.start();

    events.add(buttonEvent(GamepadButton.dpadLeft, 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    expect(actions.where((action) => action == GameAction.moveLeft).length, 2);

    events.add(buttonEvent(GamepadButton.dpadLeft, 0));
    await tester.pump();
    final count = actions.length;
    await tester.pump(const Duration(milliseconds: 200));
    expect(actions.length, count);
  });
}
