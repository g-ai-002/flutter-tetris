import 'package:flutter/material.dart';
import 'package:flutter_tetris/pages/settings_page.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    storage = await prepareStorage();
  });

  testWidgets('设置页可以切换外观、幽灵块、网格与音频开关', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(child: const SettingsPage(), storage: storage),
    );

    expect(find.text('外观与操作'), findsOneWidget);
    expect(find.text('音效与反馈'), findsOneWidget);
    expect(find.text('运行日志'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('switch-dark')));
    await tester.pump();
    expect(storage.darkMode, isTrue);

    await tester.tap(find.byKey(const ValueKey('switch-ghost')));
    await tester.pump();
    expect(storage.showGhost, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-grid')));
    await tester.pump();
    expect(storage.showGrid, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-sound')));
    await tester.pump();
    expect(storage.soundEnabled, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-haptics')));
    await tester.pump();
    expect(storage.hapticsEnabled, isFalse);
  });

  testWidgets('设置页可以打开玩法说明', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(child: const SettingsPage(), storage: storage),
    );

    await tester.scrollUntilVisible(
      find.text('查看玩法与键位'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('查看玩法与键位'));
    await tester.pumpAndSettle();
    expect(find.text('玩法与操作'), findsOneWidget);
    expect(find.textContaining('堆叠方块填满整行即可消除'), findsOneWidget);
  });
}
