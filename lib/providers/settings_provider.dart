import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';

// 设置服务Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// 设置状态Provider
final settingsProvider = StateNotifierProvider<SettingsController, QuizSettings>((ref) {
  final settingsService = ref.read(settingsServiceProvider);
  return SettingsController(settingsService);
});

// 设置控制器
class SettingsController extends StateNotifier<QuizSettings> {
  final SettingsService _settingsService;

  SettingsController(this._settingsService) : super(const QuizSettings()) {
    _loadSettings();
  }

  // 加载设置
  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.loadSettings();
      state = settings;
    } catch (e) {
      // 如果加载失败，保持默认设置
      state = const QuizSettings();
    }
  }

  // 更新单选题数量
  Future<void> updateSingleChoiceCount(int count) async {
    final newSettings = state.copyWith(singleChoiceCount: count);
    await _saveSettings(newSettings);
  }

  // 更新多选题数量
  Future<void> updateMultipleChoiceCount(int count) async {
    final newSettings = state.copyWith(multipleChoiceCount: count);
    await _saveSettings(newSettings);
  }

  // 更新判断题数量
  Future<void> updateBooleanCount(int count) async {
    final newSettings = state.copyWith(booleanCount: count);
    await _saveSettings(newSettings);
  }

  // 更新选项乱序设置
  Future<void> updateShuffleOptions(bool shuffle) async {
    final newSettings = state.copyWith(shuffleOptions: shuffle);
    await _saveSettings(newSettings);
  }

  // 更新快速切题设置
  Future<void> updateAutoNextQuestion(bool autoNext) async {
    final newSettings = state.copyWith(autoNextQuestion: autoNext);
    await _saveSettings(newSettings);
  }

  // 批量更新设置
  Future<void> updateSettings(QuizSettings settings) async {
    await _saveSettings(settings);
  }

  // 重置设置
  Future<void> resetSettings() async {
    await _settingsService.resetSettings();
    state = const QuizSettings();
  }

  // 保存设置
  Future<void> _saveSettings(QuizSettings settings) async {
    try {
      await _settingsService.saveSettings(settings);
      state = settings;
    } catch (e) {
      // 保存失败时不更新状态
      rethrow;
    }
  }
}
