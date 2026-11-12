import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bag.dart';
import 'board.dart';
import 'daily_challenge.dart';
import 'game_mode.dart';
import 'garbage.dart';
import 'level.dart';
import 'match_rules.dart';
import 'scoreboard.dart';
import 'srs.dart';
import 'tetromino.dart';
import 'tspin.dart';

/// 对局状态。
enum GameStatus { ready, playing, paused, over }

/// 需要界面反馈的动作，对应音效与震动。
enum GameEvent {
  move,
  rotate,
  hold,
  lock,
  lineClear,
  tetris,
  perfectClear,
  levelUp,
  gameOver,
  win,
}

/// 俄罗斯方块核心控制器：负责方块生成、移动、消行、计分与计时。
/// 默认自带 60Hz 定时器驱动；单元测试可关闭自动计时，手动调用 [tick]。
class TetrisController extends ChangeNotifier {
  TetrisController({
    required GameMode mode,
    LevelDefinition? level,
    DailyChallenge? daily,
    int? seed,
    bool autoTick = true,
    Duration? lockDelay,
    Duration clearDelay = const Duration(milliseconds: 260),
    Duration tickInterval = const Duration(microseconds: 16666),
  }) : this._(
         rules: MatchRules(mode: mode, level: level, daily: daily),
         seed: seed ?? daily?.seed ?? level?.seed,
         autoTick: autoTick,
         lockDelay: lockDelay,
         clearDelay: clearDelay,
         tickInterval: tickInterval,
       );

  TetrisController._({
    required this.rules,
    required int? seed,
    required this.autoTick,
    Duration? lockDelay,
    required this.clearDelay,
    required this.tickInterval,
  }) : lockDelay = lockDelay ?? rules.lockDelay,
       _seed = seed,
       _bag = SevenBag(seed: seed),
       _garbage = GarbageSpawner(
         rule: rules.garbage,
         seed: (seed ?? 0) * 31 + 17,
       ),
       _scoreBoard = ScoreBoard(
         startLevel: rules.startLevel,
         arcade: rules.isArcade,
       ),
       board = Board() {
    _lastTick = DateTime.now();
  }

  static const int maxLockResets = 15;

  /// 本局玩法与关卡规则。
  final MatchRules rules;

  GameMode get mode => rules.mode;

  /// 关卡模式下生效的关卡规则，其他模式为 null。
  LevelDefinition? get levelDef => rules.level;

  final Board board;
  final Duration lockDelay;
  final Duration clearDelay;
  final Duration tickInterval;

  final bool autoTick;
  final int? _seed;
  final SevenBag _bag;
  final GarbageSpawner _garbage;
  final ScoreBoard _scoreBoard;
  final List<GameEvent> _events = [];

  Timer? _timer;
  late DateTime _lastTick;

  GameStatus _status = GameStatus.ready;
  ActivePiece? _piece;
  TetrominoType? _hold;
  bool _holdUsed = false;

  Duration _elapsed = Duration.zero;
  Duration _gravityAccumulator = Duration.zero;
  Duration _lockElapsed = Duration.zero;
  int _lockResets = 0;
  bool _grounded = false;

  List<int> _clearingRows = const [];
  Duration _clearElapsed = Duration.zero;
  Duration? _completedAt;

  bool _lastActionRotate = false;
  GameResult? _result;

  int _boardRevision = 0;
  int _clearSequence = 0;
  int _lockSequence = 0;
  int _hardDropSequence = 0;
  int _hardDropColumn = 0;
  int _hardDropRows = 0;
  List<Block> _lastLockedBlocks = const [];
  TetrominoType? _lastLockedType;

  /// 计时专用通知：只在时间读数变化时触发。
  /// 界面上的数值组件单独监听它，避免侧栏与操作区跟着按帧重建。
  final ValueNotifier<Duration> clock = ValueNotifier(Duration.zero);

  ActivePiece? _ghost;
  ActivePiece? _ghostSource;
  int _ghostSourceRevision = -1;
  int _ghostComputations = 0;

