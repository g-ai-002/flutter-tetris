import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tetris/services/history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameRecord', () {
    test('toJson and fromJson roundtrip', () {
      final record = GameRecord(
        score: 500,
        level: 3,
        linesCleared: 12,
        date: DateTime(2026, 6, 19, 14, 30),
      );
      final json = record.toJson();
      expect(json['score'], 500);
      expect(json['level'], 3);
      expect(json['linesCleared'], 12);
      expect(json['date'], '2026-06-19T14:30:00.000');

      final restored = GameRecord.fromJson(json);
      expect(restored.score, 500);
      expect(restored.level, 3);
      expect(restored.linesCleared, 12);
      expect(restored.date, DateTime(2026, 6, 19, 14, 30));
    });
  });

  group('HistoryService', () {
    setUp(() async {
      HistoryService.resetForTest();
      await HistoryService.init();
    });

    test('init creates empty records', () {
      final records = HistoryService.getRecords();
      expect(records, isEmpty);
    });

    test('addRecord stores and sorts by score desc', () async {
      await HistoryService.addRecord(score: 100, level: 1, linesCleared: 2);
      await HistoryService.addRecord(score: 500, level: 3, linesCleared: 10);
      await HistoryService.addRecord(score: 300, level: 2, linesCleared: 6);

      final records = HistoryService.getRecords();
      expect(records.length, 3);
      expect(records[0].score, 500);
      expect(records[1].score, 300);
      expect(records[2].score, 100);
    });

    test('clearAll removes all records', () async {
      await HistoryService.addRecord(score: 100, level: 1, linesCleared: 2);
      expect(HistoryService.getRecords().length, 1);

      await HistoryService.clearAll();
      expect(HistoryService.getRecords(), isEmpty);
    });

    test('getRecords returns unmodifiable list', () {
      final records = HistoryService.getRecords();
      expect(() => (records as List).add(GameRecord(score: 0, level: 0, linesCleared: 0, date: DateTime.now())),
          throwsUnsupportedError);
    });
  });
}
