import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blind_taste_model.dart';
import '../models/progress_model.dart';
import '../services/blind_taste_service.dart';
import '../services/progress_service.dart';

/// 品鉴服务Provider
final blindTasteServiceProvider = Provider<BlindTasteService>((ref) {
  return BlindTasteService();
});

/// 品鉴进度服务Provider
final blindTasteProgressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
});

/// 当前品鉴题目状态
class BlindTasteState {
  final BlindTasteItemModel? currentItem;
  final BlindTasteAnswer userAnswer;
  final int currentIndex;
  final bool isCompleted;
  final double? finalScore;
  final bool isLoading;
  final String? error;

  const BlindTasteState({
    this.currentItem,
    required this.userAnswer,
    this.currentIndex = 0,
    this.isCompleted = false,
    this.finalScore,
    this.isLoading = false,
    this.error,
  });

  BlindTasteState copyWith({
    BlindTasteItemModel? currentItem,
    BlindTasteAnswer? userAnswer,
    int? currentIndex,
    bool? isCompleted,
    double? finalScore,
    bool? isLoading,
    String? error,
  }) {
    return BlindTasteState(
      currentItem: currentItem ?? this.currentItem,
      userAnswer: userAnswer ?? this.userAnswer,
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      finalScore: finalScore ?? this.finalScore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 品鉴状态管理器
class BlindTasteNotifier extends StateNotifier<BlindTasteState> {
  final BlindTasteService _service;
  final ProgressService _progressService;

  BlindTasteNotifier(this._service, this._progressService)
    : super(BlindTasteState(userAnswer: BlindTasteAnswer()));

  /// 开始新的品鉴
  Future<void> startNewTasting() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.initialize();
      final item = await _service.getRandomItem();

      if (item == null) {
        state = state.copyWith(isLoading: false, error: '没有可用的品鉴数据');
        return;
      }

      state = state.copyWith(
        currentItem: item,
        userAnswer: BlindTasteAnswer(),
        currentIndex: 0,
        isCompleted: false,
        finalScore: null,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载品鉴数据失败: $e');
    }
  }

  /// 选择香型
  void selectAroma(String aroma) {
    final newAnswer = BlindTasteAnswer(
      selectedAroma: aroma,
      selectedAlcoholDegree: state.userAnswer.selectedAlcoholDegree,
      selectedTotalScore: state.userAnswer.selectedTotalScore,
      selectedEquipment: List.from(state.userAnswer.selectedEquipment),
      selectedFermentationAgent: List.from(
        state.userAnswer.selectedFermentationAgent,
      ),
    );

    state = state.copyWith(userAnswer: newAnswer);

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 选择酒度
  void selectAlcoholDegree(double degree) {
    final newAnswer = BlindTasteAnswer(
      selectedAroma: state.userAnswer.selectedAroma,
      selectedAlcoholDegree: degree,
      selectedTotalScore: state.userAnswer.selectedTotalScore,
      selectedEquipment: List.from(state.userAnswer.selectedEquipment),
      selectedFermentationAgent: List.from(
        state.userAnswer.selectedFermentationAgent,
      ),
    );

    state = state.copyWith(userAnswer: newAnswer);

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 调整总分
  void adjustTotalScore(double delta) {
    final newScore = (state.userAnswer.selectedTotalScore + delta).clamp(
      0.0,
      100.0,
    );

    final newAnswer = BlindTasteAnswer(
      selectedAroma: state.userAnswer.selectedAroma,
      selectedAlcoholDegree: state.userAnswer.selectedAlcoholDegree,
      selectedTotalScore: newScore,
      selectedEquipment: List.from(state.userAnswer.selectedEquipment),
      selectedFermentationAgent: List.from(
        state.userAnswer.selectedFermentationAgent,
      ),
    );

    state = state.copyWith(userAnswer: newAnswer);

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 切换设备选择
  void toggleEquipment(String equipment) {
    final currentEquipment = List<String>.from(
      state.userAnswer.selectedEquipment,
    );

    if (currentEquipment.contains(equipment)) {
      currentEquipment.remove(equipment);
    } else {
      currentEquipment.add(equipment);
    }

    final newAnswer = BlindTasteAnswer(
      selectedAroma: state.userAnswer.selectedAroma,
      selectedAlcoholDegree: state.userAnswer.selectedAlcoholDegree,
      selectedTotalScore: state.userAnswer.selectedTotalScore,
      selectedEquipment: currentEquipment,
      selectedFermentationAgent: List.from(
        state.userAnswer.selectedFermentationAgent,
      ),
    );

    state = state.copyWith(userAnswer: newAnswer);

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 切换发酵剂选择
  void toggleFermentationAgent(String agent) {
    final currentAgents = List<String>.from(
      state.userAnswer.selectedFermentationAgent,
    );

    if (currentAgents.contains(agent)) {
      currentAgents.remove(agent);
    } else {
      currentAgents.add(agent);
    }

    final newAnswer = BlindTasteAnswer(
      selectedAroma: state.userAnswer.selectedAroma,
      selectedAlcoholDegree: state.userAnswer.selectedAlcoholDegree,
      selectedTotalScore: state.userAnswer.selectedTotalScore,
      selectedEquipment: List.from(state.userAnswer.selectedEquipment),
      selectedFermentationAgent: currentAgents,
    );

    state = state.copyWith(userAnswer: newAnswer);

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 提交答案并计算得分
  void submitAnswer() {
    if (state.currentItem == null) return;

    final score = state.userAnswer.calculateScore(state.currentItem!);

    state = state.copyWith(isCompleted: true, finalScore: score);

    // 品鉴完成，清除保存的进度
    clearSavedProgress();
  }

  /// 重置状态
  void reset() {
    state = BlindTasteState(userAnswer: BlindTasteAnswer());
  }

  /// 自动保存当前进度
  Future<void> _autoSaveProgress() async {
    if (state.currentItem != null && !state.isCompleted) {
      try {
        final progress = QuizProgress.fromBlindTasteState(state);
        await _progressService.saveBlindTasteProgress(progress);
      } catch (e) {}
    }
  }

  /// 恢复进度
  Future<bool> restoreProgress() async {
    try {
      final progress = await _progressService.loadBlindTasteProgress();
      if (progress != null &&
          progress.isValid &&
          progress.blindTasteItemId != null) {
        // 根据ID获取酒样
        final item = await _service.getItemById(progress.blindTasteItemId!);
        if (item != null) {
          state = BlindTasteState(
            currentItem: item,
            userAnswer: progress.blindTasteAnswer ?? BlindTasteAnswer(),
            currentIndex: progress.currentIndex,
            isCompleted: false,
            isLoading: false,
          );
          return true;
        }
      }
    } catch (e) {}
    return false;
  }

  /// 清除保存的进度
  Future<void> clearSavedProgress() async {
    try {
      await _progressService.clearBlindTasteProgress();
    } catch (e) {
      print('Failed to clear blind taste progress: $e');
    }
  }

  /// 检查是否有保存的进度
  Future<bool> hasSavedProgress() async {
    try {
      return await _progressService.hasBlindTasteProgress();
    } catch (e) {
      print('Failed to check saved blind taste progress: $e');
      return false;
    }
  }

  /// 获取保存的进度描述
  Future<String?> getSavedProgressDescription() async {
    try {
      final progress = await _progressService.loadBlindTasteProgress();
      return progress?.description;
    } catch (e) {
      print('Failed to get blind taste progress description: $e');
      return null;
    }
  }
}

/// 品鉴状态Provider
final blindTasteProvider =
    StateNotifierProvider<BlindTasteNotifier, BlindTasteState>((ref) {
      final service = ref.watch(blindTasteServiceProvider);
      final progressService = ref.watch(blindTasteProgressServiceProvider);
      return BlindTasteNotifier(service, progressService);
    });

/// 品鉴数据统计Provider
final blindTasteStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final service = ref.watch(blindTasteServiceProvider);
  await service.initialize();

  return {
    'totalItems': await service.getItemCount(),
    'aromaTypes': await service.getAllAromaTypes(),
    'equipmentTypes': await service.getAllEquipmentTypes(),
    'fermentationAgents': await service.getAllFermentationAgents(),
    'alcoholDegreeRange': await service.getAlcoholDegreeRange(),
    'totalScoreRange': await service.getTotalScoreRange(),
  };
});
