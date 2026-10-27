import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'layout_helpers.dart';

/// 横屏布局：棋盘严格居中，信息列在左、控制区在右。
///
/// 左右两侧用同样的宽度，棋盘才能落在页面正中间。
class LandscapeLayout extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;

  /// 棋盘占位槽位；真正的棋盘由铺满整页的 Flame 画布绘制。
  final Widget boardSlot;

  /// 叠加在棋盘顶部的开局提示（数秒后自行淡出）。
  final Widget? hint;

  /// 左右 HUD 区宽度（与方向键簇宽度一致）。
  static const double _sideWidth = 176;

  /// 侧栏与棋盘之间的留白。
  static const double _gap = 8;

  const LandscapeLayout({
    super.key,
    required this.game,
    required this.boardSlot,
    this.controlMode = ControlMode.both,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = game.state.width / game.state.height;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final maxHeightByWidth =
            (size.width - _sideWidth * 2 - _gap * 2) / ratio;
        final boardHeight = math.max(
          0.0,
          math.min(size.height - 24, maxHeightByWidth),
        );
        final boardWidth = boardHeight * ratio;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _sideWidth,
              child: Center(
                child: IgnorePointer(
                  child: Consumer<GameProvider>(
                    builder: (context, provider, _) =>
                        CompactInfoColumn(state: provider.state),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: boardWidth,
                  height: boardHeight,
                  child: Stack(
                    children: [
                      boardSlot,
                      if (hint != null)
                        Positioned(top: 8, left: 8, right: 8, child: hint!),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            SizedBox(
              width: _sideWidth,
              child: Center(
                child: ControlArea(game: game, controlMode: controlMode),
              ),
            ),
          ],
        );
      },
    );
  }
}
