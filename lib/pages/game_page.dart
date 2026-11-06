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
import '../utils/formatters.dart';
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
    _controller = TetrisController(
      mode: widget.mode,
      level: widget.level,
      daily: widget.daily,
    );
    final settings = context.read<SettingsProvider>();
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
    LogService.info('开始对局: ${_controller.rules.title}');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (_controller.isPlaying) _controller.pause();
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
    _focusNode.requestFocus();
  }

  void _exit() {
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openPause() async {
    if (!_controller.isPlaying || _pauseDialogOpen) return;
    _controller.pause();
    _pauseDialogOpen = true;
    await showPauseDialog(
      context,
      controller: _controller,
      onRestart: _restart,
      onExit: _exit,
    );
    _pauseDialogOpen = false;
    if (mounted && _controller.isPaused) _controller.resume();
    _focusNode.requestFocus();
  }

  Future<void> _openHelp() async {
    final wasPlaying = _controller.isPlaying;
    if (wasPlaying) _controller.pause();
    await showHelpDialog(context);
    if (mounted && wasPlaying && _controller.isPaused) _controller.resume();
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
      showGhost: settings.showGhost,
      showGrid: settings.showGrid,
    );

    return Focus(
      key: const ValueKey('game-focus'),
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 58,
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
                Text(
                  _subtitle(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                onPressed: _controller.isOver
                    ? null
                    : (_controller.isPaused
                          ? _controller.resume
                          : () => unawaited(_openPause())),
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
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 880
                ? _buildWide(palette, bindings)
                : _buildCompact(palette, bindings),
          ),
        ),
      ),
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

  Widget _buildWide(BlockPalette palette, KeyBindings bindings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 132,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => GameLeftRail(
                controller: _controller,
                palette: palette,
                bindings: bindings,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildBoard(palette)),
          const SizedBox(width: 16),
          SizedBox(
            width: 124,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  GameRightRail(controller: _controller, palette: palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BlockPalette palette, KeyBindings bindings) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                GameHud(controller: _controller, compact: true),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(child: _buildBoard(palette)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 58,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => GameCompactRail(
                      controller: _controller,
                      palette: palette,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDesktopPlatform)
          GameKeyboardHint(bindings: bindings)
        else
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => TouchPad(controller: _controller),
          ),
      ],
    );
  }
}
