import 'dart:async';

import 'package:flutter/foundation.dart';

import 'bag.dart';
import 'board.dart';
import 'game_mode.dart';
import 'scoring.dart';
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
///
/// 默认自带 16ms 定时器驱动；单元测试可关闭自动计时，手动调用 [tick]。
class TetrisController extends ChangeNotifier {
  TetrisController({
    required this.mode,
    int? seed,
    this.autoTick = true,
    this.lockDelay = const Duration(milliseconds: 500),
    this.clearDelay = const Duration(milliseconds: 260),
    this.tickInterval = const Duration(milliseconds: 16),
  }) : _bag = SevenBag(seed: seed),
       board = Board() {
    _lastTick = DateTime.now();
  }

  static const int maxLockResets = 15;

  final GameMode mode;
  final Board board;
  final Duration lockDelay;
  final Duration clearDelay;
  final Duration tickInterval;

  final bool autoTick;
  final SevenBag _bag;
  final List<GameEvent> _events = [];

  Timer? _timer;
  late DateTime _lastTick;

  GameStatus _status = GameStatus.ready;
  ActivePiece? _piece;
  TetrominoType? _hold;
  bool _holdUsed = false;
  final List<TetrominoType> _next = [];

  int _score = 0;
  int _lines = 0;
  int _level = 1;
  int _combo = 0;
  int _maxCombo = 0;
  int _pieces = 0;
  bool _backToBack = false;

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

  int _clearSequence = 0;
  int _lockSequence = 0;
  int _hardDropSequence = 0;
  int _hardDropColumn = 0;
  int _hardDropRows = 0;
  List<Block> _lastLockedBlocks = const [];
  TetrominoType? _lastLockedType;

  int _lastNotifiedMillis = -1;

  GameStatus get status => _status;
  ActivePiece? get piece => _piece;
  TetrominoType? get holdType => _hold;
  bool get canHold => _status == GameStatus.playing && !_holdUsed;
  List<TetrominoType> get nextQueue => List.unmodifiable(_next);

  int get score => _score;
  int get lines => _lines;
  int get level => _level;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get pieces => _pieces;
  bool get backToBack => _backToBack;
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

  Duration get timeLimit => mode.timeLimit ?? Duration.zero;
  Duration get remaining {
    final limit = mode.timeLimit;
    if (limit == null) return Duration.zero;
    final value = limit - _elapsed;
    return value.isNegative ? Duration.zero : value;
  }

  /// 幽灵方块：当前方块直落到底的位置。
  ActivePiece? get ghostPiece {
    final current = _piece;
    if (current == null) return null;
    var ghost = current;
    while (board.fits(ghost.copyWith(y: ghost.y + 1).blocks)) {
      ghost = ghost.copyWith(y: ghost.y + 1);
    }
    return ghost;
  }

  /// 已完成的进度（0~1），用于 40 行竞速的进度条。
  double get progress {
    final target = mode.targetLines;
    if (target == null) return 0;
    return (_lines / target).clamp(0.0, 1.0);
  }

  Duration get gravity => gravityForLevel(_level);

  int get stackHeight => board.stackHeight;

