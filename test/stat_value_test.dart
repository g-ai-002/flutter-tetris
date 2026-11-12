import 'package:flutter/material.dart';
import 'package:flutter_tetris/pages/widgets/stat_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('数值、后缀与标签一起展示，数值使用等宽数字', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatValue(label: '累计消行', value: '1,280', suffix: '行', center: true),
        ),
      ),
    );

    expect(find.text('1,280'), findsOneWidget);
    expect(find.text('行'), findsOneWidget);
    expect(find.text('累计消行'), findsOneWidget);

    final value = tester.widget<Text>(find.text('1,280'));
    expect(value.style?.fontFeatures, contains(const FontFeature.tabularFigures()));
  });

  testWidgets('labelFirst 把标签排在数值上方', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatValue(label: '剩余', value: '01:20', labelFirst: true),
        ),
      ),
    );

    final labelY = tester.getTopLeft(find.text('剩余')).dy;
    final valueY = tester.getTopLeft(find.text('01:20')).dy;
    expect(labelY, lessThan(valueY));
  });

  testWidgets('inline 布局把标签与数值放在同一行', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: StatValue.inline(label: '最高连击', value: '12'),
          ),
        ),
      ),
    );

    final row = find.descendant(of: find.byType(StatValue), matching: find.byType(Row));
    expect(row, findsOneWidget);
    expect(tester.getCenter(find.text('最高连击')).dy, tester.getCenter(find.text('12')).dy);
  });

  testWidgets('强调色只作用于数值', (tester) async {
    const accent = Colors.orange;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatValue(label: '最高分', value: '9,999', accent: accent),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('9,999')).style?.color, accent);
    expect(tester.widget<Text>(find.text('最高分')).style?.color, isNot(accent));
  });
}
