import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tetris/utils/game_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  List<String> methods() => calls.map((call) => call.method).toList();

  test('手机端进入沉浸模式，不锁定屏幕方向', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await enterImmersiveDisplay();
    expect(methods(), contains('SystemChrome.setEnabledSystemUIMode'));
    expect(methods(), isNot(contains('SystemChrome.setPreferredOrientations')));
    final arguments = calls
        .firstWhere((call) => call.method == 'SystemChrome.setEnabledSystemUIMode')
        .arguments;
    expect(arguments, 'SystemUiMode.immersiveSticky');
  });

  test('桌面端不处理系统栏', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await enterImmersiveDisplay();
    expect(methods(), isEmpty);
  });
}
