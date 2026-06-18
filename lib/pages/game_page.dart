import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/board_painter.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final state = game.state;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppConstants.appName),
            actions: [
              IconButton(
                icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
                tooltip: state.isPaused ? '继续' : '暂停',
                onPressed: () => game.togglePause(),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape = constraints.maxWidth > constraints.maxHeight;
                if (isLandscape) {
                  return _buildLandscape(context, game, state, constraints);
                }
                return _buildPortrait(context, game, state, constraints);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    GameProvider game,
    GameState state,
    BoxConstraints constraints,
  ) {
    final maxBoardHeight = constraints.maxHeight - 200;
    final maxBoardWidth = constraints.maxWidth - 32;
    final cellSize = min(
      maxBoardWidth / state.width,
      maxBoardHeight / state.height,
    );
    final boardW = cellSize * state.width;
    final boardH = cellSize * state.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildScorePanel(state),
          const SizedBox(height: 8),
          _buildNextPiece(state),
          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () {
                if (state.isGameOver) {
                  game.start();
                }
              },
              child: Container(
                width: boardW,
                height: boardH,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CustomPaint(
                    painter: BoardPainter(state: state, cellSize: cellSize),
                  ),
                ),
              ),
            ),
          ),
          if (state.isGameOver)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => game.start(),
                icon: const Icon(Icons.replay),
                label: const Text('重新开始'),
              ),
            ),
          if (state.isPaused && !state.isGameOver)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '已暂停',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          const SizedBox(height: 8),
          _buildControls(game, state),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    GameProvider game,
    GameState state,
    BoxConstraints constraints,
  ) {
    final maxBoardHeight = constraints.maxHeight - 16;
    final cellSize = maxBoardHeight / state.height;
    final boardW = cellSize * state.width;

    return Row(
      children: [
        const SizedBox(width: 8),
        // 左侧信息面板
        SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScorePanel(state),
              const SizedBox(height: 16),
              _buildNextPiece(state),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 游戏面板
        GestureDetector(
          onTap: () {
            if (state.isGameOver) game.start();
          },
          child: Container(
            width: boardW,
            height: maxBoardHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                painter: BoardPainter(state: state, cellSize: cellSize),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 右侧控制
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isGameOver)
                ElevatedButton.icon(
                  onPressed: () => game.start(),
                  icon: const Icon(Icons.replay),
                  label: const Text('重新开始'),
                )
              else if (state.isPaused)
                Text(
                  '已暂停',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                _buildControls(game, state),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildScorePanel(GameState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _scoreItem('分数', state.score.toString()),
            const SizedBox(width: 24),
            _scoreItem('等级', state.level.toString()),
            const SizedBox(width: 24),
            _scoreItem('行数', state.linesCleared.toString()),
            const SizedBox(width: 24),
            _scoreItem('最高', state.highScore.toString()),
          ],
        ),
      ),
    );
  }

  Widget _scoreItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNextPiece(GameState state) {
    if (state.nextPiece == null) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('下一个', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: NextPiecePainter(piece: state.nextPiece!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(GameProvider game, GameState state) {
    if (state.isGameOver) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _controlButton(Icons.keyboard_arrow_up, '旋转', () => game.rotate()),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _controlButton(Icons.keyboard_arrow_left, '左移', () => game.moveLeft()),
            const SizedBox(width: 16),
            _controlButton(Icons.keyboard_arrow_down, '下移', () => game.moveDown()),
            const SizedBox(width: 16),
            _controlButton(Icons.keyboard_arrow_right, '右移', () => game.moveRight()),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _controlButton(Icons.keyboard_double_arrow_down, '硬降', () => game.hardDrop()),
          ],
        ),
      ],
    );
  }

  Widget _controlButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: 56,
      height: 56,
      child: IconButton(
        icon: Icon(icon, size: 28),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }
}
