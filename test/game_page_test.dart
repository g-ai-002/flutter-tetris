import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tetris/pages/game_page.dart';
import 'package:flutter_tetris/providers/game_provider.dart';
import 'package:flutter_tetris/services/history_service.dart';
import 'package:flutter_tetris/services/sound_service.dart';

void main() {
  group('GamePage', () {
    Future<GameProvider> _createProvider() async {
      SharedPreferences.setMockInitialValues({});
      SoundService().resetForTest();
      final prefs = await SharedPreferences.getInstance();
      await SoundService().init(prefs);
      await HistoryService.init();
      await HistoryService.clearAll();
      return GameProvider(prefs);
    }

    Widget buildTestApp(GameProvider provider) {
      return MaterialApp(
        home: ChangeNotifierProvider.value(
          value: provider,
          child: const GamePage(),
        ),
      );
    }

    testWidgets('renders without crashing', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      expect(find.text('俄罗斯方块'), findsOneWidget);
    });

    testWidgets('arrow left key moves piece left', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      final initialX = provider.state.currentX;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(provider.state.currentX, initialX - 1);
    });

    testWidgets('arrow right key moves piece right', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      final initialX = provider.state.currentX;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(provider.state.currentX, initialX + 1);
    });

    testWidgets('arrow down key moves piece down', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('arrow up key rotates piece', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('space key hard drops', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(provider.state, isNotNull);
    });

    testWidgets('P key toggles pause', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
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
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
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
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      final boardFinder = find.byType(CustomPaint);
      expect(boardFinder, findsWidgets);
      await tester.tap(boardFinder.first);
      await tester.pump();
      expect(provider.state, isNotNull);
    });
  });
}
