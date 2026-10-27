import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_record.dart';
import 'log_service.dart';

/// Web 平台历史记录：浏览器没有可写目录，改存 SharedPreferences（localStorage）。
///
/// 与 IO 实现保持相同的公开 API；读写失败时降级为仅在当前会话内保留记录。
class HistoryService {
  static HistoryService? _instance;
  static const String _prefsKey = 'tetris_history_records';

  List<GameRecord> _records = [];
  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _testing = false;

  HistoryService._();

  static Future<void> init() async {
    _instance ??= HistoryService._();
    await _instance!._init();
  }

  Future<void> _init() async {
    if (_initialized) return;
    if (!_testing) {
      try {
        _prefs = await SharedPreferences.getInstance();
        await _load();
      } catch (e) {
        LogService.error('加载历史记录失败', e);
        _records = [];
      }
    }
    _initialized = true;
    LogService.info('历史记录服务初始化: ${_records.length} 条记录');
  }

  Future<void> _load() async {
    final raw = _prefs?.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _records = list
          .map((e) => GameRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      _records.sort((a, b) => b.score.compareTo(a.score));
    } catch (e) {
      LogService.error('解析历史记录失败', e);
      _records = [];
    }
  }

  Future<void> _save() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final list = _records.map((r) => r.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(list));
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
    _instance ??= HistoryService._();
    _instance!._records.clear();
    _instance!._initialized = false;
    _instance!._testing = true;
    _instance!._prefs = null;
  }
}
