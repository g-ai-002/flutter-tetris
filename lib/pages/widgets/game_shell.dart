import 'package:flutter/material.dart';

import '../../flame/tetris_game.dart';
import '../../game/game_mode.dart';
import '../../game/tetris_controller.dart';
import '../../input/key_bindings.dart';
import '../../theme/block_palette.dart';
import '../../utils/formatters.dart';
import '../../utils/game_layout.dart';
import '../../utils/platform_info.dart';
import 'board_gestures.dart';
import 'board_stage.dart';
import 'game_hud.dart';
import 'game_rails.dart';
import 'touch_pad.dart';

/// 对局展示外壳：按窗口与平台选择版式，负责顶栏、棋盘、信息栏与操作区的排版。
/// 生命周期、输入与弹窗由对局页处理，这里只消费控制器状态。
class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.controller,
    required this.game,
    required this.palette,
    required this.bindings,
    required this.onExit,
    required this.onHelp,
    required this.onPause,
  });

  final TetrisController controller;
  final TetrisGame game;
  final BlockPalette palette;
  final KeyBindings bindings;
  final VoidCallback onExit;
  final VoidCallback onHelp;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = GameLayout.of(size);
    final short = layout.isShort(size);
    return Scaffold(
      appBar: layout.usesSidePads ? null : _appBar(context, short),
      body: SafeArea(
        child: switch (layout.kind) {
          GameLayoutKind.rails => _buildRails(size),
          GameLayoutKind.sidePads => _buildSidePads(size),
          GameLayoutKind.stack => _buildStack(size),
        },
      ),
    );
  }

  /// 顶部栏：矮窗口收起副标题，只留玩法名与操作按钮。
  PreferredSizeWidget _appBar(BuildContext context, bool short) {
    final theme = Theme.of(context);
    return AppBar(
      toolbarHeight: short ? 46 : 58,
      title: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.rules.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!short)
              Text(
                _subtitle(),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          tooltip: '玩法与操作',
          onPressed: onHelp,
          icon: const Icon(Icons.help_outline, size: 21),
        ),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) => IconButton(
            tooltip: controller.isPaused ? '继续' : '暂停',
            onPressed: controller.isOver ? null : onPause,
            icon: Icon(
              controller.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              size: 23,
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _subtitle() {
    switch (controller.mode) {
      case GameMode.endless:
        return '第 ${controller.level} 级 · 每 10 行提速';
      case GameMode.sprint:
        return '${controller.lines} / 40 行 · 第 ${controller.level} 级';
      case GameMode.ultra:
        return '剩余 ${formatDuration(controller.remaining.inMilliseconds)}';
      case GameMode.arcade:
        return '第 ${controller.level} 级 · 街机计分';
      case GameMode.level:
        final target = controller.targetLines ?? 0;
        final garbage = controller.garbageSecondsLeft;
        return '${controller.lines} / $target 行 · '
            '剩余 ${formatDuration(controller.remaining.inMilliseconds)}'
            '${garbage == null ? '' : ' · 垃圾行 $garbage 秒'}';
      case GameMode.daily:
        return '剩余 ${formatDuration(controller.remaining.inMilliseconds)}'
            ' · 固定牌序';
    }
  }

  Widget _buildBoard() {
    return RepaintBoundary(
      child: BoardGestureLayer(
        controller: controller,
        child: BoardStage(
          game: game,
          gameKey: const ValueKey('tetris-board'),
          palette: palette,
        ),
      ),
    );
  }

  /// 对局 HUD 与操作区随控制器每一帧刷新。
  Widget _bound(Widget Function() builder) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => builder(),
  );

  Widget _sized(double width, Widget Function() build) =>
      SizedBox(width: width, child: _bound(build));

  /// 底部输入区：桌面显示键位提示，移动端显示触控键。
  Widget _inputBar({bool dense = false}) => isDesktopPlatform
      ? GameKeyboardHint(
          bindings: bindings,
          showHold: controller.rules.holdEnabled,
        )
      : _bound(() => TouchPad(controller: controller, dense: dense));

  /// 桌面与平板的宽屏版式：左右信息栏夹住棋盘，超宽窗口收敛到 1160 像素。
  Widget _buildRails(Size size) {
    final rail = (size.width * 0.11).clamp(120.0, 176.0);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sized(
                      rail,
                      () => GameLeftRail(
                        controller: controller,
                        palette: palette,
                        bindings: bindings,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBoard()),
                    const SizedBox(width: 16),
                    _sized(
                      rail - 8,
                      () => GameRightRail(
                        controller: controller,
                        palette: palette,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _inputBar(),
      ],
    );
  }

  /// 手机横屏版式：状态条压到 38 像素，左右两侧承担信息与操作，棋盘独占高度。
  Widget _buildSidePads(Size size) {
    final rail = (size.width * 0.075).clamp(58.0, 76.0);
    final pad = (size.width * 0.22).clamp(150.0, 220.0);
    return Column(
      children: [
        _bound(
          () => GameHudBar(
            controller: controller,
            onBack: onExit,
            onHelp: onHelp,
            onPause: onPause,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _sized(
                  rail,
                  () => GameCompactRail(
                    controller: controller,
                    palette: palette,
                    width: rail,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildBoard()),
                const SizedBox(width: 10),
                SizedBox(
                  width: pad,
                  child: Center(
                    child: _bound(
                      () => TouchPad(
                        controller: controller,
                        dense: true,
                        columns: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 竖屏单列版式：数值在顶、棋盘中列、操作区贴底。
  Widget _buildStack(Size size) {
    final short = size.height < 620;
    final rail = size.width >= 600 ? 76.0 : (size.width < 360 ? 52.0 : 58.0);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, short ? 0 : 2, 14, short ? 4 : 8),
          child: _bound(() => GameHud(controller: controller, compact: true)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(child: _buildBoard()),
                const SizedBox(width: 6),
                _sized(
                  rail,
                  () => GameCompactRail(
                    controller: controller,
                    palette: palette,
                    width: rail,
                  ),
                ),
              ],
            ),
          ),
        ),
        _inputBar(dense: short),
      ],
    );
  }
}
