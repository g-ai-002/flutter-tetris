import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import 'game_page.dart';
import 'history_page.dart';
import 'mode_select_page.dart';
import 'settings_page.dart';

/// 首页：应用入口，集中提供开始游戏、选择模式、排行榜与设置入口。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final game = context.read<GameProvider>();
    final highScore = context.select<GameProvider, int>((g) => g.state.highScore);
    final modeLabel = context.select<GameProvider, String>((g) => g.selectedMode.label);
    final darkMode = settings.darkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(darkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: darkMode ? '切换浅色模式' : '切换深色模式',
            onPressed: () => settings.setDarkMode(!darkMode),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '设置',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.widgets, size: 80, color: colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '经典街机游戏',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  '最高分: $highScore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '当前模式: $modeLabel  |  操控: ${settings.controlMode.label}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      game.start();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GamePage()),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始游戏', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ModeSelectPage()),
                      );
                    },
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Text('选择模式'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    },
                    icon: const Icon(Icons.emoji_events),
                    label: const Text('排行榜'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
