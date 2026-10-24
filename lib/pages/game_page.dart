import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../widgets/landscape_layout.dart';
import '../widgets/portrait_layout.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final FocusNode _focusNode = FocusNode();

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
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controlMode = context.watch<SettingsProvider>().controlMode;
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        final state = game.state;
        return Scaffold(
          appBar: AppBar(
            title: Text('${AppConstants.appName} - ${state.gameMode.label}'),
            actions: [
              IconButton(
                icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
                tooltip: state.isPaused ? '继续' : '暂停',
                onPressed: () {
                  game.togglePause();
                  _focusNode.requestFocus();
                },
              ),
            ],
          ),
          body: SafeArea(
            // 点击任意位置夺回键盘焦点；键盘事件由 TetrisGame 处理。
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _focusNode.requestFocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      constraints.maxWidth > constraints.maxHeight;
                  return isLandscape
                      ? LandscapeLayout(
                          game: game,
                          state: state,
                          controlMode: controlMode,
                          focusNode: _focusNode,
                        )
                      : PortraitLayout(
                          game: game,
                          state: state,
                          controlMode: controlMode,
                          focusNode: _focusNode,
                        );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
