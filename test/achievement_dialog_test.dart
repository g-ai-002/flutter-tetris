import 'package:flutter/material.dart';
import 'package:flutter_tetris/game/achievement.dart';
import 'package:flutter_tetris/game/game_mode.dart';
import 'package:flutter_tetris/pages/widgets/game_dialogs.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('结算弹窗展示本局新解锁的成就', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final storage = await prepareStorage();

    await tester.pumpWidget(
      wrapPage(
        storage: storage,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => showGameResultDialog(
              context,
              result: const GameResult(
                mode: GameMode.endless,
                score: 1200,
                lines: 7,
                level: 1,
                pieces: 30,
                maxCombo: 5,
                elapsed: Duration(minutes: 1),
                won: false,
                reason: '方块堆到了顶部',
              ),
              outcome: const RecordOutcome(
                newBestScore: true,
                newBestTime: false,
                unlocked: [Achievement.firstGame, Achievement.tetris1],
              ),
              bestScore: 1200,
              onRestart: _noop,
              onExit: _noop,
            ),
            child: const Text('开始结算'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('开始结算'));
    await tester.pumpAndSettle();

    expect(find.text('新成就 · 初来乍到'), findsOneWidget);
    expect(find.text('新成就 · 四行齐消'), findsOneWidget);
    expect(find.text('新的最高分'), findsOneWidget);
    expect(find.text('游戏结束'), findsOneWidget);
  });
}

void _noop() {}
