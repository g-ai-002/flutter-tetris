import 'dart:math';
import '../utils/constants.dart';
import 'tetromino.dart';

class GameState {
  final int width;
  final int height;
  final List<List<int>> board;
  final Tetromino currentPiece;
  final int currentX;
  final int currentY;
  final int score;
  final int level;
  final int linesCleared;
  final bool isGameOver;
  final bool isPaused;
  final Tetromino? nextPiece;
  final int highScore;

  GameState({
    required this.width,
    required this.height,
    required this.board,
    required this.currentPiece,
    required this.currentX,
    required this.currentY,
    required this.score,
    required this.level,
    required this.linesCleared,
    this.isGameOver = false,
    this.isPaused = false,
    this.nextPiece,
    this.highScore = 0,
  });

  factory GameState.initial({int highScore = 0}) {
    final board = List.generate(
      AppConstants.boardHeight,
      (_) => List.filled(AppConstants.boardWidth, 0),
    );
    final piece = Tetromino.random();
    final next = Tetromino.random();
    return GameState(
      width: AppConstants.boardWidth,
      height: AppConstants.boardHeight,
      board: board,
      currentPiece: piece,
      currentX: (AppConstants.boardWidth - piece.shape[0].length) ~/ 2,
      currentY: 0,
      score: 0,
      level: 1,
      linesCleared: 0,
      nextPiece: next,
      highScore: highScore,
    );
  }

  bool _collides(List<List<int>> shape, int px, int py) {
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final bx = px + c;
        final by = py + r;
        if (bx < 0 || bx >= width || by >= height) return true;
        if (by < 0) continue;
        if (board[by][bx] != 0) return true;
      }
    }
    return false;
  }

  GameState moveLeft() {
    if (isGameOver || isPaused) return this;
    if (!_collides(currentPiece.shape, currentX - 1, currentY)) {
      return _copyWith(currentX: currentX - 1);
    }
    return this;
  }

  GameState moveRight() {
    if (isGameOver || isPaused) return this;
    if (!_collides(currentPiece.shape, currentX + 1, currentY)) {
      return _copyWith(currentX: currentX + 1);
    }
    return this;
  }

  GameState moveDown() {
    if (isGameOver || isPaused) return this;
    if (!_collides(currentPiece.shape, currentX, currentY + 1)) {
      return _copyWith(currentY: currentY + 1);
    }
    return _lockPiece();
  }

  GameState hardDrop() {
    if (isGameOver || isPaused) return this;
    var dropY = currentY;
    while (!_collides(currentPiece.shape, currentX, dropY + 1)) {
      dropY++;
    }
    return _copyWith(currentY: dropY)._lockPiece();
  }

  GameState rotateCW() {
    if (isGameOver || isPaused) return this;
    final rotated = currentPiece.rotateCW();
    if (!_collides(rotated, currentX, currentY)) {
      return _copyWith(currentPiece: Tetromino(currentPiece.type, rotated, currentPiece.color));
    }
    // wall kick: try shifting left/right
    for (final offset in [1, -1, 2, -2]) {
      if (!_collides(rotated, currentX + offset, currentY)) {
        return _copyWith(
          currentPiece: Tetromino(currentPiece.type, rotated, currentPiece.color),
          currentX: currentX + offset,
        );
      }
    }
    return this;
  }

  GameState togglePause() {
    if (isGameOver) return this;
    return _copyWith(isPaused: !isPaused);
  }

  GameState _lockPiece() {
    final (newBoard, pieceAboveBoard) = _mergePieceToBoard();
    if (pieceAboveBoard) return _copyWith(isGameOver: true);

    final cleared = _clearLines(newBoard);
    final newLines = linesCleared + cleared;
    final newLevel = (newLines ~/ 10) + 1;
    final newScore = score + _scoreForLines(cleared, newLevel);
    final newHighScore = max(newScore, highScore);

    return _spawnNextPiece(newBoard, newScore, newLevel, newLines, newHighScore);
  }

  (List<List<int>>, bool) _mergePieceToBoard() {
    final newBoard = board.map((row) => List<int>.from(row)).toList();
    final shape = currentPiece.shape;
    for (var r = 0; r < shape.length; r++) {
      for (var c = 0; c < shape[r].length; c++) {
        if (shape[r][c] == 0) continue;
        final by = currentY + r;
        if (by < 0) return (newBoard, true);
        newBoard[by][currentX + c] = currentPiece.color;
      }
    }
    return (newBoard, false);
  }

  GameState _spawnNextPiece(
    List<List<int>> board,
    int newScore,
    int newLevel,
    int newLines,
    int newHighScore,
  ) {
    final newPiece = nextPiece ?? Tetromino.random();
    final spawnX = (width - newPiece.shape[0].length) ~/ 2;

    if (_collides(newPiece.shape, spawnX, 0)) {
      return _copyWith(
        board: board,
        isGameOver: true,
        score: newScore,
        level: newLevel,
        linesCleared: newLines,
        highScore: newHighScore,
      );
    }

    return _copyWith(
      board: board,
      currentPiece: newPiece,
      currentX: spawnX,
      currentY: 0,
      nextPiece: Tetromino.random(),
      score: newScore,
      level: newLevel,
      linesCleared: newLines,
      highScore: newHighScore,
    );
  }

  int _clearLines(List<List<int>> b) {
    var cleared = 0;
    for (var r = b.length - 1; r >= 0; r--) {
      if (b[r].every((cell) => cell != 0)) {
        b.removeAt(r);
        b.insert(0, List.filled(width, 0));
        cleared++;
        r++;
      }
    }
    return cleared;
  }

  int _scoreForLines(int lines, int level) {
    switch (lines) {
      case 1: return 100 * level;
      case 2: return 300 * level;
      case 3: return 500 * level;
      case 4: return 800 * level;
      default: return 0;
    }
  }

  /// 获取 ghost piece 的 Y 坐标（硬降预览位置）
  int get ghostY {
    var gy = currentY;
    while (!_collides(currentPiece.shape, currentX, gy + 1)) {
      gy++;
    }
    return gy;
  }

  GameState _copyWith({
    List<List<int>>? board,
    Tetromino? currentPiece,
    int? currentX,
    int? currentY,
    int? score,
    int? level,
    int? linesCleared,
    bool? isGameOver,
    bool? isPaused,
    Tetromino? nextPiece,
    int? highScore,
  }) {
    return GameState(
      width: width,
      height: height,
      board: board ?? this.board,
      currentPiece: currentPiece ?? this.currentPiece,
      currentX: currentX ?? this.currentX,
      currentY: currentY ?? this.currentY,
      score: score ?? this.score,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      isGameOver: isGameOver ?? this.isGameOver,
      isPaused: isPaused ?? this.isPaused,
      nextPiece: nextPiece ?? this.nextPiece,
      highScore: highScore ?? this.highScore,
    );
  }
}
