import 'package:flutter/material.dart';
import 'package:flutter_tetris/flame/playfield_component.dart';
import 'package:flutter_tetris/flame/tetris_game.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/tetris_controller.dart';
import 'package:flutter_tetris/input/key_bindings.dart';
import 'package:flutter_tetris/pages/widgets/game_shell.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/theme/block_palette.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late StorageService storage;
  late TetrisController controller;
  late TetrisGame game;

  setUp(() async {
    storage = await prepareStorage();
    controller = TetrisController(
      mode: GameMode.endless,
      autoTick: false,
      seed: 7,
    )..start();
    game = TetrisGame(
      controller: controller,
      style: const PlayfieldStyle(palette: BlockPalette.light),
    );
  });

  tearDown(() => controller.dispose());

  Widget shell() => wrapPage(
    storage: storage,
    child: GameShell(
      controller: controller,
      game: game,
      palette: BlockPalette.light,
      bindings: KeyBindings.defaults(),
      onExit: () {},
      onHelp: () {},
      onPause: () {},
    ),
  );

  testWidgets('宽屏外壳使用三栏版式', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(shell());
    await tester.pump();

    expect(find.text('经典模式'), findsOneWidget);
    expect(find.text('暂存'), findsOneWidget);
    expect(find.text('下一个'), findsOneWidget);
    expect(find.text('分数'), findsOneWidget);
    expect(find.text('消行'), findsOneWidget);
    expect(find.text('等级'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('窄屏外壳切换单列版式与触控键', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(shell());
    await tester.pump();

    expect(find.text('经典模式'), findsOneWidget);
    expect(find.text('暂存'), findsOneWidget);
    expect(find.text('下一个'), findsOneWidget);
    expect(find.text('左移'), findsOneWidget);
    expect(find.text('硬降'), findsOneWidget);
    expect(find.text('右移'), findsOneWidget);
    expect(find.text('旋转'), findsNothing);
    expect(find.text('软降'), findsNothing);
    expect(find.text('分数'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('窄屏信息栏贴在棋盘左侧', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(shell());
    await tester.pump();

    final railRight = tester.getTopRight(find.text('下一个')).dx;
    final boardLeft = tester
        .getTopLeft(find.byKey(const ValueKey('tetris-board')))
        .dx;
    expect(railRight, lessThan(boardLeft));
    expect(find.text('暂存'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
