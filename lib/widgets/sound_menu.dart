import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/sound_service.dart';

class SoundMenu extends StatefulWidget {
  const SoundMenu({super.key});

  @override
  State<SoundMenu> createState() => _SoundMenuState();
}

class _SoundMenuState extends State<SoundMenu> {
  final SoundService _sound = SoundService();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(_sound.soundEnabled ? Icons.volume_up : Icons.volume_off),
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
              Icon(_sound.soundEnabled ? Icons.music_note : Icons.music_off, size: 20),
              const SizedBox(width: 8),
              Text(_sound.soundEnabled ? '关闭音效' : '开启音效'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'music',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_sound.musicEnabled ? Icons.library_music : Icons.library_music_outlined, size: 20),
              const SizedBox(width: 8),
              Text(_sound.musicEnabled ? '关闭音乐' : '开启音乐'),
            ],
          ),
        ),
      ],
      onSelected: (value) async {
        final prefs = await SharedPreferences.getInstance();
        if (value == 'sound') {
          await _sound.setSoundEnabled(!_sound.soundEnabled, prefs);
        } else if (value == 'music') {
          await _sound.setMusicEnabled(!_sound.musicEnabled, prefs);
        }
        setState(() {});
      },
    );
  }
}