  int _lastNotifiedMillis = -1;

  GameStatus get status => _status;
  ActivePiece? get piece => _piece;
  TetrominoType? get holdType => _hold;
  bool get canHold =>
      rules.holdEnabled && _status == GameStatus.playing && !_holdUsed;

  /// 接下来的方块：标准玩法五个，街机模式只有下一块。
  List<TetrominoType> get nextQueue => _bag.peek(rules.previewCount);

  int get score => _scoreBoard.score;
  int get lines => _scoreBoard.lines;
  int get level => _scoreBoard.level;
  int get combo => _scoreBoard.combo;
  int get maxCombo => _scoreBoard.maxCombo;
  int get pieces => _scoreBoard.pieces;
  int get tetrises => _scoreBoard.tetrises;
  int get tSpins => _scoreBoard.tSpins;
  int get perfectClears => _scoreBoard.perfectClears;
  bool get backToBack => _scoreBoard.backToBack;
  Duration get elapsed => _elapsed;
  GameResult? get result => _result;
  bool get isPlaying => _status == GameStatus.playing;
  bool get isPaused => _status == GameStatus.paused;
  bool get isOver => _status == GameStatus.over;

  /// 消行动画进行中，此时不接受操作。
  bool get isClearing => _clearingRows.isNotEmpty;
  List<int> get clearingRows => _clearingRows;
  double get clearProgress {
    if (_clearingRows.isEmpty || clearDelay.inMicroseconds == 0) return 0;
    final ratio = _clearElapsed.inMicroseconds / clearDelay.inMicroseconds;
    return ratio.clamp(0.0, 1.0);
  }

  bool get canControl =>
      _status == GameStatus.playing && _piece != null && !isClearing;

  /// 当前对局的目标行数：竞速为 40，关卡取自关卡定义。
  int? get targetLines => rules.targetLines;

  /// 当前对局的限时：计时模式 120 秒，关卡取自关卡定义。
  Duration? get limit => rules.timeLimit;

  Duration get timeLimit => limit ?? Duration.zero;

