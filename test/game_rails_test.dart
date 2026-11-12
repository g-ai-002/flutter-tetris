import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/pages/widgets/game_rails.dart';
import 'package:flutter_tetris/pages/widgets/piece_slot.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/theme/block_palette.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    storage = await prepareStorage();
  });

  Widget rail(TetrisController controller, Widget child) => wrapPage(
    storage: storage,
    child: Scaffold(body: child),
  );

  testWidgets('宽屏侧栏按玩法 previewCount 展示预览块', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final standard = TetrisController(mode: GameMode.endless, autoTick: false)..start();
    await tester.pumpWidget(
      rail(standard, GameRightRail(controller: standard, palette: BlockPalette.light)),
    );
    await tester.pump();
    expect(find.text('下一个'), findsOneWidget);
    expect(find.byType(PieceSlot), findsNWidgets(5));
    await tester.pumpWidget(const SizedBox.shrink());
    standard.dispose();

    final arcade = TetrisController(mode: GameMode.arcade, autoTick: false)..start();
    await tester.pumpWidget(
      rail(arcade, GameRightRail(controller: arcade, palette: BlockPalette.light)),
    );
    await tester.pump();
    expect(find.byType(PieceSlot), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    arcade.dispose();
  });

  testWidgets('紧凑侧栏最多展示三块预览并标注中文', (tester) async {
    final controller = TetrisController(mode: GameMode.endless, autoTick: false)..start();
    await tester.pumpWidget(
      rail(controller, GameCompactRail(controller: controller, palette: BlockPalette.light)),
    );
    await tester.pump();
    expect(find.text('下一个'), findsOneWidget);
    expect(find.text('暂存'), findsOneWidget);
    expect(find.text('NEXT'), findsNothing);
    expect(find.text('HOLD'), findsNothing);
    expect(find.byType(PieceSlot), findsNWidgets(4));
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
