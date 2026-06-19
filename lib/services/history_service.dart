import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'log_service.dart';

class GameRecord {
  final int score;
  final int level;
  final int linesCleared;
  final DateTime date;

  const GameRecord({
    required this.score,
    required this.level,
    required this.linesCleared,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'level': level,
        'linesCleared': linesCleared,
        'date': date.toIso8601String(),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        score: json['score'] as int,
        level: json['level'] as int,
        linesCleared: json['linesCleared'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

class HistoryService {
  static HistoryService? _instance;
  File? _file;
  List<GameRecord> _records = [];
  bool _initialized = false;
  bool _testing = false;

  HistoryService._();

  static Future<void> init() async {
    _instance ??= HistoryService._();
    await _instance!._init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    if (_testing) {
      _initialized = true;
      LogService.info('历史记录服务初始化(测试模式)');
      return;
    }
    final dir = await _getDataDir();
    _file = File('${dir.path}${Platform.pathSeparator}history.json');
    await _load();
    _initialized = true;
    LogService.info('历史记录服务初始化: ${_records.length} 条记录');
  }

  Future<Directory> _getDataDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${base.path}${Platform.pathSeparator}FlutterTetris',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _load() async {
    try {
      if (await _file!.exists()) {
        final content = await _file!.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _records = list
            .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        _records.sort((a, b) => b.score.compareTo(a.score));
      }
    } catch (e) {
      LogService.error('加载历史记录失败', e);
      _records = [];
    }
  }

  Future<void> _save() async {
    try {
      final list = _records.map((r) => r.toJson()).toList();
      await _file!.writeAsString(jsonEncode(list));
    } catch (e) {
      LogService.error('保存历史记录失败', e);
    }
  }

  static Future<void> addRecord({
    required int score,
    required int level,
    required int linesCleared,
  }) async {
    if (_instance == null) return;
    final record = GameRecord(
      score: score,
      level: level,
      linesCleared: linesCleared,
      date: DateTime.now(),
    );
    _instance!._records.add(record);
    _instance!._records.sort((a, b) => b.score.compareTo(a.score));
    if (!_instance!._testing) await _instance!._save();
    LogService.info('保存游戏记录: 分数=$score, 等级=$level, 行数=$linesCleared');
  }

  static List<GameRecord> getRecords() {
    if (_instance == null) return [];
    return List.unmodifiable(_instance!._records);
  }

  static Future<void> clearAll() async {
    if (_instance == null) return;
    _instance!._records.clear();
    if (!_instance!._testing) await _instance!._save();
    LogService.info('历史记录已清空');
  }

  static void resetForTest() {
    _instance?._records.clear();
    _instance?._initialized = false;
    _instance?._testing = true;
    _instance?._file = null;
  }
}
