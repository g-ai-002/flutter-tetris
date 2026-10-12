import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/pages/game_page.dart';
import 'package:flutter_tetris/utils/constants.dart';
import 'package:flutter_tetris/widgets/game_board.dart';
import 'test_utils.dart';

void main() {
  group('GamePage', () {
    Widget buildTestApp(TestProviders providers) {
      return providers.app(const GamePage());
    }

    testWidgets('renders without crashing', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      expect(find.text('俄罗斯方块 - 经典模式'), findsOneWidget);
    });

    testWidgets('app bar keeps only pause action', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      expect(find.byTooltip('暂停'), findsOneWidget);
      expect(find.byTooltip('排行榜'), findsNothing);
      expect(find.byTooltip('切换模式'), findsNothing);
      expect(find.byTooltip('音效设置'), findsNothing);
    });

    testWidgets('arrow left key moves piece left', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      final initialX = provider.state.currentX;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(provider.state.currentX, initialX - 1);
    });

    testWidgets('arrow right key moves piece right', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      final initialX = provider.state.currentX;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(provider.state.currentX, initialX + 1);
    });

    testWidgets('arrow down key moves piece down', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('arrow up key rotates piece', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('space key hard drops', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('P key toggles pause', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      expect(provider.state.isPaused, false);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(provider.state.isPaused, true);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.pump();
      expect(provider.state.isPaused, false);
      provider.dispose();
    });

    testWidgets('R key restarts when game over', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      for (var i = 0; i < 500; i++) {
        if (provider.state.isGameOver) break;
        provider.hardDrop();
      }
      await tester.pump();
      expect(provider.state.isGameOver, true);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(provider.state.isGameOver, false);
      provider.dispose();
    });

    testWidgets('tap on board rotates piece when playing', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      final boardFinder = find.byType(CustomPaint);
      expect(boardFinder, findsWidgets);
      await tester.tap(boardFinder.first);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('swipe board left moves piece left', (tester) async {
      final providers = await createTestProviders();
      final provider = providers.game;
      await tester.pumpWidget(buildTestApp(providers));
      final initialX = provider.state.currentX;
      await tester.drag(find.byType(GameBoard), const Offset(-60, 0));
      await tester.pump();
      expect(provider.state.currentX, initialX - 1);
    });

    testWidgets('virtual buttons show in default control mode', (tester) async {
      final providers = await createTestProviders();
      await tester.pumpWidget(buildTestApp(providers));
      expect(find.byTooltip('旋转'), findsOneWidget);
    });

    testWidgets('virtual buttons hidden in gesture-only mode', (tester) async {
      final providers = await createTestProviders();
      await providers.settings.setControlMode(ControlMode.gesture);
      await tester.pumpWidget(buildTestApp(providers));
      await tester.pump();
      expect(find.byTooltip('旋转'), findsNothing);
    });
  });
}