  // 渲染层用于触发特效的序号与快照。
  int get clearSequence => _clearSequence;
  List<int> get lastClearRows => _clearingRows;
  int get lockSequence => _lockSequence;
  List<Block> get lastLockedBlocks => List.unmodifiable(_lastLockedBlocks);
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
    _refillQueue();
    _spawnNext();
    _startTicker();
    notifyListeners();
  }

  void restart() => start();

  void togglePause() {
    if (_status == GameStatus.playing) {
      _status = GameStatus.paused;
      _timer?.cancel();
      _timer = null;
      notifyListeners();
      return;
    }
    if (_status == GameStatus.paused) {
      _status = GameStatus.playing;
      _lastTick = DateTime.now();
      _startTicker();
      notifyListeners();
    }
  }

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
    _score += 1;
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
    _score += distance * 2;
    _hardDropColumn = current.x;
    _hardDropRows = distance;
    _hardDropSequence++;
    _lockPiece();
    notifyListeners();
  }

  /// 暂存：一局中每次锁定前只能使用一次。
  void hold() {
    if (!canControl || _holdUsed) return;
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
    if (lines != null) {
      _lines = lines;
      _level = levelForLines(lines);
    }
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

    final limit = mode.timeLimit;
    if (limit != null && _elapsed >= limit) {
      _elapsed = limit;
      _end(won: false, reason: '时间到');
      return;
    }

    if (isClearing) {
      _clearElapsed += step;
      if (_clearElapsed >= clearDelay) _finishClear();
      _notifyIfTimeChanged();
      return;
    }

    final activePiece = _piece;
    if (activePiece == null) return;
    var current = activePiece;

    _gravityAccumulator += step;
    final interval = gravityForLevel(_level);
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
    _notifyIfTimeChanged();
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

  /// 贴地时移动或旋转会重置锁定延迟，最多重置 15 次。
  void _resetLockDelay() {
    _refreshGrounded();
    if (!_grounded) {
      _lockElapsed = Duration.zero;
      return;
    }
    if (_lockResets >= maxLockResets) return;
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

  void _refillQueue() {
    while (_next.length < 5) {
      _next.add(_bag.next());
    }
  }

  void _spawnNext() {
    _refillQueue();
    final type = _next.removeAt(0);
    _refillQueue();
    _spawnType(type);
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
    _piece = null;
    _pieces++;
    _lastLockedBlocks = blocks;
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
    if (rows.isEmpty) {
      // 零消 T-Spin 不计连击，但仍有基础分。
      if (tSpin) {
        _score += clearScore(lines: 0, level: _level, tSpin: true, mini: mini);
      }
      _combo = 0;
      _events.add(GameEvent.lock);
      _spawnNext();
      notifyListeners();
      return;
    }

    final difficult = tSpin || rows.length == 4;
    final b2bActive = difficult && _backToBack;
    final perfect = board.filledCount == rows.length * board.columns;
    _score += clearScore(
      lines: rows.length,
      level: _level,
      tSpin: tSpin,
      mini: mini,
      backToBack: b2bActive,
      perfectClear: perfect,
      combo: _combo,
    );
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _lines += rows.length;
    final newLevel = levelForLines(_lines);
    if (newLevel > _level) {
      _level = newLevel;
      _events.add(GameEvent.levelUp);
    }
    _backToBack = difficult;

    _events.add(GameEvent.lock);
    _events.add(rows.length == 4 ? GameEvent.tetris : GameEvent.lineClear);
    if (perfect) _events.add(GameEvent.perfectClear);

    _clearingRows = rows;
    _clearElapsed = Duration.zero;
    _clearSequence++;

    final target = mode.targetLines;
    if (target != null && _lines >= target && _completedAt == null) {
      _completedAt = _elapsed;
    }
    notifyListeners();
  }

  void _finishClear() {
    board.removeRows(_clearingRows);
    _clearingRows = const [];
    _clearElapsed = Duration.zero;

    final target = mode.targetLines;
    if (target != null && _lines >= target) {
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
    _result = GameResult(
      mode: mode,
      score: _score,
      lines: _lines,
      level: _level,
      pieces: _pieces,
      maxCombo: _maxCombo,
      elapsed: elapsedOverride ?? _elapsed,
      won: won,
      reason: reason,
    );
    _events.add(won ? GameEvent.win : GameEvent.gameOver);
    notifyListeners();
  }

  void _notifyIfTimeChanged() {
    final bucket = _elapsed.inMilliseconds ~/ 50;
    if (bucket == _lastNotifiedMillis) return;
    _lastNotifiedMillis = bucket;
    notifyListeners();
  }

  void _resetState() {
    board.reset();
    _bag.reset();
    _next.clear();
    _piece = null;
    _hold = null;
    _holdUsed = false;
    _score = 0;
    _lines = 0;
    _level = 1;
    _combo = 0;
    _maxCombo = 0;
    _pieces = 0;
    _backToBack = false;
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
