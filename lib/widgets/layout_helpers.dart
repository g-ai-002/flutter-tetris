import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'game_controls.dart';
import 'next_piece_preview.dart';
import 'score_panel.dart';

/// 竖屏顶部紧凑信息条：单行展示分数统计，右侧附带小尺寸下一个方块预览。
class CompactInfoBar extends StatelessWidget {
  final GameState state;

  const CompactInfoBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: ScorePanel(state: state)),
        if (state.nextPiece != null) ...[
          const SizedBox(width: 10),
          NextPiecePreview(state: state, size: 40),
        ],
      ],
    );
  }
}

/// 横屏左侧紧凑信息列：窄列展示分数统计与下一个方块预览。
class CompactInfoColumn extends StatelessWidget {
  final GameState state;
  final double width;

  const CompactInfoColumn({super.key, required this.state, this.width = 100});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScorePanel(state: state),
          if (state.nextPiece != null) ...[
            const SizedBox(height: 8),
            NextPiecePreview(state: state, size: 56),
          ],
        ],
      ),
    );
  }
}

class ControlArea extends StatelessWidget {
  final GameProvider game;
  final ControlMode controlMode;

  /// 为 true 时虚拟按键横向单行排布（竖屏紧凑布局）。
  final bool compactControls;

  const ControlArea({
    super.key,
    required this.game,
    this.controlMode = ControlMode.both,
    this.compactControls = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        final showButtons = controlMode != ControlMode.gesture;
        final showHint = controlMode != ControlMode.buttons;
        final playing = !state.isGameOver && !state.isPaused;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (playing && showButtons)
              GameControls(game: provider, singleRow: compactControls),
            if (playing && showHint)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '点击/上滑旋转 · 左右滑动移动 · 下滑硬降',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }
}
