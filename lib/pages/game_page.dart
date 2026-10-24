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
    final game = context.read<GameProvider>();
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
                      controlMode: controlMode,
                      focusNode: _focusNode,
                    )
                  : PortraitLayout(
                      game: game,
                      controlMode: controlMode,
                      focusNode: _focusNode,
                    );
            },
          ),
        ),
      ),
    );
  }
}
