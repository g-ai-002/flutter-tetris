import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'layout_helpers.dart';

/// 竖屏布局：棋盘严格居中，信息条在上、控制区在下。
class PortraitLayout extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;

  /// 棋盘占位槽位；真正的棋盘由铺满整页的 Flame 画布绘制。
  final Widget boardSlot;

  /// 上下留给信息条/控制区的对称高度，保证棋盘居中后 HUD 不压到棋盘。
  static const double _reserve = 88;

  /// 棋盘与页面边缘、HUD 之间的留白。
  static const double _margin = 12;

  const PortraitLayout({
    super.key,
    required this.game,
    required this.boardSlot,
    this.controlMode = ControlMode.both,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = game.state.width / game.state.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final maxHeightByWidth = (size.width - _margin * 2) / ratio;
        final boardHeight = math.max(
          0.0,
          math.min(size.height - _reserve * 2, maxHeightByWidth),
        );
        final boardWidth = boardHeight * ratio;
        final boardTop = (size.height - boardHeight) / 2;
        final margin = boardTop;

        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: boardWidth,
                height: boardHeight,
                child: boardSlot,
              ),
            ),
            Positioned(
              top: math.max(4, margin - 56),
              left: 8,
              right: 8,
              child: IgnorePointer(
                child: Consumer<GameProvider>(
                  builder: (context, provider, _) =>
                      CompactInfoBar(state: provider.state),
                ),
              ),
            ),
            Positioned(
              top: boardTop + boardHeight + 12,
              left: 8,
              right: 8,
              child: ControlArea(
                game: game,
                controlMode: controlMode,
                compactControls: true,
              ),
            ),
          ],
        );
      },
    );
  }
}
