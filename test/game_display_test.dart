import 'package:flutter/services.dart';
import 'package:flutter_tetris/utils/game_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  List<String> methods() => calls.map((call) => call.method).toList();

  test('进入对局只切换沉浸模式，不锁定屏幕方向', () async {
    await enterGameDisplay();
    expect(methods(), contains('SystemChrome.setEnabledSystemUIMode'));
    expect(methods(), isNot(contains('SystemChrome.setPreferredOrientations')));
  });

  test('离开对局恢复系统栏，屏幕方向仍交给系统', () async {
    await exitGameDisplay();
    expect(methods(), contains('SystemChrome.setEnabledSystemUIMode'));
    expect(methods(), isNot(contains('SystemChrome.setPreferredOrientations')));
  });
}
