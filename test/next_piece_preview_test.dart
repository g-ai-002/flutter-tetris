import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/game/next_piece_game.dart';

void main() {
  test('下一个方块预览不铺底色', () {
    expect(NextPieceGame().backgroundColor(), Colors.transparent);
  });
}
