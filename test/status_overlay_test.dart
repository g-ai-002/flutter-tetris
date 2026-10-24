import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/game/overlays/tetris_overlays.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('暂停浮层显示继续并触发回调', (tester) async {
    var resumed = 0;
    await tester.pumpWidget(
      _wrap(TetrisPauseOverlay(onResume: () => resumed++)),
    );

    expect(find.text('已暂停'), findsOneWidget);
    await tester.tap(find.text('继续'));
    expect(resumed, 1);
  });

  testWidgets('结束浮层显示标题并可重新开始', (tester) async {
    var restarted = 0;
    await tester.pumpWidget(
      _wrap(
        TetrisGameOverOverlay(
          title: '游戏结束',
          onRestart: () => restarted++,
        ),
      ),
    );

    expect(find.text('游戏结束'), findsOneWidget);
    await tester.tap(find.text('重新开始'));
    expect(restarted, 1);
  });

  testWidgets('挑战完成标题可复用同一浮层', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TetrisGameOverOverlay(title: '挑战完成！', onRestart: () {}),
      ),
    );
    expect(find.text('挑战完成！'), findsOneWidget);
  });
}
