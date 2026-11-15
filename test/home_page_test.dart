import 'dart:convert';

import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/pages/home_page.dart';
import 'package:flutter_tetris/pages/widgets/home_top_bar.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_helpers.dart';

void main() {
  late StorageService storage;
  late String todayKey;

  setUp(() async {
    todayKey = DailyChallenge.today().key;
    storage = await prepareStorage({
      'best_score_endless': 12345,
      'plays_endless': 3,
      'best_sprint_time_ms': 83450,
      'plays_sprint': 2,
      'best_score_ultra': 8900,
      'plays_ultra': 1,
      'best_score_arcade': 5432,
      'plays_arcade': 1,
      'daily_records': jsonEncode({
        todayKey: {'score': 4321, 'lines': 30, 'level': 4, 'plays': 2},
      }),
    });
  });

  testWidgets('首页展示标题与四种标准玩法', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapPage(child: const HomePage(), storage: storage));

    expect(find.text('俄罗斯方块'), findsWidgets);
    expect(find.text('经典模式'), findsOneWidget);
    expect(find.text('40 行竞速'), findsOneWidget);
    expect(find.text('2 分钟计时'), findsOneWidget);
    expect(find.text('街机模式'), findsOneWidget);
    expect(find.text('关卡模式'), findsOneWidget);
    expect(find.text('每日挑战'), findsOneWidget);
    expect(find.textContaining('今日 4,321 分'), findsOneWidget);
    expect(find.text('连续打卡 1 天'), findsOneWidget);
    expect(find.textContaining('最高 12,345 分'), findsOneWidget);
    expect(find.textContaining('最快 01:23.45'), findsOneWidget);
    expect(find.textContaining('最高 8,900 分'), findsOneWidget);
    expect(find.textContaining('最高 5,432 分'), findsOneWidget);
    expect(find.textContaining('v${AppConstants.version}'), findsOneWidget);
  });

  testWidgets('首页可以打开关卡选择页', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapPage(child: const HomePage(), storage: storage));

    await tester.tap(find.text('关卡模式'));
    await tester.pumpAndSettle();
    expect(find.text('挑战进度'), findsOneWidget);
    expect(find.text('初入长安'), findsOneWidget);
  });

  testWidgets('首页窄屏单列排布并支持切换深色模式', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapPage(child: const HomePage(), storage: storage));
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump();
    expect(storage.darkMode, isTrue);
  });

  testWidgets('首页背景铺满整个屏幕', (tester) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapPage(child: const HomePage(), storage: storage));
    await tester.pump();

    final background = tester
        .widgetList<Container>(
          find.descendant(of: find.byType(HomePage), matching: find.byType(Container)),
        )
        .firstWhere((widget) => (widget.decoration as BoxDecoration?)?.gradient != null);
    expect(tester.getRect(find.byWidget(background)).size, size);
  });

  testWidgets('首页内容在高屏上水平与垂直居中', (tester) async {
    const size = Size(1280, 1600);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapPage(child: const HomePage(), storage: storage));
    await tester.pump();

    final topBar = tester.getRect(find.byType(HomeTopBar));
    final footer = tester.getRect(find.textContaining('本地离线'));
    expect(topBar.left, closeTo(size.width - topBar.right, 1));
    // 上下内边距分别为 14 与 24，内容在扣除内边距后的区域里垂直居中。
    expect(topBar.top - 14, closeTo(size.height - 24 - footer.bottom, 1));
  });

  testWidgets('首页可以打开设置与纪录页', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapPage(child: const HomePage(), storage: storage));

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    expect(find.text('外观与操作'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('本地纪录'));
    await tester.pumpAndSettle();
    expect(find.text('本地纪录'), findsOneWidget);
  });
}
