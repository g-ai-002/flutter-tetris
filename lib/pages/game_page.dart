import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';
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
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final game = context.read<GameProvider>();
    final state = game.state;

    if (event.logicalKey == LogicalKeyboardKey.keyP) {
      game.togglePause();
      return KeyEventResult.handled;
    }
    if (state.isGameOver) {
      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        game.start();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (state.isPaused) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        game.moveLeft();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        game.moveRight();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        game.moveDown();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        game.rotate();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.space:
        game.hardDrop();
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Widget _buildSoundMenu() {
    final sound = SoundService();
    return PopupMenuButton<String>(
      icon: Icon(sound.soundEnabled ? Icons.volume_up : Icons.volume_off),
      tooltip: '音效设置',
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('音效设置', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ),
        PopupMenuItem(
          value: 'sound',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sound.soundEnabled ? Icons.music_note : Icons.music_off, size: 20),
              const SizedBox(width: 8),
              Text(sound.soundEnabled ? '关闭音效' : '开启音效'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'music',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sound.musicEnabled ? Icons.library_music : Icons.library_music_outlined, size: 20),
              const SizedBox(width: 8),
              Text(sound.musicEnabled ? '关闭音乐' : '开启音乐'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        final prefs = await SharedPreferences.getInstance();
        if (value == 'sound') {
          await sound.setSoundEnabled(!sound.soundEnabled, prefs);
        } else if (value == 'music') {
          await sound.setMusicEnabled(!sound.musicEnabled, prefs);
        }
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Consumer<GameProvider>(
        builder: (context, game, _) {
          final state = game.state;
          return Scaffold(
            appBar: AppBar(
              title: const Text(AppConstants.appName),
              actions: [
                _buildSoundMenu(),
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
                      ? LandscapeLayout(game: game, state: state, constraints: constraints)
                      : PortraitLayout(game: game, state: state, constraints: constraints);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
