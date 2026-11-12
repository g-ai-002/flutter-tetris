import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tetris/input/key_bindings.dart';
import 'package:flutter_tetris/pages/widgets/game_rails.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('键盘提示条显示当前键位', (tester) async {
    final bindings = KeyBindings.defaults().rebind(GameAction.moveLeft, LogicalKeyboardKey.keyA);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameKeyboardHint(bindings: bindings)),
      ),
    );

    expect(find.text('A/→'), findsOneWidget);
    expect(find.text('空格'), findsOneWidget);
    expect(find.text('移动'), findsOneWidget);
  });

  testWidgets('键位恢复默认后提示条同步回默认按键', (tester) async {
    final bindings = KeyBindings.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameKeyboardHint(bindings: bindings)),
      ),
    );

    expect(find.text('←/→'), findsOneWidget);
    expect(find.text('A/→'), findsNothing);
  });
}
