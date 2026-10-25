import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'layout_helpers.dart';

class LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;

  /// 棋盘占位槽位；真正的棋盘由铺满整页的 Flame 画布绘制。
  final Widget boardSlot;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.boardSlot,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    final width = game.state.width;
    final height = game.state.height;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Consumer<GameProvider>(
            builder: (context, provider, _) => IgnorePointer(
              child: CompactInfoColumn(state: provider.state),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AspectRatio(
                aspectRatio: width / height,
                child: boardSlot,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ControlArea(game: game, controlMode: controlMode),
        ],
      ),
    );
  }
}
