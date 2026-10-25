import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/game/board_camera.dart';
import 'package:flutter_tetris/game/tetris_game.dart';

import 'test_utils.dart';

void main() {
  const worldBoard = Rect.fromLTWH(0, 0, 300, 600);

  group('相机布局', () {
    test('棋盘居中时的缩放与取景器位置', () {
      final layout = cameraLayoutForBoard(
        canvasSize: const Size(400, 800),
        boardRect: const Rect.fromLTWH(50, 100, 300, 600),
        worldBoardRect: worldBoard,
      );

      expect(layout.zoom, 1);
      expect(layout.position.x, 150);
      expect(layout.position.y, 300);
    });

    test('棋盘偏离画布中心时取景器反向偏移', () {
      final layout = cameraLayoutForBoard(
        canvasSize: const Size(400, 800),
        boardRect: const Rect.fromLTWH(50, 200, 300, 600),
        worldBoardRect: worldBoard,
      );

      expect(layout.zoom, 1);
      expect(layout.position.x, 150);
      expect(layout.position.y, 200);
    });
  });

  group('TetrisGame 画布手势', () {
    Future<TetrisGame> buildGame() async {
      final provider = await createTestProvider();
      return TetrisGame(
        provider: provider,
        surfaceColor: Colors.black,
        gridColor: Colors.white,
      );
    }

    test('棋盘槽位同步到相机', () async {
      final game = await buildGame();
      game.updateBoardLayout(
        boardRect: const Rect.fromLTWH(50, 100, 300, 600),
        canvasSize: const Size(400, 800),
      );

      expect(game.camera.viewfinder.zoom, 1);
      expect(game.camera.viewfinder.position.x, 150);
      expect(game.camera.viewfinder.position.y, 300);
    });

    test('棋盘以外的滑动也能移动方块', () async {
      final game = await buildGame();
      game.updateBoardLayout(
        boardRect: const Rect.fromLTWH(50, 100, 300, 600),
        canvasSize: const Size(400, 800),
      );
      final initialX = game.provider.state.currentX;

      game.handleSwipe(const Offset(-80, 0));

      expect(game.provider.state.currentX, initialX - 1);
    });

    test('下滑触发硬降', () async {
      final game = await buildGame();
      final boardBefore = game.provider.state.board;

      game.handleSwipe(const Offset(0, 80));

      final boardAfter = game.provider.state.board;
      expect(boardAfter, isNot(same(boardBefore)));
      expect(boardAfter.any((row) => row.any((value) => value != 0)), isTrue);
    });

    test('仅虚拟按键模式下忽略手势', () async {
      final game = await buildGame();
      game.gesturesEnabled = false;
      final initialX = game.provider.state.currentX;

      game.handleSwipe(const Offset(-80, 0));

      expect(game.provider.state.currentX, initialX);
    });

    test('结束后点击任意位置重新开局', () async {
      final game = await buildGame();
      for (var i = 0; i < 500; i++) {
        if (game.provider.state.isGameOver) {
          break;
        }
        game.provider.hardDrop();
      }
      expect(game.provider.state.isGameOver, isTrue);

      game.handleTap();

      expect(game.provider.state.isGameOver, isFalse);
    });
  });
}
