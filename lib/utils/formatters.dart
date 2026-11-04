/// 全局格式化工具。
library;

String pad2(int value) => value.toString().padLeft(2, '0');

/// `yyyyMMdd`，用于日志文件名。
String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}${pad2(date.month)}${pad2(date.day)}';

/// 整数千分位：`12345` -> `12,345`。
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// `mm:ss`，满一小时显示 `h:mm:ss`。
String formatDuration(int milliseconds) {
  final total = (milliseconds / 1000).ceil();
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  return hours > 0
      ? '$hours:${pad2(minutes)}:${pad2(seconds)}'
      : '${pad2(minutes)}:${pad2(seconds)}';
}

/// `mm:ss.cc`，竞速成绩使用百分秒。
String formatPreciseDuration(int milliseconds) {
  final safe = milliseconds < 0 ? 0 : milliseconds;
  final minutes = safe ~/ 60000;
  final seconds = (safe % 60000) ~/ 1000;
  final centis = (safe % 1000) ~/ 10;
  return '${pad2(minutes)}:${pad2(seconds)}.${pad2(centis)}';
}

/// `HH:mm:ss.SSS`，日志行首时间戳。
String formatLogTimestamp(DateTime time) =>
    '${pad2(time.hour)}:${pad2(time.minute)}:${pad2(time.second)}.'
    '${time.millisecond.toString().padLeft(3, '0')}';

String formatLogLine(DateTime time, String level, String message) =>
    '[${formatLogTimestamp(time)}][$level] $message';
