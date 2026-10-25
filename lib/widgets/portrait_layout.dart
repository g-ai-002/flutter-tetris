import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'layout_helpers.dart';

class PortraitLayout extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;

  /// 棋盘占位槽位；真正的棋盘由铺满整页的 Flame 画布绘制。
  final Widget boardSlot;

  const PortraitLayout({
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: [
          Consumer<GameProvider>(
            builder: (context, provider, _) => IgnorePointer(
              child: CompactInfoBar(state: provider.state),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AspectRatio(
                aspectRatio: width / height,
                child: boardSlot,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ControlArea(
            game: game,
            controlMode: controlMode,
            compactControls: true,
          ),
        ],
      ),
    );
  }
}
