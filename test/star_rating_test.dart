import 'package:flutter/material.dart';
import 'package:flutter_tetris/pages/widgets/star_rating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('星级组件按数量显示实心与空心星', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StarRating(stars: 2))),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('星级组件支持自定义上限', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StarRating(stars: 1, max: 5))),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(4));
  });
}
