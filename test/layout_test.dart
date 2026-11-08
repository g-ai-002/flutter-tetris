import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/pages/game_page.dart';
import 'package:flutter_tetris/pages/home_page.dart';
import 'package:flutter_tetris/pages/records_page.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/utils/game_layout.dart';

import 'test_helpers.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    storage = await prepareStorage();
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> pumpAt(
    WidgetTester tester,
    Size size,
    Widget page, {
    TargetPlatform platform = TargetPlatform.android,
    double textScale = 1,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      wrapPage(
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: page,
        ),
        storage: storage,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    debugDefaultTargetPlatformOverride = null;
  }

  group('版式判定', () {
    test('桌面宽窗三栏，窄窗单列，手机横屏双翼', () {
      expect(GameLayout.of(const Size(1280, 860)).kind, GameLayoutKind.rails);
      expect(GameLayout.of(const Size(480, 640)).kind, GameLayoutKind.stack);
    });

    test('移动端横屏使用两侧操作区', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(GameLayout.of(const Size(844, 390)).kind, GameLayoutKind.sidePads);
      expect(GameLayout.of(const Size(390, 844)).kind, GameLayoutKind.stack);
    });
  });

  testWidgets('手机竖屏棋盘占满宽度且不被操作区挤扁', (tester) async {
    await pumpAt(
      tester,
      const Size(390, 844),
      const GamePage(mode: GameMode.endless),
    );
    final board = tester.getSize(find.byKey(const ValueKey('tetris-board')));
    expect(board.width / board.height, closeTo(0.5, 0.02));
    expect(board.height, greaterThan(844 * 0.62));
    expect(find.text('左移'), findsOneWidget);
    expect(find.text('硬降'), findsOneWidget);
    expect(find.text('右移'), findsOneWidget);
    expect(find.text('旋转'), findsNothing);
    expect(find.text('软降'), findsNothing);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('手机竖屏进入对局不强制横屏', (tester) async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pumpAt(
      tester,
      const Size(390, 844),
      const GamePage(mode: GameMode.endless),
    );

    final methods = calls.map((call) => call.method);
    expect(methods, contains('SystemChrome.setEnabledSystemUIMode'));
    expect(methods, isNot(contains('SystemChrome.setPreferredOrientations')));
    final board = tester.getSize(find.byKey(const ValueKey('tetris-board')));
    expect(board.width / board.height, closeTo(0.5, 0.02));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('手机横屏收起顶栏，棋盘获得接近全屏的高度', (tester) async {
    await pumpAt(
      tester,
      const Size(844, 390),
      const GamePage(mode: GameMode.sprint),
    );
    final board = tester.getSize(find.byKey(const ValueKey('tetris-board')));
    expect(board.width / board.height, closeTo(0.5, 0.02));
    expect(board.height, greaterThan(390 * 0.75));
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('左移'), findsOneWidget);
    expect(find.text('硬降'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('窄屏与大字体下不溢出', (tester) async {
    await pumpAt(
      tester,
      const Size(320, 568),
      const GamePage(mode: GameMode.level),
      textScale: 1.3,
    );
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('平板竖屏棋盘随高度放大且不超过单格上限', (tester) async {
    await pumpAt(
      tester,
      const Size(800, 1280),
      const GamePage(mode: GameMode.endless),
    );
    final board = tester.getSize(find.byKey(const ValueKey('tetris-board')));
    expect(board.width / board.height, closeTo(0.5, 0.02));
    expect(board.width, lessThanOrEqualTo(640));
    expect(board.height, greaterThan(900));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('桌面宽窗保留左右侧栏与键盘提示', (tester) async {
    await pumpAt(
      tester,
      const Size(1280, 860),
      const GamePage(mode: GameMode.endless),
      platform: TargetPlatform.windows,
    );
    expect(find.text('暂存'), findsWidgets);
    expect(find.text('下一个'), findsOneWidget);
    expect(find.textContaining('移动'), findsOneWidget);
    final board = tester.getSize(find.byKey(const ValueKey('tetris-board')));
    expect(board.height, greaterThan(700));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('桌面窄窗使用单列布局并隐藏触控键', (tester) async {
    await pumpAt(
      tester,
      const Size(480, 640),
      const GamePage(mode: GameMode.endless),
      platform: TargetPlatform.windows,
    );
    expect(find.text('左移'), findsNothing);
    expect(find.textContaining('硬降'), findsWidgets);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('首页中宽窗口玩法卡片两列排布', (tester) async {
    await pumpAt(tester, const Size(700, 1000), const HomePage());
    final classic = tester.getTopLeft(find.text('经典模式'));
    final sprint = tester.getTopLeft(find.text('40 行竞速'));
    expect(sprint.dy, closeTo(classic.dy, 1));
    expect(sprint.dx, greaterThan(classic.dx + 100));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('首页窄屏单列排布', (tester) async {
    await pumpAt(tester, const Size(390, 844), const HomePage());
    final classic = tester.getTopLeft(find.text('经典模式'));
    final sprint = tester.getTopLeft(find.text('40 行竞速'));
    expect(sprint.dx, closeTo(classic.dx, 1));
    expect(sprint.dy, greaterThan(classic.dy));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('平板横屏保留侧栏并补齐触控操作', (tester) async {
    await pumpAt(
      tester,
      const Size(1024, 768),
      const GamePage(mode: GameMode.endless),
    );
    expect(find.text('暂存'), findsWidgets);
    expect(find.text('左移'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('折叠屏展开态竖屏按单列排布', (tester) async {
    await pumpAt(
      tester,
      const Size(673, 841),
      const GamePage(mode: GameMode.endless),
    );
    final board = tester.getSize(find.byKey(const ValueKey('tetris-board')));
    expect(board.width, greaterThan(280));
    expect(board.height, greaterThan(550));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('超宽窗口棋盘保持居中', (tester) async {
    await pumpAt(
      tester,
      const Size(2560, 1080),
      const GamePage(mode: GameMode.endless),
      platform: TargetPlatform.windows,
    );
    final board = tester.getCenter(find.byKey(const ValueKey('tetris-board')));
    expect(board.dx, closeTo(1280, 40));
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });

  testWidgets('纪录页在手机上完整滚动且不溢出', (tester) async {
    await pumpAt(tester, const Size(360, 720), const RecordsPage());
    expect(find.text('本地纪录'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await dispose(tester);
  });
}