  Duration get remaining {
    final total = limit;
    if (total == null) return Duration.zero;
    final value = total - _elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  /// 幽灵方块：当前方块直落到底的位置。
  /// 方块不可变、移动即换实例，棋盘变化由版本号表示，两者不变时直接复用。
  ActivePiece? get ghostPiece {
    final current = _piece;
    if (current == null) return null;
    if (identical(current, _ghostSource) &&
        _ghostSourceRevision == _boardRevision) {
      return _ghost;
    }
    var ghost = current;
    while (board.fits(ghost.copyWith(y: ghost.y + 1).blocks)) {
      ghost = ghost.copyWith(y: ghost.y + 1);
    }
    _ghostComputations++;
    _ghostSource = current;
    _ghostSourceRevision = _boardRevision;
    _ghost = ghost;
    return ghost;
  }

  /// 幽灵落点实际计算次数，用于校验缓存命中。
  @visibleForTesting
  int get debugGhostComputations => _ghostComputations;

  /// 已完成的进度（0~1），用于目标行数进度条。
  double get progress {
    final target = targetLines;
    if (target == null) return 0;
    return (lines / target).clamp(0.0, 1.0);
  }

  Duration? get garbageInterval => rules.garbage?.interval;

  /// 距下一次垃圾行上涌还有多少秒，未启用时为 null。
  int? get garbageSecondsLeft => _garbage.secondsLeft;

  int get stackHeight => board.stackHeight;

  // 渲染层用于触发特效的序号与快照。
  /// 棋盘内容版本号，渲染层据此判断静态图层是否失效。
  int get boardRevision => _boardRevision;
  int get clearSequence => _clearSequence;
  List<int> get lastClearRows => _clearingRows;
  int get lockSequence => _lockSequence;
  List<Block> get lastLockedBlocks => _lastLockedBlocks;
  TetrominoType? get lastLockedType => _lastLockedType;
  int get hardDropSequence => _hardDropSequence;
  int get hardDropColumn => _hardDropColumn;
  int get hardDropRows => _hardDropRows;

  List<GameEvent> drainEvents() {
    if (_events.isEmpty) return const [];
    final drained = List<GameEvent>.of(_events);
    _events.clear();
    return drained;
  }

  void start() {
    _resetState();
    _status = GameStatus.playing;
    _spawnNext();
    _startTicker();
    notifyListeners();
  }

  void restart() => start();

  void pause() {
    if (_status != GameStatus.playing) return;
    _status = GameStatus.paused;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void resume() {
    if (_status != GameStatus.paused) return;
    _status = GameStatus.playing;
    _lastTick = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  bool moveLeft() => _move(-1);

  bool moveRight() => _move(1);

  bool rotateClockwise() => _rotate(1);

  bool rotateCounterClockwise() => _rotate(-1);

  /// 软降：每次下移一格加 1 分。
  void softDrop() {
    if (!canControl) return;
    final current = _piece!;
    final moved = current.copyWith(y: current.y + 1);
    if (!board.fits(moved.blocks)) {
      _grounded = true;
      return;
    }
    _piece = moved;
    _scoreBoard.addDropScore(1, pointsPerCell: 1);
    _gravityAccumulator = Duration.zero;
    _lastActionRotate = false;
    _refreshGrounded();
    notifyListeners();
  }

  /// 硬降：直接落底并立即锁定，每格加 2 分。
  void hardDrop() {
    if (!canControl) return;
    var current = _piece!;
    var distance = 0;
    while (board.fits(current.copyWith(y: current.y + 1).blocks)) {
      current = current.copyWith(y: current.y + 1);
      distance++;
    }
    _piece = current;
    _scoreBoard.addDropScore(distance, pointsPerCell: 2);
    _hardDropColumn = current.x;
    _hardDropRows = distance;
    _hardDropSequence++;
    _lockPiece();
    notifyListeners();
  }

  /// 暂存：一局中每次锁定前只能使用一次，街机模式不可用。
  void hold() {
    if (!canHold || !canControl) return;
    final current = _piece!;
    final previous = _hold;
    _hold = current.type;
    if (previous == null) {
      _spawnNext();
    } else {
      _spawnType(previous);
    }
    _holdUsed = true;
    _events.add(GameEvent.hold);
    notifyListeners();
  }

  /// 供渲染层与测试使用的落定入口。
  @visibleForTesting
  void lockNowForTest() => _lockPiece();

  @visibleForTesting
  void debugSetStats({int? lines, Duration? elapsed}) {
    if (lines != null) _scoreBoard.setLinesForTest(lines);
    if (elapsed != null) _elapsed = elapsed;
  }

  @visibleForTesting
  void setPieceForTest(ActivePiece piece) {
    _piece = piece;
    _holdUsed = false;
    _lockElapsed = Duration.zero;
    _lockResets = 0;
    _gravityAccumulator = Duration.zero;
    _lastActionRotate = false;
    _refreshGrounded();
    notifyListeners();
  }

  /// 推进一帧：处理重力、锁定延迟、消行动画与计时模式。
  void tick(Duration delta) {
    if (_status != GameStatus.playing) return;
    var step = delta;
    if (step > const Duration(milliseconds: 100)) {
      step = const Duration(milliseconds: 100);
    }
    _elapsed += step;

    final deadline = limit;
    if (deadline != null && _elapsed >= deadline) {
      _elapsed = deadline;
      _end(won: false, reason: '时间到');
      return;
    }

    if (isClearing) {
      _clearElapsed += step;
      if (_clearElapsed >= clearDelay) _finishClear();
      _publishClock();
      return;
    }

    final activePiece = _piece;
    if (activePiece == null) return;
    var current = activePiece;

    _gravityAccumulator += step;
    final interval = rules.gravityFor(level);
    while (_gravityAccumulator >= interval) {
      _gravityAccumulator -= interval;
      final moved = current.copyWith(y: current.y + 1);
      if (!board.fits(moved.blocks)) {
        _grounded = true;
        break;
      }
      _piece = moved;
      current = moved;
      _grounded = false;
      _lastActionRotate = false;
    }

    if (!_grounded) _refreshGrounded();
    if (_grounded) {
      _lockElapsed += step;
      if (_lockElapsed >= lockDelay) {
        _lockPiece();
        return;
      }
    }
    _updateGarbage(step);
    _publishClock();
  }

  /// 按关卡设定定期把整行垃圾从底部顶上，并把当前方块一并抬起。
  void _updateGarbage(Duration step) {
    for (final holes in _garbage.advance(step, board.columns)) {
      _raiseGarbage(holes);
      if (_status != GameStatus.playing) return;
    }
  }

  void _raiseGarbage(List<int> holes) {
    if (holes.isEmpty) return;
    final overflow = board.raiseGarbage(holes);
    _boardRevision++;
    if (overflow) {
      _end(won: false, reason: '垃圾行顶到了顶部');
      return;
    }
    final current = _piece;
    if (current != null) {
      var lifted = current;
      var steps = 0;
      while (!board.fits(lifted.blocks) && steps <= holes.length + 1) {
        lifted = lifted.copyWith(y: lifted.y - 1);
        steps++;
      }
      if (!board.fits(lifted.blocks)) {
        _end(won: false, reason: '垃圾行顶到了顶部');
        return;
      }
      _piece = lifted;
      _refreshGrounded();
    }
    _events.add(GameEvent.lock);
    notifyListeners();
  }

  void _startTicker() {
    if (!autoTick) return;
    _timer?.cancel();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(tickInterval, (_) {
      final now = DateTime.now();
      var delta = now.difference(_lastTick);
      _lastTick = now;
      if (delta > const Duration(milliseconds: 100)) {
        delta = const Duration(milliseconds: 100);
      }
      tick(delta);
    });
  }

  bool _move(int direction) {
    if (!canControl) return false;
    final current = _piece!;
    final moved = current.copyWith(x: current.x + direction);
    if (!board.fits(moved.blocks)) return false;
    _piece = moved;
    _lastActionRotate = false;
    _resetLockDelay();
    _events.add(GameEvent.move);
    notifyListeners();
    return true;
  }

  bool _rotate(int direction) {
    if (!canControl) return false;
    final rotated = tryRotate(board, _piece!, direction);
    if (rotated == null) return false;
    _piece = rotated;
    _lastActionRotate = true;
    _resetLockDelay();
    _events.add(GameEvent.rotate);
    notifyListeners();
    return true;
  }

  /// 贴地时移动或旋转会重置锁定延迟，最多重置 15 次；街机模式不重置。
  void _resetLockDelay() {
    _refreshGrounded();
    if (!_grounded) {
      _lockElapsed = Duration.zero;
      return;
    }
    if (!rules.lockResetEnabled || _lockResets >= maxLockResets) return;
    _lockResets++;
    _lockElapsed = Duration.zero;
  }

  void _refreshGrounded() {
    final current = _piece;
    if (current == null) {
      _grounded = false;
      return;
    }
    _grounded = !board.fits(current.copyWith(y: current.y + 1).blocks);
    if (!_grounded) _lockElapsed = Duration.zero;
  }

  void _spawnNext() {
    _spawnType(_bag.next());
  }

  bool _spawnType(TetrominoType type) {
    final spawned = ActivePiece(type: type, x: kSpawnColumn, y: 0);
    _piece = spawned;
    _holdUsed = false;
    _lockElapsed = Duration.zero;
    _lockResets = 0;
    _gravityAccumulator = Duration.zero;
    _lastActionRotate = false;
    _refreshGrounded();
    if (!board.fits(spawned.blocks)) {
      _end(won: false, reason: '方块堆到了顶部');
      return false;
    }
    return true;
  }

  void _lockPiece() {
    final current = _piece;
    if (current == null) return;
    final spin = detectTSpin(
      board: board,
      piece: current,
      lastActionRotate: _lastActionRotate,
    );
    final tSpin = spin.isTSpin;
    final mini = spin.isMini;
    final blocks = current.blocks;
    board.lock(blocks, current.type);
    _boardRevision++;
    _piece = null;
    _scoreBoard.countPiece();
    _lastLockedBlocks = List.unmodifiable(blocks);
    _lastLockedType = current.type;
    _lockSequence++;
    _grounded = false;
    _lockElapsed = Duration.zero;

    // 方块完全锁在隐藏区，等同顶出。
    if (blocks.every((block) => block.y < board.hiddenRows)) {
      _events.add(GameEvent.lock);
      _end(won: false, reason: '方块堆到了顶部');
      return;
    }

    final rows = board.fullRows();
    final perfect =
        rows.isNotEmpty && board.filledCount == rows.length * board.columns;
    final clear = _scoreBoard.registerClear(
      rows: rows.length,
      tSpin: tSpin,
      mini: mini,
      perfectClear: perfect,
    );
    if (rows.isEmpty) {
      _events.add(GameEvent.lock);
      _spawnNext();
      notifyListeners();
      return;
    }

    if (clear.levelUp) _events.add(GameEvent.levelUp);
    _events.add(GameEvent.lock);
    _events.add(rows.length == 4 ? GameEvent.tetris : GameEvent.lineClear);
    if (perfect) _events.add(GameEvent.perfectClear);

    _clearingRows = rows;
    _clearElapsed = Duration.zero;
    _clearSequence++;

    final target = targetLines;
    if (target != null && lines >= target && _completedAt == null) {
      _completedAt = _elapsed;
    }
    notifyListeners();
  }

  void _finishClear() {
    board.removeRows(_clearingRows);
    _boardRevision++;
    _clearingRows = const [];
    _clearElapsed = Duration.zero;

    final target = targetLines;
    if (target != null && lines >= target) {
      _end(
        won: true,
        reason: '完成 $target 行',
        elapsedOverride: _completedAt ?? _elapsed,
      );
      return;
    }
    _completedAt = null;
    _spawnNext();
    notifyListeners();
  }

  void _end({
    required bool won,
    required String reason,
    Duration? elapsedOverride,
  }) {
    if (_status == GameStatus.over) return;
    _status = GameStatus.over;
    _timer?.cancel();
    _timer = null;
    _clearingRows = const [];
    final finishedAt = elapsedOverride ?? _elapsed;
    _result = GameResult(
      mode: rules.mode,
      score: score,
      lines: lines,
      level: level,
      pieces: pieces,
      maxCombo: maxCombo,
      elapsed: finishedAt,
      won: won,
      reason: reason,
      levelId: rules.levelId,
      stars: won ? rules.starsFor(finishedAt) : 0,
      challengeKey: rules.daily?.key,
      tetrises: tetrises,
      tSpins: tSpins,
      perfectClears: perfectClears,
    );
    _events.add(won ? GameEvent.win : GameEvent.gameOver);
    notifyListeners();
  }

  void _publishClock() {
    final bucket = _elapsed.inMilliseconds ~/ 50;
    if (bucket == _lastNotifiedMillis) return;
    _lastNotifiedMillis = bucket;
    clock.value = _elapsed;
  }

  void _resetState() {
    if (rules.terrain.isEmpty) {
      board.reset();
    } else {
      board.loadTerrain(rules.terrain);
    }
    _boardRevision++;
    _bag.reset(seed: _seed);
    _garbage.reset();
    _piece = null;
    _hold = null;
    _holdUsed = false;
    _scoreBoard.reset(startLevel: rules.startLevel);
    _elapsed = Duration.zero;
    _gravityAccumulator = Duration.zero;
    _lockElapsed = Duration.zero;
    _lockResets = 0;
    _grounded = false;
    _clearingRows = const [];
    _clearElapsed = Duration.zero;
    _completedAt = null;
    _lastActionRotate = false;
    _result = null;
    _events.clear();
    _lastNotifiedMillis = -1;
    clock.value = Duration.zero;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    clock.dispose();
    super.dispose();
  }
}
