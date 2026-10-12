import 'package:flutter/material.dart';
import '../providers/game_provider.dart';

class GameControls extends StatelessWidget {
  final GameProvider game;

  /// 为 true 时横向单行排布（竖屏紧凑布局），否则为三行方向键簇（横屏）。
  final bool singleRow;

  const GameControls({super.key, required this.game, this.singleRow = false});

  static const double _buttonSize = 48;

  @override
  Widget build(BuildContext context) {
    final rotate = _controlButton(Icons.keyboard_arrow_up, '旋转', game.rotate);
    final left = _controlButton(Icons.keyboard_arrow_left, '左移', game.moveLeft);
    final down = _controlButton(Icons.keyboard_arrow_down, '下移', game.moveDown);
    final right =
        _controlButton(Icons.keyboard_arrow_right, '右移', game.moveRight);
    final hardDrop =
        _controlButton(Icons.keyboard_double_arrow_down, '硬降', game.hardDrop);

    if (singleRow) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          rotate,
          const SizedBox(width: 8),
          left,
          const SizedBox(width: 8),
          down,
          const SizedBox(width: 8),
          right,
          const SizedBox(width: 8),
          hardDrop,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [rotate]),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            left,
            const SizedBox(width: 12),
            down,
            const SizedBox(width: 12),
            right,
          ],
        ),
        const SizedBox(height: 6),
        Row(mainAxisSize: MainAxisSize.min, children: [hardDrop]),
      ],
    );
  }

  Widget _controlButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: IconButton(
        icon: Icon(icon, size: 24),
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
