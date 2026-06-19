import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/utils/constants.dart';

void main() {
  group('AppConstants', () {
    test('board dimensions are correct', () {
      expect(AppConstants.boardWidth, 10);
      expect(AppConstants.boardHeight, 20);
    });

    test('app name is set', () {
      expect(AppConstants.appName, '俄罗斯方块');
    });

    test('version is 0.4.0', () {
      expect(AppConstants.version, '0.4.0');
    });
  });
}
