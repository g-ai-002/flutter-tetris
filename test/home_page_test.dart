import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/pages/home_page.dart';
import 'test_utils.dart';

void main() {
  group('HomePage', () {
    Widget buildTestApp(TestProviders providers) {
      return MaterialApp(home: providers.wrap(const HomePage()));
    }

    testWidgets('renders menu entries and high score', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      expect(find.text('开始游戏'), findsOneWidget);
      expect(find.text('选择模式'), findsOneWidget);
      expect(find.text('排行榜'), findsOneWidget);
      expect(find.text('最高分: 0'), findsOneWidget);
    });

    testWidgets('start button enters and starts the game', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      await tester.tap(find.text('开始游戏'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('俄罗斯方块 - 经典模式'), findsOneWidget);
      providers.game.dispose();
    });

    testWidgets('mode button opens the mode select page', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      await tester.tap(find.text('选择模式'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('选择游戏模式'), findsOneWidget);
      providers.game.dispose();
    });

    testWidgets('settings button opens the settings page', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      await tester.tap(find.byTooltip('设置'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('操控方式'), findsOneWidget);
      providers.game.dispose();
    });

    testWidgets('dark mode toggle updates settings', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      expect(providers.settings.darkMode, false);
      await tester.tap(find.byTooltip('切换深色模式'));
      await tester.pump();
      expect(providers.settings.darkMode, true);
    });
  });
}
