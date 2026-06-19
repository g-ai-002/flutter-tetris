import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tetris/providers/game_provider.dart';
import 'package:flutter_tetris/services/history_service.dart';
import 'package:flutter_tetris/services/sound_service.dart';
import 'package:flutter_tetris/widgets/status_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatusOverlay', () {
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
          child: StatusOverlay(
            game: provider,
            isGameOver: provider.state.isGameOver,
            isPaused: provider.state.isPaused,
          ),
        ),
      );
    }

    testWidgets('shows nothing when playing', (tester) async {
      final provider = await _createProvider();
      await tester.pumpWidget(buildTestApp(provider));
      expect(find.text('重新开始'), findsNothing);
      expect(find.text('已暂停'), findsNothing);
    });

    testWidgets('shows restart button when game over', (tester) async {
      final provider = await _createProvider();
      for (var i = 0; i < 500; i++) {
        if (provider.state.isGameOver) break;
        provider.hardDrop();
      }
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();
      expect(find.text('重新开始'), findsOneWidget);
    });

    testWidgets('shows paused text when paused', (tester) async {
      final provider = await _createProvider();
      provider.togglePause();
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();
      expect(find.text('已暂停'), findsOneWidget);
    });

    testWidgets('restart button triggers game start', (tester) async {
      final provider = await _createProvider();
      for (var i = 0; i < 500; i++) {
        if (provider.state.isGameOver) break;
        provider.hardDrop();
      }
      await tester.pumpWidget(buildTestApp(provider));
      await tester.pump();
      expect(provider.state.isGameOver, true);
      await tester.tap(find.text('重新开始'));
      await tester.pump();
      expect(provider.state.isGameOver, false);
      provider.dispose();
    });
  });
}
