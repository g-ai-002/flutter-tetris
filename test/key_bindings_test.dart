import 'package:flutter/services.dart';
import 'package:flutter_tetris/input/key_bindings.dart';
import 'package:flutter_tetris/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  test('默认键位覆盖全部操作且没有重复按键', () {
    final bindings = KeyBindings.defaults();
    final seen = <LogicalKeyboardKey>{};
    for (final action in GameAction.values) {
      final keys = bindings.keysFor(action);
      expect(keys, isNotEmpty, reason: '${action.label} 缺少按键');
      for (final key in keys) {
        expect(seen.add(key), isTrue, reason: '${action.label} 的按键重复');
      }
    }
    expect(bindings.actionFor(LogicalKeyboardKey.arrowLeft), GameAction.moveLeft);
    expect(bindings.actionFor(LogicalKeyboardKey.space), GameAction.hardDrop);
    expect(bindings.actionFor(LogicalKeyboardKey.keyX), GameAction.rotateClockwise);
    expect(bindings.actionFor(LogicalKeyboardKey.keyQ), isNull);
  });

  test('编码后可完整还原主键与多键并存', () {
    final original = KeyBindings.defaults();
    final restored = KeyBindings.decode(original.encode());
    for (final action in GameAction.values) {
      expect(restored.keysFor(action), original.keysFor(action));
      expect(restored.primaryKey(action), original.primaryKey(action));
    }
  });

  test('损坏或缺失的键位数据回退到默认值', () {
    for (final raw in [null, '', '{oops', '[]', '{"moveLeft":"x"}']) {
      final bindings = KeyBindings.decode(raw);
      expect(bindings.primaryKey(GameAction.moveLeft), LogicalKeyboardKey.arrowLeft);
      for (final action in GameAction.values) {
        expect(bindings.keysFor(action), isNotEmpty);
      }
    }
  });

  test('重新绑定时与已占用按键交换，双方都可继续操作', () {
    final bindings = KeyBindings.defaults().rebind(GameAction.hold, LogicalKeyboardKey.arrowLeft);
    expect(bindings.keysFor(GameAction.hold), {LogicalKeyboardKey.arrowLeft});
    expect(bindings.actionFor(LogicalKeyboardKey.arrowLeft), GameAction.hold);
    // 左移原本只有 ←，被占用后换到暂存的主键 C。
    expect(bindings.keysFor(GameAction.moveLeft), {LogicalKeyboardKey.keyC});
    expect(bindings.actionFor(LogicalKeyboardKey.keyC), GameAction.moveLeft);
  });

  test('自定义键位可解析并持久化到偏好', () async {
    final storage = await prepareStorage();
    final settings = SettingsProvider(storage);
    await settings.bindKey(GameAction.hardDrop, LogicalKeyboardKey.enter);
    expect(settings.keyBindings.primaryKey(GameAction.hardDrop), LogicalKeyboardKey.enter);
    expect(storage.keyBindings.actionFor(LogicalKeyboardKey.enter), GameAction.hardDrop);

    await settings.resetKeyBindings();
    expect(storage.keyBindings.primaryKey(GameAction.hardDrop), LogicalKeyboardKey.space);
  });

  test('按键标签使用符号与常用键名', () {
    final bindings = KeyBindings.defaults();
    expect(bindings.labelsFor(GameAction.moveLeft), ['←']);
    expect(bindings.labelsFor(GameAction.hardDrop), ['空格']);
    expect(bindings.labelsFor(GameAction.rotateClockwise), ['↑', 'X']);
    expect(bindings.labelsFor(GameAction.pause), ['P', 'Esc']);
  });
}
