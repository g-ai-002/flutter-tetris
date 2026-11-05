import 'package:flutter/material.dart';
import 'package:flutter_tetris/pages/level_select_page.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('关卡选择页展示进度、星级与锁定状态', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = await prepareStorage({
      'level_records':
          '{"1":{"completed":true,"stars":3,"score":1200,"time":50000}}',
    });

    await tester.pumpWidget(
      wrapPage(child: const LevelSelectPage(), storage: storage),
    );

    expect(find.text('挑战进度'), findsOneWidget);
    expect(find.text('1 / 12'), findsOneWidget);
    expect(find.text('初入长安'), findsOneWidget);
    expect(find.text('残垣'), findsOneWidget);
    expect(find.text('最佳 1,200 分'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(10));
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });

  testWidgets('关卡选择页窄屏两列排布', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = await prepareStorage();

    await tester.pumpWidget(
      wrapPage(child: const LevelSelectPage(), storage: storage),
    );
    await tester.pump();

    expect(find.text('挑战进度'), findsOneWidget);
    expect(find.text('初入长安'), findsOneWidget);
    expect(find.text('残垣'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('点击已解锁关卡进入对局页', (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = await prepareStorage();

    await tester.pumpWidget(
      wrapPage(child: const LevelSelectPage(), storage: storage),
    );

    await tester.tap(find.byKey(const ValueKey('level-tile-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('第 1 关 · 初入长安'), findsOneWidget);
    expect(find.textContaining('剩余 01:30'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
