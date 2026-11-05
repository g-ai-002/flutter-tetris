import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../flame/playfield_component.dart';
import '../flame/tetris_game.dart';
import '../game/game_mode.dart';
import '../game/level.dart';
import '../game/tetris_controller.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/platform_info.dart';
import 'widgets/board_gestures.dart';
import 'widgets/board_stage.dart';
import 'widgets/game_dialogs.dart';
import 'widgets/game_hud.dart';
import 'widgets/piece_slot.dart';
import 'widgets/status_chip.dart';
import 'widgets/touch_pad.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.mode, this.level});

  final GameMode mode;

  /// 关卡模式下要挑战的关卡。
  final LevelDefinition? level;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late final TetrisController _controller;
  late final TetrisGame _game;
  final FocusNode _focusNode = FocusNode(debugLabel: 'tetris-input');

  bool _resultShown = false;
  bool _pauseDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = TetrisController(mode: widget.mode, level: widget.level);
    _game = TetrisGame(
      controller: _controller,
      style: const PlayfieldStyle(palette: BlockPalette.light),
    );
    _controller.addListener(_onControllerChanged);
    _controller.start();
    LogService.info(
      '开始对局: ${widget.level == null ? widget.mode.label : '第 ${widget.level!.id} 关'}',
    );
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
      '对局结束: ${result.levelId == null ? result.mode.label : '第 ${result.levelId} 关'}, '
      '得分 ${result.score}, 消行 ${result.lines}, 等级 ${result.level}, '
      '用时 ${result.elapsed.inMilliseconds}ms, ${result.reason}'
      '${outcome.isRecord ? '（新纪录）' : ''}',
    );
    if (!mounted) return;
    context.read<SettingsProvider>().refresh();
    final level = widget.level;
    final next = level == null ? null : nextLevelOf(level);
    final bestScore = level == null
        ? storage.bestScore(result.mode)
        : storage.levelRecord(level.id).bestScore;
    await showGameResultDialog(
      context,
      result: result,
      outcome: outcome,
      bestScore: bestScore,
      level: level,
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
    LogService.info(
      '重新开始: ${widget.level == null ? widget.mode.label : '第 ${widget.level!.id} 关'}',
    );
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
    final key = event.logicalKey;
    final firstPress = event is KeyDownEvent;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _controller.moveLeft();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _controller.moveRight();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _controller.softDrop();
      return KeyEventResult.handled;
    }
    if (!firstPress) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyX) {
      _controller.rotateClockwise();
    } else if (key == LogicalKeyboardKey.keyZ) {
      _controller.rotateCounterClockwise();
    } else if (key == LogicalKeyboardKey.space) {
      _controller.hardDrop();
    } else if (key == LogicalKeyboardKey.keyC ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      _controller.hold();
    } else if (key == LogicalKeyboardKey.keyP ||
        key == LogicalKeyboardKey.escape) {
      unawaited(_openPause());
    } else if (key == LogicalKeyboardKey.keyR) {
      _restart();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final darkness = Theme.of(context).brightness == Brightness.dark;
    final palette = darkness ? BlockPalette.darkPalette : BlockPalette.light;
    _game.style = PlayfieldStyle(
      palette: palette,
      showGhost: settings.showGhost,
      showGrid: settings.showGrid,
    );

    return Focus(
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
                  widget.level == null
                      ? widget.mode.label
                      : '第 ${widget.level!.id} 关 · ${widget.level!.name}',
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
                ? _buildWide(palette)
                : _buildCompact(palette),
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

  Widget _buildWide(BlockPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 132,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _buildLeftRail(palette),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildBoard(palette)),
          const SizedBox(width: 16),
          SizedBox(
            width: 124,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => _buildRightRail(palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftRail(BlockPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PieceSlot(
          label: 'HOLD 暂存',
          type: _controller.holdType,
          palette: palette,
          size: 62,
          onTap: _controller.canHold ? _controller.hold : null,
          hint: _controller.canHold ? 'C / 点击' : null,
        ),
        const SizedBox(height: 18),
        Divider(color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 14),
        GameHud(controller: _controller),
      ],
    );
  }

  Widget _buildRightRail(BlockPalette palette) {
    final next = _controller.nextQueue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < 5 && i < next.length; i++) ...[
          if (i > 0) const SizedBox(height: 7),
          PieceSlot(
            label: '',
            type: next[i],
            palette: palette,
            size: i == 0 ? 52 : 44,
            showLabel: false,
          ),
        ],
        const Spacer(),
        if (_controller.combo >= 2) ...[
          StatusChip(
            accent: Theme.of(context).colorScheme.primary,
            filled: true,
            child: Text(
              '连击 ×${_controller.combo}',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
        ],
        if (_controller.backToBack)
          StatusChip(
            accent: appGold,
            child: Text(
              '连续奖励',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: appGold, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildCompact(BlockPalette palette) {
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
                    builder: (context, _) => _buildCompactRail(palette),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isDesktopPlatform)
          const _KeyboardHint()
        else
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => TouchPad(controller: _controller),
          ),
      ],
    );
  }

  Widget _buildCompactRail(BlockPalette palette) {
    final next = _controller.nextQueue;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PieceSlot(
              label: 'HOLD',
              type: _controller.holdType,
              palette: palette,
              showLabel: false,
              onTap: _controller.canHold ? _controller.hold : null,
            ),
            const SizedBox(height: 8),
            Text(
              'NEXT',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < 3 && i < next.length; i++) ...[
              if (i > 0) const SizedBox(height: 5),
              PieceSlot(
                label: '',
                type: next[i],
                palette: palette,
                size: 38,
                showLabel: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyboardHint extends StatelessWidget {
  const _KeyboardHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final item in const [
            ('←→', '移动'),
            ('↓', '软降'),
            ('空格', '硬降'),
            ('↑', '旋转'),
            ('C', '暂存'),
            ('P', '暂停'),
          ])
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: colors.outline.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Text(
                    item.$1,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9.5),
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  item.$2,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
        ],
      ),
    );
  }
}
