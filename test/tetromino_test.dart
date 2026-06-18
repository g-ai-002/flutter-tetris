import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/models/tetromino.dart';

void main() {
  group('Tetromino', () {
    test('create returns correct shape for each type', () {
      for (final type in TetrominoType.values) {
        final piece = Tetromino.create(type);
        expect(piece.type, type);
        expect(piece.shape.isNotEmpty, true);
        expect(piece.color, isNotNull);
      }
    });

    test('random returns valid piece', () {
      final piece = Tetromino.random();
      expect(TetrominoType.values.contains(piece.type), true);
    });

    test('I piece has 4x4 shape', () {
      final piece = Tetromino.create(TetrominoType.I);
      expect(piece.shape.length, 4);
      expect(piece.shape[0].length, 4);
    });

    test('O piece has 2x2 shape', () {
      final piece = Tetromino.create(TetrominoType.O);
      expect(piece.shape.length, 2);
      expect(piece.shape[0].length, 2);
    });

    test('rotateCW produces valid rotation', () {
      final piece = Tetromino.create(TetrominoType.T);
      final rotated = piece.rotateCW();
      expect(rotated.length, piece.shape.length);
      // T piece CW: [0,1,0],[0,1,1],[0,1,0]
      expect(rotated[1][1], 1);
      expect(rotated[1][2], 1);
    });

    test('rotateCCW produces valid rotation', () {
      final piece = Tetromino.create(TetrominoType.T);
      final rotated = piece.rotateCCW();
      expect(rotated.length, piece.shape.length);
      // T piece CCW: [0,1,0],[1,1,0],[0,1,0]
      expect(rotated[1][0], 1);
      expect(rotated[1][1], 1);
    });

    test('O piece rotation is identity', () {
      final piece = Tetromino.create(TetrominoType.O);
      expect(piece.rotateCW(), piece.shape);
      expect(piece.rotateCCW(), piece.shape);
    });
  });
}
