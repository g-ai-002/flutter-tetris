import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tetris/flame/tetris_game.dart';
import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/garbage.dart';
import 'package:flutter_tetris/game/level.dart';
import 'package:flutter_tetris/input/key_bindings.dart';
import 'package:flutter_tetris/pages/game_page.dart';
import 'package:flutter_tetris/services/log_service.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/theme/block_skin.dart';
import 'package:flutter_tetris/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    storage = await prepareStorage();
  });

  testWidgets('宽屏对局页展示侧栏信息与棋盘', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.endless),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('经典模式'), findsOneWidget);
    expect(find.text('暂存'), findsOneWidget);
    expect(find.text('下一个'), findsOneWidget);
    expect(find.text('分数'), findsOneWidget);
    expect(find.text('消行'), findsOneWidget);
    expect(find.text('等级'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('对局按偏好使用 120Hz 逻辑更新速率', (tester) async {
    final custom = await prepareStorage({AppConstants.prefKeyLogicRate: 120});
    LogService.reset();
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.endless),
        storage: custom,
      ),
    );
    await tester.pump();

    expect(LogService.getRecentLogs().any((line) => line.contains('逻辑 120Hz')), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('街机模式没有暂存区，只保留下一块预览', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.arcade),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final game = tester.widget<GameWidget<TetrisGame>>(find.byType(GameWidget<TetrisGame>)).game!;
    expect(find.text('街机模式'), findsOneWidget);
    expect(find.textContaining('街机计分'), findsOneWidget);
    expect(find.text('暂存'), findsNothing);
    expect(game.controller.nextQueue, hasLength(1));
    expect(game.controller.rules.holdEnabled, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('窄屏对局页展示手游操作区', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.sprint),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('40 行竞速'), findsOneWidget);
    expect(find.text('暂存'), findsOneWidget);
    expect(find.text('下一个'), findsOneWidget);
    expect(find.text('左移'), findsOneWidget);
    expect(find.text('硬降'), findsOneWidget);
    expect(find.text('右移'), findsOneWidget);
    expect(find.text('旋转'), findsNothing);
    expect(find.text('软降'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('计时模式在顶栏展示剩余时间', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.ultra),
        storage: storage,
      ),
    );
    await tester.pump();

    expect(find.text('2 分钟计时'), findsOneWidget);
    expect(find.textContaining('剩余 02:00'), findsWidgets);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('每日挑战展示日期、剩余时间与固定种子提示', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final daily = DailyChallenge.forDate(DateTime(2026, 11, 5));

    await tester.pumpWidget(
      wrapPage(
        child: GamePage(mode: GameMode.daily, daily: daily),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('每日挑战 · 11 月 5 日'), findsOneWidget);
    expect(find.textContaining('固定牌序'), findsWidgets);
    expect(find.textContaining('剩余 02:00'), findsWidgets);
    expect(find.text('暂存'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('对局页使用所选皮肤', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    storage = await prepareStorage({'block_skin': BlockSkin.ink.name});

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.endless),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final gameWidget = tester.widget<GameWidget<TetrisGame>>(find.byType(GameWidget<TetrisGame>));
    expect(gameWidget.game!.style.palette.skin, BlockSkin.ink);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('关卡模式展示关卡名、目标与剩余时间', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const level = LevelDefinition(
      id: 5,
      name: '落子无悔',
      brief: '',
      targetLines: 10,
      timeLimit: Duration(seconds: 110),
      terrain: ['#.####.###', '##.######.'],
      garbage: GarbageRule(interval: Duration(seconds: 30)),
      seed: 105,
    );

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.level, level: level),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('第 5 关 · 落子无悔'), findsOneWidget);
    expect(find.text('0 / 10 行'), findsOneWidget);
    expect(find.textContaining('剩余 01:50'), findsWidgets);
    expect(find.textContaining('垃圾行'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('进入对局后无需点击即可用键盘操作', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.endless),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final game = tester.widget<GameWidget<TetrisGame>>(find.byType(GameWidget<TetrisGame>)).game!;
    final startX = game.controller.piece!.x;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(game.controller.piece!.x, startX - 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('暂停弹窗期间暂停 Flame 引擎，继续后恢复', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.endless),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final game = tester.widget<GameWidget<TetrisGame>>(find.byType(GameWidget<TetrisGame>)).game!;
    expect(game.paused, isFalse);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();
    expect(game.paused, isTrue);

    await tester.tap(find.text('继续游戏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.paused, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('对局页使用自定义键位', (tester) async {
    tester.view.physicalSize = const Size(1280, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bindings = KeyBindings.defaults().rebind(GameAction.moveLeft, LogicalKeyboardKey.keyA);
    storage = await prepareStorage({AppConstants.prefKeyKeyBindings: bindings.encode()});

    await tester.pumpWidget(
      wrapPage(
        child: const GamePage(mode: GameMode.endless),
        storage: storage,
      ),
    );
    await tester.pump();

    final game = tester.widget<GameWidget<TetrisGame>>(find.byType(GameWidget<TetrisGame>)).game!;
    tester.widget<Focus>(find.byKey(const ValueKey('game-focus'))).focusNode!.requestFocus();
    await tester.pump();
    final startX = game.controller.piece!.x;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(game.controller.piece!.x, startX);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(game.controller.piece!.x, startX - 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
