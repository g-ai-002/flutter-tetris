import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SoundMenu extends StatelessWidget {
  const SoundMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return PopupMenuButton<String>(
      icon: Icon(settings.soundEnabled ? Icons.volume_up : Icons.volume_off),
      tooltip: '音效设置',
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text(
            '音效设置',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'sound',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(settings.soundEnabled ? Icons.music_note : Icons.music_off, size: 20),
              const SizedBox(width: 8),
              Text(settings.soundEnabled ? '关闭音效' : '开启音效'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'music',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(settings.musicEnabled ? Icons.library_music : Icons.library_music_outlined, size: 20),
              const SizedBox(width: 8),
              Text(settings.musicEnabled ? '关闭音乐' : '开启音乐'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'sound') {
          settings.setSoundEnabled(!settings.soundEnabled);
        } else if (value == 'music') {
          settings.setMusicEnabled(!settings.musicEnabled);
        }
      },
    );
  }
}
