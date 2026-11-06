import 'package:flutter_tetris/input/action_repeat.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('立即触发一次，并按间隔重复直到停止', (tester) async {
    var count = 0;
    final repeat = ActionRepeat(onRepeat: () => count++);
    addTearDown(repeat.dispose);

    repeat.start(interval: const Duration(milliseconds: 100));
    expect(count, 1);

    await tester.pump(const Duration(milliseconds: 100));
    expect(count, 2);
    await tester.pump(const Duration(milliseconds: 200));
    expect(count, 4);

    repeat.stop();
    await tester.pump(const Duration(milliseconds: 300));
    expect(count, 4);
  });

  testWidgets('起手延迟期间不重复，延迟结束后进入固定节拍', (tester) async {
    var count = 0;
    final repeat = ActionRepeat(onRepeat: () => count++);
    addTearDown(repeat.dispose);

    repeat.start(
      interval: const Duration(milliseconds: 50),
      initialDelay: const Duration(milliseconds: 220),
    );
    expect(count, 1);

    await tester.pump(const Duration(milliseconds: 219));
    expect(count, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(count, 1);
    await tester.pump(const Duration(milliseconds: 50));
    expect(count, 2);
    repeat.stop();
  });

  testWidgets('间隔为零时只触发一次', (tester) async {
    var count = 0;
    final repeat = ActionRepeat(onRepeat: () => count++);
    addTearDown(repeat.dispose);

    repeat.start(interval: Duration.zero);
    await tester.pump(const Duration(seconds: 1));
    expect(count, 1);
    expect(repeat.isRunning, isFalse);
  });

  testWidgets('重新开始会取消上一轮定时器', (tester) async {
    var first = 0;
    var second = 0;
    final repeat = ActionRepeat(onRepeat: () => first++);
    addTearDown(repeat.dispose);

    repeat.start(interval: const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 50));

    final restarted = ActionRepeat(onRepeat: () => second++);
    addTearDown(restarted.dispose);
    repeat.stop();
    restarted.start(interval: const Duration(milliseconds: 100));

    await tester.pump(const Duration(milliseconds: 200));
    expect(first, 1);
    expect(second, 3);
    restarted.stop();
  });
}
