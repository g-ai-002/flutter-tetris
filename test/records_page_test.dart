import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/daily_challenge.dart';
import 'package:flutter_tetris/pages/records_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('纪录页展示累计数据与各模式纪录', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = await prepareStorage({
      'games_played': 4,
      'total_lines': 128,
      'total_score': 56780,
      'best_score_endless': 12345,
      'best_lines_endless': 42,
      'plays_endless': 2,
      'best_score_sprint': 800,
      'best_lines_sprint': 40,
      'plays_sprint': 1,
      'best_sprint_time_ms': 95400,
      'best_score_ultra': 8900,
      'best_lines_ultra': 30,
      'plays_ultra': 1,
    });

    await tester.pumpWidget(
      wrapPage(child: const RecordsPage(), storage: storage),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('56,780'), findsOneWidget);
    expect(find.text('12,345'), findsOneWidget);
    expect(find.text('01:35.40'), findsOneWidget);
    expect(find.text('8,900'), findsOneWidget);
  });

  testWidgets('清空纪录后回到空状态', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = await prepareStorage({
      'games_played': 3,
      'total_lines': 20,
      'total_score': 3000,
      'best_score_endless': 1200,
      'best_lines_endless': 8,
      'plays_endless': 3,
    });

    await tester.pumpWidget(
      wrapPage(child: const RecordsPage(), storage: storage),
    );

    expect(find.text('1,200'), findsOneWidget);
    await tester.tap(find.byTooltip('清空纪录'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '清空'));
    await tester.pumpAndSettle();

    expect(storage.gamesPlayed, 0);
    expect(find.text('还没有对局记录，去玩一局吧。'), findsNWidgets(3));
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('纪录页展示每日挑战与七日记录', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final today = DailyChallenge.today();
    final yesterday = DailyChallenge.forDate(
      DateTime(today.date.year, today.date.month, today.date.day - 1),
    );
    final storage = await prepareStorage({
      'daily_records': jsonEncode({
        today.key: {'score': 5432, 'lines': 21, 'level': 3, 'plays': 2},
        yesterday.key: {'score': 3200, 'lines': 15, 'level': 2, 'plays': 1},
      }),
    });

    await tester.pumpWidget(
      wrapPage(child: const RecordsPage(), storage: storage),
    );

    expect(find.text('每日挑战'), findsOneWidget);
    expect(find.textContaining('今日最高 5,432 分'), findsOneWidget);
    expect(find.text('连续 2 天'), findsOneWidget);
    expect(find.text('今天 · ${today.weekdayLabel}'), findsOneWidget);
    expect(find.text('21 行 · 2 次'), findsOneWidget);
    expect(find.text('3,200 分'), findsOneWidget);
  });

  testWidgets('没有纪录时展示空提示且不显示清空按钮', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = await prepareStorage();

    await tester.pumpWidget(
      wrapPage(child: const RecordsPage(), storage: storage),
    );

    expect(find.text('还没有对局记录，去玩一局吧。'), findsNWidgets(3));
    expect(find.byTooltip('清空纪录'), findsNothing);
  });
}
