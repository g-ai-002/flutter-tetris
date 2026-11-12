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
import '../utils/game_display.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_shell.dart';

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
      style: PlayfieldStyle(palette: settings.blockSkin.palette(dark: settings.darkMode)),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
    _gamepad = GamepadService(onAction: _handleAction);
    unawaited(_gamepad.start());
    LogService.info('开始对局: ${_controller.rules.title}, 逻辑 ${settings.logicRate}Hz');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(enterGameDisplay());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_controller.isPlaying) _controller.pause();
    } else if (state == AppLifecycleState.resumed && mounted) {
      // 系统栏可能在后台被还原，回到前台重新进入沉浸模式。
      unawaited(enterGameDisplay());
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
    await showPauseDialog(context, controller: _controller, onRestart: _restart, onExit: _exit);
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
    final action = context.read<SettingsProvider>().keyBindings.actionFor(event.logicalKey);
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
    _game.style = PlayfieldStyle(
      palette: palette,
      showGhost: settings.showGhost && _controller.rules.ghostEnabled,
      showGrid: settings.showGrid,
    );

    return Focus(
      key: const ValueKey('game-focus'),
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GameShell(
        controller: _controller,
        game: _game,
        palette: palette,
        bindings: settings.keyBindings,
        onExit: _exit,
        onHelp: () => unawaited(_openHelp()),
        onPause: _togglePause,
      ),
    );
  }
}
