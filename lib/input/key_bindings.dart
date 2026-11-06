import 'dart:convert';

import 'package:flutter/services.dart';

/// 可在设置中重新绑定的游戏操作。
enum GameAction {
  moveLeft('左移'),
  moveRight('右移'),
  softDrop('软降'),
  hardDrop('硬降'),
  rotateClockwise('顺时针旋转'),
  rotateCounterClockwise('逆时针旋转'),
  hold('暂存'),
  pause('暂停'),
  restart('重新开始');

  const GameAction(this.label);

  final String label;

  /// 长按可持续触发的操作，只有这些操作响应键盘与手柄的重复事件。
  bool get repeatable =>
      this == GameAction.moveLeft ||
      this == GameAction.moveRight ||
      this == GameAction.softDrop;
}

/// 键盘键位表：每个操作至少一个按键，同一按键只属于一个操作。
///
/// 默认保留多键并存（如顺时针同时支持 ↑ 与 X），重新绑定某操作后该操作
/// 只保留新按键，被占用的按键会与对方交换，避免出现无法操作的动作。
class KeyBindings {
  KeyBindings(Map<GameAction, Set<LogicalKeyboardKey>> keys)
    : _keys = {
        for (final action in GameAction.values)
          action: Set.unmodifiable(
            keys[action] == null || keys[action]!.isEmpty
                ? defaultKeysFor(action)
                : keys[action]!,
          ),
      };

  final Map<GameAction, Set<LogicalKeyboardKey>> _keys;

  static KeyBindings defaults() => KeyBindings({
    GameAction.moveLeft: {LogicalKeyboardKey.arrowLeft},
    GameAction.moveRight: {LogicalKeyboardKey.arrowRight},
    GameAction.softDrop: {LogicalKeyboardKey.arrowDown},
    GameAction.hardDrop: {LogicalKeyboardKey.space},
    GameAction.rotateClockwise: {
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyX,
    },
    GameAction.rotateCounterClockwise: {LogicalKeyboardKey.keyZ},
    GameAction.hold: {
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    },
    GameAction.pause: {LogicalKeyboardKey.keyP, LogicalKeyboardKey.escape},
    GameAction.restart: {LogicalKeyboardKey.keyR},
  });

  static Set<LogicalKeyboardKey> defaultKeysFor(GameAction action) =>
      Set.of(defaults()._keys[action]!);

  /// 从偏好中恢复键位；内容缺失、损坏或冲突时回退到默认键位。
  static KeyBindings decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaults();
    try {
      final data = jsonDecode(raw);
      if (data is! Map) return defaults();
      final parsed = <GameAction, Set<LogicalKeyboardKey>>{};
      final used = <LogicalKeyboardKey>{};
      for (final action in GameAction.values) {
        final keys = <LogicalKeyboardKey>{};
        final stored = data[action.name];
        if (stored is List) {
          for (final value in stored) {
            final id = value is int ? value : int.tryParse('$value');
            final key = id == null
                ? null
                : LogicalKeyboardKey.findKeyByKeyId(id);
            if (key != null && used.add(key)) keys.add(key);
          }
        }
        parsed[action] = keys;
      }
      for (final action in GameAction.values) {
        if (parsed[action]!.isNotEmpty) continue;
        for (final fallback in defaultKeysFor(action)) {
          if (used.add(fallback)) {
            parsed[action]!.add(fallback);
            break;
          }
        }
        if (parsed[action]!.isEmpty) {
          parsed[action]!.add(defaultKeysFor(action).first);
        }
      }
      return KeyBindings(parsed);
    } catch (_) {
      return defaults();
    }
  }

  String encode() => jsonEncode({
    for (final action in GameAction.values)
      action.name: _keys[action]!.map((key) => key.keyId).toList(),
  });

  Set<LogicalKeyboardKey> keysFor(GameAction action) => _keys[action]!;

  /// 设置页展示用主键：多键并存时取默认顺序中的第一个。
  LogicalKeyboardKey primaryKey(GameAction action) => _keys[action]!.first;

  List<String> labelsFor(GameAction action) =>
      _keys[action]!.map(formatKeyLabel).toList();

  /// 返回按键对应的操作，未绑定时为 null。
  GameAction? actionFor(LogicalKeyboardKey key) {
    for (final action in GameAction.values) {
      if (_keys[action]!.contains(key)) return action;
    }
    return null;
  }

  /// 把 [key] 绑定到 [action]；原本占用该键的操作改绑当前操作的主键。
  KeyBindings rebind(GameAction action, LogicalKeyboardKey key) {
    final next = <GameAction, Set<LogicalKeyboardKey>>{
      for (final entry in _keys.entries) entry.key: Set.of(entry.value),
    };
    final displaced = primaryKey(action);
    for (final other in GameAction.values) {
      if (other == action) continue;
      final keys = next[other]!;
      if (!keys.remove(key) || keys.isNotEmpty) continue;
      keys.add(displaced == key ? defaultKeysFor(other).first : displaced);
    }
    next[action] = {key};
    return KeyBindings(next);
  }
}

/// 键盘键位在界面上的短名称，优先使用符号与常用键名。
String formatKeyLabel(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.arrowLeft) return '←';
  if (key == LogicalKeyboardKey.arrowRight) return '→';
  if (key == LogicalKeyboardKey.arrowUp) return '↑';
  if (key == LogicalKeyboardKey.arrowDown) return '↓';
  if (key == LogicalKeyboardKey.space) return '空格';
  if (key == LogicalKeyboardKey.escape) return 'Esc';
  if (key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter) {
    return 'Enter';
  }
  if (key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight) {
    return 'Shift';
  }
  if (key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight) {
    return 'Ctrl';
  }
  if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight) {
    return 'Alt';
  }
  final label = key.keyLabel;
  return label.isEmpty ? '键 ${key.keyId}' : label;
}
