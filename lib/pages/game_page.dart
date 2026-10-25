import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/tetris_game.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/board_slot.dart';
import '../widgets/game_board.dart';
import '../widgets/landscape_layout.dart';
import '../widgets/portrait_layout.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final GlobalKey _pageKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();
  TetrisGame? _game;
  Brightness? _brightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    final provider = context.read<GameProvider>();
    if (_game != null &&
        _brightness == brightness &&
        _game!.provider == provider) {
      return;
    }

    _brightness = brightness;
    final colors = Theme.of(context).colorScheme;
    _game = TetrisGame(
      provider: provider,
      surfaceColor: colors.surface,
      gridColor: colors.outline.withValues(alpha: 0.22),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleBoardRect(Rect rect) {
    final game = _game;
    final pageBox = _pageKey.currentContext?.findRenderObject();
    if (game == null || pageBox is! RenderBox || !pageBox.hasSize) {
      return;
    }
    game.updateBoardLayout(boardRect: rect, canvasSize: pageBox.size);
  }

  @override
  Widget build(BuildContext context) {
    final controlMode = context.watch<SettingsProvider>().controlMode;
    final provider = context.read<GameProvider>();
    final tetris = _game;
    if (tetris == null) {
      return const Scaffold();
    }
    tetris.gesturesEnabled = controlMode != ControlMode.buttons;

    return Scaffold(
      appBar: AppBar(
        title: Consumer<GameProvider>(
          builder: (context, provider, _) => Text(
            '${AppConstants.appName} - ${provider.state.gameMode.label}',
          ),
        ),
        actions: [
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              final paused = provider.state.isPaused;
              return IconButton(
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
                tooltip: paused ? '继续' : '暂停',
                onPressed: () {
                  provider.togglePause();
                  _focusNode.requestFocus();
                },
              );
            },
          ),
        ],
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _focusNode.requestFocus(),
        child: Stack(
          key: _pageKey,
          children: [
            // Flame 画布铺满整个游戏页，棋盘由相机对齐到下面的槽位。
            Positioned.fill(
              child: GameBoard(
                game: tetris,
                gameProvider: provider,
                focusNode: _focusNode,
              ),
            ),
            // HUD 悬浮在画布之上；不接收点击的区域放行给 Flame 手势。
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final boardSlot = BoardSlot(
                    pageKey: _pageKey,
                    onRect: _handleBoardRect,
                  );
                  return isLandscape
                      ? LandscapeLayout(
                          game: provider,
                          controlMode: controlMode,
                          boardSlot: boardSlot,
                        )
                      : PortraitLayout(
                          game: provider,
                          controlMode: controlMode,
                          boardSlot: boardSlot,
                        );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
