import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // 外观
          const _SectionHeader(title: '外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('切换深色/浅色主题'),
            value: settings.darkMode,
            onChanged: settings.setDarkMode,
            secondary: Icon(
              settings.darkMode ? Icons.dark_mode : Icons.light_mode,
              color: colorScheme.primary,
            ),
          ),
          const Divider(),
          // 音效
          const _SectionHeader(title: '音效'),
          SwitchListTile(
            title: const Text('游戏音效'),
            subtitle: const Text('移动、旋转、消行等提示音'),
            value: settings.soundEnabled,
            onChanged: settings.setSoundEnabled,
            secondary: Icon(
              settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
              color: colorScheme.primary,
            ),
          ),
          SwitchListTile(
            title: const Text('背景音乐'),
            subtitle: const Text('循环播放背景音乐'),
            value: settings.musicEnabled,
            onChanged: settings.setMusicEnabled,
            secondary: Icon(
              settings.musicEnabled ? Icons.library_music : Icons.library_music_outlined,
              color: colorScheme.primary,
            ),
          ),
          const Divider(),
          // 操控方式
          const _SectionHeader(title: '操控方式'),
          ...ControlMode.values.map((mode) {
            return RadioListTile<ControlMode>(
              title: Text(mode.label),
              subtitle: Text(mode.description),
              value: mode,
              groupValue: settings.controlMode,
              onChanged: (value) {
                if (value != null) settings.setControlMode(value);
              },
              secondary: Icon(Icons.touch_app, color: colorScheme.primary),
            );
          }),
          const Divider(),
          // 关于
          const _SectionHeader(title: '关于'),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: const Text('版本'),
            trailing: const Text(AppConstants.version),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
