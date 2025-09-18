import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import 'quiz_provider.dart';

// 设置服务Provider
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// 设置状态Provider
final settingsProvider =
    StateNotifierProvider<SettingsController, QuizSettings>((ref) {
      final settingsService = ref.read(settingsServiceProvider);
      return SettingsController(settingsService, ref);
    });

// 设置控制器
class SettingsController extends StateNotifier<QuizSettings> {
  final SettingsService _settingsService;
  final Ref _ref;

  SettingsController(this._settingsService, this._ref)
    : super(const QuizSettings()) {
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

    // 通知 QuizProvider 更新选项顺序（如果正在答题中）
    try {
      final quizController = _ref.read(quizControllerProvider.notifier);
      quizController.updateShuffleOptions(shuffle);
    } catch (e) {
      // 如果 QuizProvider 不可用或出错，忽略错误
      // 这种情况通常发生在没有进行答题时
    }
  }

  // 更新快速切题设置
  Future<void> updateAutoNextQuestion(bool autoNext) async {
    final newSettings = state.copyWith(autoNextQuestion: autoNext);
    await _saveSettings(newSettings);
  }

  // 更新进度保存设置
  Future<void> updateEnableProgressSave(bool enable) async {
    final newSettings = state.copyWith(enableProgressSave: enable);
    await _saveSettings(newSettings);
  }

  // 更新考试时间设置
  Future<void> updateExamTimeMinutes(int minutes) async {
    final newSettings = state.copyWith(examTimeMinutes: minutes);
    await _saveSettings(newSettings);
  }

  // 更新品鉴模式香型设置
  Future<void> updateEnableBlindTasteAroma(bool enable) async {
    final newSettings = state.copyWith(enableBlindTasteAroma: enable);
    await _saveSettings(newSettings);
  }

  // 更新品鉴模式酒度设置
  Future<void> updateEnableBlindTasteAlcohol(bool enable) async {
    final newSettings = state.copyWith(enableBlindTasteAlcohol: enable);
    await _saveSettings(newSettings);
  }

  // 更新品鉴模式总分设置
  Future<void> updateEnableBlindTasteScore(bool enable) async {
    final newSettings = state.copyWith(enableBlindTasteScore: enable);
    await _saveSettings(newSettings);
  }

  // 更新品鉴模式设备设置
  Future<void> updateEnableBlindTasteEquipment(bool enable) async {
    final newSettings = state.copyWith(enableBlindTasteEquipment: enable);
    await _saveSettings(newSettings);
  }

  // 更新品鉴模式发酵剂设置
  Future<void> updateEnableBlindTasteFermentation(bool enable) async {
    final newSettings = state.copyWith(enableBlindTasteFermentation: enable);
    await _saveSettings(newSettings);
  }

  // 更新品鉴模式随机顺序设置
  Future<void> updateEnableBlindTasteRandomOrder(bool enable) async {
    final newSettings = state.copyWith(enableBlindTasteRandomOrder: enable);
    await _saveSettings(newSettings);
  }

  // 更新闪卡随机顺序设置
  Future<void> updateEnableFlashcardRandomOrder(bool enable) async {
    final newSettings = state.copyWith(enableFlashcardRandomOrder: enable);
    await _saveSettings(newSettings);
  }

  // 更新默认继续进度设置
  Future<void> updateEnableDefaultContinueProgress(bool enable) async {
    final newSettings = state.copyWith(enableDefaultContinueProgress: enable);
    await _saveSettings(newSettings);
  }

  // 更新练习模式乱序模式设置
  Future<void> updatePracticeShuffleMode(PracticeShuffleMode mode) async {
    final newSettings = state.copyWith(practiceShuffleMode: mode);
    await _saveSettings(newSettings);
  }

  // 兼容性方法：更新练习模式随机顺序设置
  Future<void> updateEnablePracticeRandomOrder(bool enable) async {
    final mode = enable
        ? PracticeShuffleMode.fullRandom
        : PracticeShuffleMode.ordered;
    await updatePracticeShuffleMode(mode);
  }

  // 更新酒样练习模式酒杯数量设置
  Future<void> updateWineSimulationSampleCount(int count) async {
    final newSettings = state.copyWith(wineSimulationSampleCount: count);
    await _saveSettings(newSettings);
  }

  // 更新酒样练习重复概率设置
  Future<void> updateWineSimulationDuplicateProbability(
    double probability,
  ) async {
    final newSettings = state.copyWith(
      wineSimulationDuplicateProbability: probability,
    );
    await _saveSettings(newSettings);
  }

  // 更新酒样练习最大重复组数设置
  Future<void> updateWineSimulationMaxDuplicateGroups(int maxGroups) async {
    final newSettings = state.copyWith(
      wineSimulationMaxDuplicateGroups: maxGroups,
    );
    await _saveSettings(newSettings);
  }

  // 更新多选题自动切题延迟设置
  Future<void> updateMultipleChoiceAutoSwitchDelay(int delayMs) async {
    final newSettings = state.copyWith(
      multipleChoiceAutoSwitchDelay: delayMs,
    );
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
