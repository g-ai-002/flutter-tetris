import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../flame/playfield_component.dart';
import '../flame/tetris_game.dart';
import '../game/daily_challenge.dart';
import '../game/game_mode.dart';
import '../game/level.dart';
import '../game/tetris_controller.dart';
import '../input/gamepad_input.dart';
import '../input/key_bindings.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/block_palette.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/game_display.dart';
import '../utils/game_layout.dart';
import '../utils/platform_info.dart';
import 'widgets/board_gestures.dart';
import 'widgets/board_stage.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_hud.dart';
import 'widgets/game_rails.dart';
import 'widgets/touch_pad.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.mode, this.level, this.daily});

  final GameMode mode;

  /// 关卡模式下要挑战的关卡。
  final LevelDefinition? level;

  /// 每日挑战的日期，决定本局的固定种子。
  final DailyChallenge? daily;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final TetrisController _controller;
  late final TetrisGame _game;
  late final GamepadService _gamepad;
  final FocusNode _focusNode = FocusNode(debugLabel: 'tetris-input');

  bool _resultShown = false;
  bool _pauseDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final settings = context.read<SettingsProvider>();
    _controller = TetrisController(
      mode: widget.mode,
      level: widget.level,
      daily: widget.daily,
      tickInterval: AppConstants.logicInterval(settings.logicRate),
    );
    _game = TetrisGame(
      controller: _controller,
      style: PlayfieldStyle(
        palette: settings.blockSkin.palette(dark: settings.darkMode),
      ),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
    _gamepad = GamepadService(onAction: _handleAction);
    unawaited(_gamepad.start());
    LogService.info(
      '开始对局: ${_controller.rules.title}, 逻辑 ${settings.logicRate}Hz',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(enterGameDisplay(size: MediaQuery.sizeOf(context)));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_controller.isPlaying) _controller.pause();
    } else if (state == AppLifecycleState.resumed && mounted) {
      // 系统栏可能在后台被还原，回到前台重新进入沉浸模式。
      unawaited(enterGameDisplay(size: MediaQuery.sizeOf(context)));
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;
    for (final event in _controller.drainEvents()) {
      _playFeedback(event);
    }
    final result = _controller.result;
    if (result != null && !_resultShown) {
      _resultShown = true;
      unawaited(_finishGame(result));
    }
  }

  void _playFeedback(GameEvent event) {
    final sfx = switch (event) {
      GameEvent.move => Sfx.move,
      GameEvent.rotate => Sfx.rotate,
      GameEvent.hold => Sfx.hold,
      GameEvent.lock => Sfx.lock,
      GameEvent.lineClear => Sfx.lineClear,
      GameEvent.tetris => Sfx.tetris,
      GameEvent.perfectClear => Sfx.perfectClear,
      GameEvent.levelUp => Sfx.levelUp,
      GameEvent.gameOver => Sfx.gameOver,
      GameEvent.win => Sfx.win,
    };
    SoundService.play(sfx);
  }

  Future<void> _finishGame(GameResult result) async {
    final storage = await StorageService.instance;
    final outcome = await storage.recordResult(result);
    LogService.info(
      '对局结束: ${_controller.rules.title}, '
      '得分 ${result.score}, 消行 ${result.lines}, 等级 ${result.level}, '
      '用时 ${result.elapsed.inMilliseconds}ms, ${result.reason}'
      '${outcome.isRecord ? '（新纪录）' : ''}',
    );
    if (!mounted) return;
    context.read<SettingsProvider>().refresh();
    final level = widget.level;
    final daily = widget.daily;
    final next = level == null ? null : nextLevelOf(level);
    final bestScore = level != null
        ? storage.levelRecord(level.id).bestScore
        : daily != null
        ? storage.dailyRecord(daily.key).bestScore
        : storage.bestScore(result.mode);
    _game.pauseEngine();
    await showGameResultDialog(
      context,
      result: result,
      outcome: outcome,
      bestScore: bestScore,
      level: level,
      daily: daily,
      hasNext: next != null,
      onRestart: _restart,
      onNext: next == null ? null : () => _startLevel(next),
      onExit: _exit,
    );
    if (mounted) _focusNode.requestFocus();
  }

  void _startLevel(LevelDefinition next) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(mode: GameMode.level, level: next),
      ),
    );
  }

  void _restart() {
    _resultShown = false;
    _pauseDialogOpen = false;
    _controller.restart();
    LogService.info('重新开始: ${_controller.rules.title}');
    _game.resumeEngine();
    _focusNode.requestFocus();
  }

  void _exit() {
    if (mounted) Navigator.of(context).pop();
  }

  void _togglePause() {
    if (_pauseDialogOpen || _controller.isOver) return;
    if (_controller.isPaused) {
      _controller.resume();
      _game.resumeEngine();
      _focusNode.requestFocus();
    } else {
      unawaited(_openPause());
    }
  }

  Future<void> _openPause() async {
    if (!_controller.isPlaying || _pauseDialogOpen) return;
    _controller.pause();
    _game.pauseEngine();
    _pauseDialogOpen = true;
    await showPauseDialog(
      context,
      controller: _controller,
      onRestart: _restart,
      onExit: _exit,
    );
    _pauseDialogOpen = false;
    if (mounted && _controller.isPaused) _controller.resume();
    if (mounted) _game.resumeEngine();
    _focusNode.requestFocus();
  }

  Future<void> _openHelp() async {
    final wasPlaying = _controller.isPlaying;
    if (wasPlaying) {
      _controller.pause();
      _game.pauseEngine();
    }
    await showHelpDialog(context);
    if (mounted && wasPlaying && _controller.isPaused) {
      _controller.resume();
      _game.resumeEngine();
    }
    _focusNode.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final action = context.read<SettingsProvider>().keyBindings.actionFor(
      event.logicalKey,
    );
    if (action == null) return KeyEventResult.ignored;
    if (!action.repeatable && event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    _handleAction(action);
    return KeyEventResult.handled;
  }

  void _handleAction(GameAction action) {
    if (_pauseDialogOpen || _controller.isOver) return;
    switch (action) {
      case GameAction.moveLeft:
        _controller.moveLeft();
      case GameAction.moveRight:
        _controller.moveRight();
      case GameAction.softDrop:
        _controller.softDrop();
      case GameAction.hardDrop:
        _controller.hardDrop();
      case GameAction.rotateClockwise:
        _controller.rotateClockwise();
      case GameAction.rotateCounterClockwise:
        _controller.rotateCounterClockwise();
      case GameAction.hold:
        _controller.hold();
      case GameAction.pause:
        unawaited(_openPause());
      case GameAction.restart:
        _restart();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    unawaited(_gamepad.stop());
    unawaited(exitGameDisplay());
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final darkness = Theme.of(context).brightness == Brightness.dark;
    final palette = settings.blockSkin.palette(dark: darkness);
    final bindings = settings.keyBindings;
    _game.style = PlayfieldStyle(
      palette: palette,
      showGhost: settings.showGhost && _controller.rules.ghostEnabled,
      showGrid: settings.showGrid,
    );
    final size = MediaQuery.sizeOf(context);
    final layout = GameLayout.of(size);
    final short = layout.isShort(size);

    return Focus(
      key: const ValueKey('game-focus'),
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: layout.usesSidePads ? null : _appBar(short),
        body: SafeArea(
          child: switch (layout.kind) {
            GameLayoutKind.rails => _buildRails(palette, bindings, size),
            GameLayoutKind.sidePads => _buildSidePads(palette, size),
            GameLayoutKind.stack => _buildStack(palette, bindings, size),
          },
        ),
      ),
    );
  }

  /// 顶部栏：矮窗口收起副标题，只留玩法名与操作按钮。
  PreferredSizeWidget _appBar(bool short) {
    final theme = Theme.of(context);
    return AppBar(
      toolbarHeight: short ? 46 : 58,
      title: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _controller.rules.title,
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
          onPressed: () => unawaited(_openHelp()),
          icon: const Icon(Icons.help_outline, size: 21),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => IconButton(
            tooltip: _controller.isPaused ? '继续' : '暂停',
            onPressed: _controller.isOver ? null : _togglePause,
            icon: Icon(
              _controller.isPaused
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
    switch (widget.mode) {
      case GameMode.endless:
        return '第 ${_controller.level} 级 · 每 10 行提速';
      case GameMode.sprint:
        return '${_controller.lines} / 40 行 · 第 ${_controller.level} 级';
      case GameMode.ultra:
        return '剩余 ${formatDuration(_controller.remaining.inMilliseconds)}';
      case GameMode.arcade:
        return '第 ${_controller.level} 级 · 街机计分';
      case GameMode.level:
        final target = _controller.targetLines ?? 0;
        final garbage = _controller.garbageSecondsLeft;
        return '${_controller.lines} / $target 行 · '
            '剩余 ${formatDuration(_controller.remaining.inMilliseconds)}'
            '${garbage == null ? '' : ' · 垃圾行 $garbage 秒'}';
      case GameMode.daily:
        return '剩余 ${formatDuration(_controller.remaining.inMilliseconds)}'
            ' · 固定牌序';
    }
  }

  Widget _buildBoard(BlockPalette palette) {
    return RepaintBoundary(
      child: BoardGestureLayer(
        controller: _controller,
        child: BoardStage(
          game: _game,
          gameKey: const ValueKey('tetris-board'),
          palette: palette,
        ),
      ),
    );
  }

  /// 对局 HUD 与操作区随控制器每一帧刷新。
  Widget _bound(Widget Function() builder) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => builder(),
  );

  Widget _sized(double width, Widget Function() build) =>
      SizedBox(width: width, child: _bound(build));

  /// 底部输入区：桌面显示键位提示，移动端显示触控键。
  Widget _inputBar(KeyBindings bindings, {bool dense = false}) =>
      isDesktopPlatform
      ? GameKeyboardHint(
          bindings: bindings,
          showHold: _controller.rules.holdEnabled,
        )
      : _bound(() => TouchPad(controller: _controller, dense: dense));

  /// 桌面与平板的宽屏版式：左右信息栏夹住棋盘，超宽窗口收敛到 1160 像素。
  Widget _buildRails(
    BlockPalette palette,
    KeyBindings bindings,
    Size size,
  ) {
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
                        controller: _controller,
                        palette: palette,
                        bindings: bindings,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: _buildBoard(palette)),
                    const SizedBox(width: 16),
                    _sized(
                      rail - 8,
                      () => GameRightRail(
                        controller: _controller,
                        palette: palette,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _inputBar(bindings),
      ],
    );
  }

  /// 手机横屏版式：状态条压到 38 像素，左右两侧承担信息与操作，棋盘独占高度。
  Widget _buildSidePads(BlockPalette palette, Size size) {
    final rail = (size.width * 0.075).clamp(58.0, 76.0);
    final pad = (size.width * 0.22).clamp(150.0, 220.0);
    return Column(
      children: [
        _bound(
          () => GameHudBar(
            controller: _controller,
            onBack: _exit,
            onHelp: () => unawaited(_openHelp()),
            onPause: _togglePause,
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
                    controller: _controller,
                    palette: palette,
                    width: rail,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _buildBoard(palette)),
                const SizedBox(width: 10),
                SizedBox(
                  width: pad,
                  child: Center(
                    child: _bound(
                      () => TouchPad(
                        controller: _controller,
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
  Widget _buildStack(
    BlockPalette palette,
    KeyBindings bindings,
    Size size,
  ) {
    final short = size.height < 620;
    final rail = size.width >= 600 ? 76.0 : (size.width < 360 ? 52.0 : 58.0);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14, short ? 0 : 2, 14, short ? 4 : 8),
          child: _bound(() => GameHud(controller: _controller, compact: true)),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(child: _buildBoard(palette)),
                const SizedBox(width: 6),
                _sized(
                  rail,
                  () => GameCompactRail(
                    controller: _controller,
                    palette: palette,
                    width: rail,
                  ),
                ),
              ],
            ),
          ),
        ),
        _inputBar(bindings, dense: short),
      ],
    );
  }
}
