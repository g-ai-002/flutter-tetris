import 'package:flutter/material.dart';
import 'package:flutter_tetris/pages/widgets/hero_board_preview.dart';
import 'package:flutter_tetris/theme/block_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(BlockPalette palette) => MaterialApp(
    home: Scaffold(body: Center(child: HeroBoardPreview(palette: palette))),
  );

  CustomPainter painterOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(HeroBoardPreview),
        matching: find.byType(CustomPaint),
      ),
    );
    return paint.painter!;
  }

  testWidgets('缩略棋盘在浅色皮肤之间切换时重绘', (tester) async {
    await tester.pumpWidget(host(BlockPalette.light));
    final paper = painterOf(tester);

    await tester.pumpWidget(host(BlockSkin.celadon.palette(dark: false)));
    final celadon = painterOf(tester);
    expect(celadon.shouldRepaint(paper), isTrue);

    await tester.pumpWidget(host(BlockSkin.celadon.palette(dark: false)));
    final same = painterOf(tester);
    expect(same.shouldRepaint(celadon), isFalse);
  });

  testWidgets('缩略棋盘在深浅色切换时重绘', (tester) async {
    await tester.pumpWidget(host(BlockPalette.light));
    final light = painterOf(tester);

    await tester.pumpWidget(host(BlockPalette.darkPalette));
    final dark = painterOf(tester);
    expect(dark.shouldRepaint(light), isTrue);
  });
}
