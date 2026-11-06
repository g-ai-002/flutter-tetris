import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tetris/input/key_bindings.dart';
import 'package:flutter_tetris/pages/settings_page.dart';
import 'package:flutter_tetris/services/storage_service.dart';
import 'package:flutter_tetris/theme/block_skin.dart';
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
    expect(find.text('键位与手柄'), findsOneWidget);
    expect(find.text('硬降 Y / RB / ↑'), findsOneWidget);

    expect(find.text('棋盘皮肤'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('skin-celadon')));
    await tester.pump();
    expect(storage.blockSkin, BlockSkin.celadon);
    expect(find.text('青瓷 · 雨过天青，温润如玉'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('switch-dark')));
    await tester.pump();
    expect(storage.darkMode, isTrue);

    await tester.tap(find.byKey(const ValueKey('switch-ghost')));
    await tester.pump();
    expect(storage.showGhost, isFalse);

    await tester.tap(find.byKey(const ValueKey('switch-grid')));
    await tester.pump();
    expect(storage.showGrid, isFalse);

    await tester.ensureVisible(find.byKey(const ValueKey('switch-sound')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch-sound')));
    await tester.pump();
    expect(storage.soundEnabled, isFalse);

    await tester.ensureVisible(find.byKey(const ValueKey('switch-haptics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('switch-haptics')));
    await tester.pump();
    expect(storage.hapticsEnabled, isFalse);

    await tester.scrollUntilVisible(
      find.text('运行日志'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('运行日志'), findsOneWidget);
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
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('查看玩法与键位'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看玩法与键位'));
    await tester.pumpAndSettle();
    expect(find.text('玩法与操作'), findsOneWidget);
    expect(find.textContaining('堆叠方块填满整行即可消除'), findsOneWidget);
    expect(find.text('硬降 Y / RB / ↑'), findsWidgets);
  });

  testWidgets('设置页可以重新绑定按键并恢复默认', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrapPage(child: const SettingsPage(), storage: storage),
    );

    expect(find.text('键位与手柄'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bind-moveLeft')));
    await tester.pumpAndSettle();
    expect(find.text('绑定「左移」'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();
    expect(
      storage.keyBindings.primaryKey(GameAction.moveLeft),
      LogicalKeyboardKey.keyA,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('reset-keys')));
    await tester.tap(find.byKey(const ValueKey('reset-keys')));
    await tester.pump();
    expect(
      storage.keyBindings.primaryKey(GameAction.moveLeft),
      LogicalKeyboardKey.arrowLeft,
    );
    expect(find.text('A'), findsNothing);
  });
}
