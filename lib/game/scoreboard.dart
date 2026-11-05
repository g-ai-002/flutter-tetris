import 'scoring.dart';

/// 一次落定后的计分结果。
class ClearOutcome {
  const ClearOutcome({
    required this.rows,
    required this.score,
    required this.levelUp,
  });

  /// 本次消除的行数，0 表示没有消行。
  final int rows;

  /// 本次落定获得的分数。
  final int score;

  /// 本次落定是否触发升级。
  final bool levelUp;
}

/// 对局内的分数、等级、连击与落定统计。
///
/// 只负责累计与结算，不感知场地和输入，方便单独验证计分规则。
class ScoreBoard {
  ScoreBoard({int startLevel = 1})
    : _startLevel = startLevel < 1 ? 1 : startLevel,
      _level = startLevel < 1 ? 1 : startLevel;

  int _startLevel;
  int _score = 0;
  int _lines = 0;
  int _level;
  int _combo = 0;
  int _maxCombo = 0;
  int _pieces = 0;
  bool _backToBack = false;

  int get score => _score;
  int get lines => _lines;
  int get level => _level;
  int get combo => _combo;
  int get maxCombo => _maxCombo;
  int get pieces => _pieces;
  bool get backToBack => _backToBack;

  /// 软降或硬降按格数计分。
  void addDropScore(int cells, {required int pointsPerCell}) {
    if (cells <= 0) return;
    _score += cells * pointsPerCell;
  }

  /// 记录一次方块落定。
  void countPiece() => _pieces++;

  /// 结算一次落定。
  ///
  /// [rows] 为消除行数；零消 T-Spin 保留分数但不增加连击，
  /// 也不改变连续奖励状态。
  ClearOutcome registerClear({
    required int rows,
    required bool tSpin,
    required bool mini,
    required bool perfectClear,
  }) {
    final before = _score;
    if (rows == 0) {
      if (tSpin) {
        _score += clearScore(lines: 0, level: _level, tSpin: true, mini: mini);
      }
      _combo = 0;
      return ClearOutcome(rows: 0, score: _score - before, levelUp: false);
    }

    final difficult = tSpin || rows == 4;
    _score += clearScore(
      lines: rows,
      level: _level,
      tSpin: tSpin,
      mini: mini,
      backToBack: difficult && _backToBack,
      perfectClear: perfectClear,
      combo: _combo,
    );
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    _lines += rows;
    final nextLevel = levelForLines(_lines, startLevel: _startLevel);
    final levelUp = nextLevel > _level;
    _level = nextLevel;
    _backToBack = difficult;
    return ClearOutcome(rows: rows, score: _score - before, levelUp: levelUp);
  }

  /// 测试与调试用：直接设置已消行数并同步等级。
  void setLinesForTest(int lines) {
    _lines = lines;
    _level = levelForLines(lines, startLevel: _startLevel);
  }

  void reset({required int startLevel}) {
    _startLevel = startLevel < 1 ? 1 : startLevel;
    _score = 0;
    _lines = 0;
    _level = _startLevel;
    _combo = 0;
    _maxCombo = 0;
    _pieces = 0;
    _backToBack = false;
  }
}
