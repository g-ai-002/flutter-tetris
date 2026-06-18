import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import '../widgets/board_painter.dart';
import '../widgets/game_controls.dart';
import '../widgets/next_piece_preview.dart';
import '../widgets/score_panel.dart';

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
                return isLandscape
                    ? _LandscapeLayout(game: game, state: state, constraints: constraints)
                    : _PortraitLayout(game: game, state: state, constraints: constraints);
              },
            ),
          ),
        );
      },
    );
  }
}

class _PortraitLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final BoxConstraints constraints;

  const _PortraitLayout({
    required this.game,
    required this.state,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final maxBoardHeight = constraints.maxHeight - 200;
    final maxBoardWidth = constraints.maxWidth - 32;
    final cellSize = min(maxBoardWidth / state.width, maxBoardHeight / state.height);
    final boardW = cellSize * state.width;
    final boardH = cellSize * state.height;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          ScorePanel(state: state),
          const SizedBox(height: 8),
          NextPiecePreview(state: state),
          const SizedBox(height: 8),
          _buildBoard(context, game, state, boardW, boardH, cellSize),
          _buildStatusOverlay(context, game, state),
          const SizedBox(height: 8),
          if (!state.isGameOver) GameControls(game: game),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final GameState state;
  final BoxConstraints constraints;

  const _LandscapeLayout({
    required this.game,
    required this.state,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final maxBoardHeight = constraints.maxHeight - 16;
    final cellSize = maxBoardHeight / state.height;
    final boardW = cellSize * state.width;

    return Row(
      children: [
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScorePanel(state: state),
              const SizedBox(height: 16),
              NextPiecePreview(state: state),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildBoard(context, game, state, boardW, maxBoardHeight, cellSize),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isGameOver)
                _restartButton(game)
              else if (state.isPaused)
                _pausedText(context)
              else
                GameControls(game: game),
            ],
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

Widget _buildBoard(
  BuildContext context,
  GameProvider game,
  GameState state,
  double boardW,
  double boardH,
  double cellSize,
) {
  return GestureDetector(
    onTap: () {
      if (state.isGameOver) game.start();
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
  );
}

Widget _buildStatusOverlay(BuildContext context, GameProvider game, GameState state) {
  if (state.isGameOver) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _restartButton(game),
    );
  }
  if (state.isPaused) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _pausedText(context),
    );
  }
  return const SizedBox.shrink();
}

Widget _restartButton(GameProvider game) {
  return ElevatedButton.icon(
    onPressed: () => game.start(),
    icon: const Icon(Icons.replay),
    label: const Text('重新开始'),
  );
}

Widget _pausedText(BuildContext context) {
  return Text(
    '已暂停',
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
  );
}
