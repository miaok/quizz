import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/score_record_model.dart';

/// 得分记录服务
class ScoreRecordService {
  static const String _scoreRecordsKey = 'score_records';

  static final ScoreRecordService _instance = ScoreRecordService._internal();
  factory ScoreRecordService() => _instance;
  ScoreRecordService._internal();

  SharedPreferences? _prefs;

  /// 初始化
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 保存得分记录
  Future<void> saveScoreRecord(ScoreRecord record) async {
    await initialize();

    try {
      // 获取现有记录
      final records = await loadScoreRecords();

      // 添加新记录到列表开头（最新的在前面）
      records.insert(0, record);

      // 限制记录数量（保留最近100条记录）
      if (records.length > 100) {
        records.removeRange(100, records.length);
      }

      // 转换为JSON并保存
      final jsonList = records.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _prefs!.setString(_scoreRecordsKey, jsonString);
      debugPrint('Score record saved successfully. Total records: ${records.length}');
    } catch (e) {
      debugPrint('Error saving score record: $e');
      rethrow;
    }
  }

  /// 加载所有得分记录
  Future<List<ScoreRecord>> loadScoreRecords() async {
    await initialize();

    try {
      final jsonString = _prefs!.getString(_scoreRecordsKey);
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('No score records found');
        return [];
      }

      final jsonList = json.decode(jsonString) as List<dynamic>;
      final records = jsonList
          .map((json) => ScoreRecord.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('Loaded ${records.length} score records');
      return records;
    } catch (e) {
      debugPrint('Error loading score records: $e');
      // 如果数据损坏，清除并返回空列表
      await clearScoreRecords();
      return [];
    }
  }

  /// 清除所有得分记录
  Future<void> clearScoreRecords() async {
    await initialize();

    try {
      await _prefs!.remove(_scoreRecordsKey);
      debugPrint('All score records cleared');
    } catch (e) {
      debugPrint('Error clearing score records: $e');
      rethrow;
    }
  }

  /// 检查是否有得分记录
  Future<bool> hasScoreRecords() async {
    final records = await loadScoreRecords();
    return records.isNotEmpty;
  }

  /// 获取记录数量
  Future<int> getRecordCount() async {
    final records = await loadScoreRecords();
    return records.length;
  }

  /// 获取最高分记录
  Future<ScoreRecord?> getHighestScoreRecord() async {
    final records = await loadScoreRecords();
    if (records.isEmpty) return null;

    records.sort((a, b) => b.score.compareTo(a.score));
    return records.first;
  }

  /// 获取最近的记录
  Future<ScoreRecord?> getLatestRecord() async {
    final records = await loadScoreRecords();
    if (records.isEmpty) return null;

    records.sort((a, b) => b.examTime.compareTo(a.examTime));
    return records.first;
  }

  /// 获取平均分
  Future<double> getAverageScore() async {
    final records = await loadScoreRecords();
    if (records.isEmpty) return 0.0;

    final totalScore = records.fold(0.0, (sum, record) => sum + record.score);
    return totalScore / records.length;
  }

  /// 获取统计信息
  Future<Map<String, dynamic>> getStatistics() async {
    final records = await loadScoreRecords();
    if (records.isEmpty) {
      return {
        'count': 0,
        'averageScore': 0.0,
        'highestScore': 0.0,
        'latestScore': 0.0,
      };
    }

    final scores = records.map((r) => r.score).toList();
    scores.sort((a, b) => b.compareTo(a));

    return {
      'count': records.length,
      'averageScore': await getAverageScore(),
      'highestScore': scores.first,
      'latestScore': records.first.score,
    };
  }

  /// 删除指定记录
  Future<void> deleteRecord(ScoreRecord recordToDelete) async {
    await initialize();

    try {
      final records = await loadScoreRecords();
      records.removeWhere((record) =>
          record.examTime == recordToDelete.examTime &&
          record.score == recordToDelete.score);

      // 保存更新后的记录
      final jsonList = records.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await _prefs!.setString(_scoreRecordsKey, jsonString);
      debugPrint('Score record deleted. Remaining records: ${records.length}');
    } catch (e) {
      debugPrint('Error deleting score record: $e');
      rethrow;
    }
  }
}