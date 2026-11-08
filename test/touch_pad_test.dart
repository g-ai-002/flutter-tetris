import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/pages/widgets/piece_preview.dart';
import 'package:flutter_tetris/pages/widgets/status_chip.dart';
import 'package:flutter_tetris/pages/widgets/touch_pad.dart';
import 'package:flutter_tetris/game/tetromino.dart';
import 'package:flutter_tetris/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TetrisController build({int seed = 5}) {
    final controller = TetrisController(
      mode: GameMode.endless,
      seed: seed,
      autoTick: false,
    );
    addTearDown(controller.dispose);
    controller.start();
    return controller;
  }

  Future<void> pumpPad(
    WidgetTester tester,
    TetrisController controller, {
    bool vertical = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: vertical ? 160 : 380,
              child: TouchPad(controller: controller, vertical: vertical),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('触屏只保留左移、硬降与右移三键', (tester) async {
    final controller = build();
    await pumpPad(tester, controller);

    expect(find.text('左移'), findsOneWidget);
    expect(find.text('硬降'), findsOneWidget);
    expect(find.text('右移'), findsOneWidget);
    expect(find.text('旋转'), findsNothing);
    expect(find.text('软降'), findsNothing);
    expect(find.text('暂存'), findsNothing);

    final startX = controller.piece!.x;
    await tester.tap(find.text('左移'));
    await tester.pump();
    expect(controller.piece!.x, startX - 1);

    await tester.tap(find.text('右移'));
    await tester.pump();
    expect(controller.piece!.x, startX);

    final revision = controller.boardRevision;
    await tester.tap(find.text('硬降'));
    await tester.pump();
    expect(controller.boardRevision, greaterThan(revision));
  });

  testWidgets('横排三键等宽一行，纵排上下堆叠供横屏侧栏使用', (tester) async {
    final controller = build(seed: 8);
    await pumpPad(tester, controller);

    final left = tester.getCenter(find.text('左移'));
    final hard = tester.getCenter(find.text('硬降'));
    final right = tester.getCenter(find.text('右移'));
    expect(left.dy, closeTo(hard.dy, 0.5));
    expect(right.dy, closeTo(hard.dy, 0.5));
    expect(left.dx, lessThan(hard.dx));
    expect(right.dx, greaterThan(hard.dx));

    await pumpPad(tester, controller, vertical: true);

    final stackedLeft = tester.getCenter(find.text('左移'));
    final stackedHard = tester.getCenter(find.text('硬降'));
    final stackedRight = tester.getCenter(find.text('右移'));
    expect(stackedLeft.dx, closeTo(stackedHard.dx, 0.5));
    expect(stackedRight.dx, closeTo(stackedHard.dx, 0.5));
    expect(stackedLeft.dy, lessThan(stackedHard.dy));
    expect(stackedRight.dy, greaterThan(stackedHard.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('暂停时触屏按钮不再响应', (tester) async {
    final controller = build(seed: 6);
    controller.pause();
    await pumpPad(tester, controller);

    final x = controller.piece!.x;
    await tester.tap(find.text('左移'));
    await tester.pump();
    expect(controller.piece!.x, x);
  });

  testWidgets('方块预览与状态胶囊可以绘制', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildDarkTheme(),
        home: Scaffold(
          body: Column(
            children: [
              for (final type in TetrominoType.values)
                PiecePreview(type: type, color: Colors.orange, size: 32),
              const PiecePreview(type: null, color: Colors.grey),
              const StatusChip(accent: appRed, child: Text('连击 ×2')),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('连击 ×2'), findsOneWidget);
  });
}
