import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/game/garbage.dart';
import 'package:flutter_tetris/game/level.dart';
import 'package:flutter_tetris/pages/game_page.dart';
import 'package:flutter_tetris/services/storage_service.dart';
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
    expect(find.text('HOLD 暂存'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('分数'), findsOneWidget);
    expect(find.text('消行'), findsOneWidget);
    expect(find.text('等级'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
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
    expect(find.text('旋转'), findsOneWidget);
    expect(find.text('硬降'), findsOneWidget);
    expect(find.text('左移'), findsOneWidget);
    expect(find.text('软降'), findsOneWidget);
    expect(find.text('右移'), findsOneWidget);
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
    expect(find.text('HOLD 暂存'), findsOneWidget);
    expect(tester.takeException(), isNull);

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
}
