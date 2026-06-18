import 'package:flutter/material.dart';
import '../providers/game_provider.dart';

class GameControls extends StatelessWidget {
  final GameProvider game;
  const GameControls({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
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
