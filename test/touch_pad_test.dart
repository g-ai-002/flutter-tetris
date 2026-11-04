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
  testWidgets('触屏按钮可以移动、旋转与软降', (tester) async {
    final controller = TetrisController(
      mode: GameMode.endless,
      seed: 5,
      autoTick: false,
    );
    addTearDown(controller.dispose);
    controller.start();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: TouchPad(controller: controller)),
      ),
    );

    final startX = controller.piece!.x;
    final startY = controller.piece!.y;

    await tester.tap(find.text('左移'));
    await tester.pump();
    expect(controller.piece!.x, startX - 1);

    await tester.tap(find.text('右移'));
    await tester.pump();
    expect(controller.piece!.x, startX);

    await tester.tap(find.text('旋转'));
    await tester.pump();
    expect(controller.piece!.rotation, 1);

    await tester.tap(find.text('软降'));
    await tester.pump();
    expect(controller.piece!.y, startY + 1);
    expect(controller.score, 1);
  });

  testWidgets('暂停时触屏按钮不再响应', (tester) async {
    final controller = TetrisController(
      mode: GameMode.endless,
      seed: 6,
      autoTick: false,
    );
    addTearDown(controller.dispose);
    controller.start();
    controller.pause();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: TouchPad(controller: controller)),
      ),
    );

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
