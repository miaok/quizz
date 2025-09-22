import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'quiz_settings';
  
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // 初始化
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // 保存设置
  Future<void> saveSettings(QuizSettings settings) async {
    await initialize();
    final jsonString = json.encode(settings.toJson());
    await _prefs!.setString(_settingsKey, jsonString);
    debugPrint('Settings saved: $jsonString');
  }

  // 加载设置
  Future<QuizSettings> loadSettings() async {
    await initialize();
    final jsonString = _prefs!.getString(_settingsKey);
    
    if (jsonString != null) {
      try {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final settings = QuizSettings.fromJson(jsonMap);
        debugPrint('Settings loaded: $jsonString');
        return settings;
      } catch (e) {
        debugPrint('Error loading settings: $e');
        return const QuizSettings(); // 返回默认设置
      }
    }
    
    debugPrint('No settings found, using defaults');
    return const QuizSettings(); // 返回默认设置
  }

  // 重置设置
  Future<void> resetSettings() async {
    await initialize();
    await _prefs!.remove(_settingsKey);
    debugPrint('Settings reset to defaults');
  }

  // 彻底重置所有设置数据
  Future<void> completeReset() async {
    await initialize();

    try {
      // 清除设置相关的所有数据
      await _prefs!.remove(_settingsKey);
      debugPrint('All settings data cleared');
    } catch (e) {
      debugPrint('Error during settings complete reset: $e');
      rethrow;
    }
  }
}
