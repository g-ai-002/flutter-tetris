import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/widgets/gesture_control.dart';

void main() {
  group('GestureControl.directionFromDelta', () {
    test('picks the dominant axis', () {
      expect(GestureControl.directionFromDelta(const Offset(20, 0)), GestureDirection.right);
      expect(GestureControl.directionFromDelta(const Offset(-20, 0)), GestureDirection.left);
      expect(GestureControl.directionFromDelta(const Offset(0, 20)), GestureDirection.down);
      expect(GestureControl.directionFromDelta(const Offset(0, -20)), GestureDirection.up);
      expect(GestureControl.directionFromDelta(const Offset(8, 30)), GestureDirection.down);
      expect(GestureControl.directionFromDelta(const Offset(30, 8)), GestureDirection.right);
    });
  });

  group('GestureControl widget', () {
    Widget build(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

    testWidgets('tap triggers onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(build(GestureControl(
        onTap: () => taps++,
        onSwipe: (_) {},
        child: const SizedBox(width: 200, height: 200),
      )));
      await tester.tap(find.byType(GestureControl));
      expect(taps, 1);
    });

    testWidgets('swipe reports its direction', (tester) async {
      final swipes = <GestureDirection>[];
      await tester.pumpWidget(build(GestureControl(
        onTap: () {},
        onSwipe: swipes.add,
        child: const SizedBox(width: 200, height: 200),
      )));
      await tester.drag(find.byType(GestureControl), const Offset(-60, 0));
      await tester.pump();
      expect(swipes, [GestureDirection.left]);
    });

    testWidgets('swipe shorter than threshold is ignored', (tester) async {
      final swipes = <GestureDirection>[];
      await tester.pumpWidget(build(GestureControl(
        onTap: () {},
        onSwipe: swipes.add,
        child: const SizedBox(width: 200, height: 200),
      )));
      await tester.drag(find.byType(GestureControl), const Offset(-4, 0));
      await tester.pump();
      expect(swipes, isEmpty);
    });
  });
}
