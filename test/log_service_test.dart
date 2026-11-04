import 'dart:io';

import 'package:flutter_tetris/services/log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('日志服务', () {
    late Directory dir;

    setUp(() async {
      LogService.reset();
      dir = await Directory.systemTemp.createTemp('tetris_log_test');
    });

    tearDown(() async {
      LogService.reset();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('按天写入日志并保留内存缓冲', () async {
      final clock = DateTime(2026, 11, 4, 10, 30);
      await LogService.init(logRoot: () async => dir, clock: () => clock);
      LogService.info('开局');
      LogService.warning('网络无关警告');
      LogService.error('异常', StateError('boom'));

      final file = File('${dir.path}/app_20261104.log');
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('开局'));
      expect(content, contains('WARN'));
      expect(content, contains('boom'));
      expect(LogService.getRecentLogs(10), isNotEmpty);
      expect(LogService.logFilePath, file.path);
    });

    test('初始化前的日志在初始化后补写', () async {
      LogService.info('启动早期日志');
      await LogService.init(logRoot: () async => dir);
      final files = dir.listSync().whereType<File>().toList();
      expect(files, isNotEmpty);
      final content = await files.first.readAsString();
      expect(content, contains('启动早期日志'));
    });

    test('日志目录不可用时降级为内存模式', () async {
      await LogService.init(
        logRoot: () async => throw const FileSystemException('denied'),
      );
      LogService.info('仍然可用');
      expect(LogService.getRecentLogs().join(), contains('仍然可用'));
      expect(LogService.logFilePath, '');
    });

    test('日志行格式包含时间与级别', () async {
      await LogService.init(
        logRoot: () async => dir,
        clock: () => DateTime(2026, 1, 2, 3, 4, 5, 6),
      );
      LogService.error('格式检查');
      final content = await File('${dir.path}/app_20260102.log').readAsString();
      expect(content, contains('[03:04:05.006][ERROR] 格式检查'));
    });
  });
}
