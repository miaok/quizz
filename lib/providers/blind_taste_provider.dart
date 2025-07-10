import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blind_taste_model.dart';
import '../models/progress_model.dart';
import '../services/blind_taste_service.dart';
import '../services/progress_service.dart';
import 'settings_provider.dart';

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

  // 题目池管理
  final List<BlindTasteItemModel> questionPool; // 当前轮次的题目池
  final Set<int> completedItemIds; // 已完成的题目ID集合
  final int totalItemsInPool; // 题目池总数
  final bool isRoundCompleted; // 是否完成一轮

  // 用户进度设置
  final int maxItemsPerRound; // 每轮最大题目数（0表示全部）
  final String? selectedAromaFilter; // 香型筛选
  final double? minAlcoholDegree; // 最小酒度
  final double? maxAlcoholDegree; // 最大酒度

  const BlindTasteState({
    this.currentItem,
    required this.userAnswer,
    this.currentIndex = 0,
    this.isCompleted = false,
    this.finalScore,
    this.isLoading = false,
    this.error,
    this.questionPool = const [],
    this.completedItemIds = const {},
    this.totalItemsInPool = 0,
    this.isRoundCompleted = false,
    this.maxItemsPerRound = 0, // 默认全部题目
    this.selectedAromaFilter,
    this.minAlcoholDegree,
    this.maxAlcoholDegree,
  });

  BlindTasteState copyWith({
    BlindTasteItemModel? currentItem,
    BlindTasteAnswer? userAnswer,
    int? currentIndex,
    bool? isCompleted,
    double? finalScore,
    bool? isLoading,
    String? error,
    List<BlindTasteItemModel>? questionPool,
    Set<int>? completedItemIds,
    int? totalItemsInPool,
    bool? isRoundCompleted,
    int? maxItemsPerRound,
    String? selectedAromaFilter,
    double? minAlcoholDegree,
    double? maxAlcoholDegree,
  }) {
    return BlindTasteState(
      currentItem: currentItem ?? this.currentItem,
      userAnswer: userAnswer ?? this.userAnswer,
      currentIndex: currentIndex ?? this.currentIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      finalScore: finalScore ?? this.finalScore,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      questionPool: questionPool ?? this.questionPool,
      completedItemIds: completedItemIds ?? this.completedItemIds,
      totalItemsInPool: totalItemsInPool ?? this.totalItemsInPool,
      isRoundCompleted: isRoundCompleted ?? this.isRoundCompleted,
      maxItemsPerRound: maxItemsPerRound ?? this.maxItemsPerRound,
      selectedAromaFilter: selectedAromaFilter ?? this.selectedAromaFilter,
      minAlcoholDegree: minAlcoholDegree ?? this.minAlcoholDegree,
      maxAlcoholDegree: maxAlcoholDegree ?? this.maxAlcoholDegree,
    );
  }

  /// 获取当前进度百分比
  double get progressPercentage {
    if (totalItemsInPool == 0) return 0.0;
    return completedItemIds.length / totalItemsInPool;
  }

  /// 获取剩余题目数
  int get remainingItems {
    return totalItemsInPool - completedItemIds.length;
  }

  /// 是否有可用的下一题
  bool get hasNextItem {
    return questionPool.any(
      (item) => item.id != null && !completedItemIds.contains(item.id!),
    );
  }
}

/// 品鉴状态管理器
class BlindTasteNotifier extends StateNotifier<BlindTasteState> {
  final BlindTasteService _service;
  final ProgressService _progressService;
  final Ref _ref;

  BlindTasteNotifier(this._service, this._progressService, this._ref)
    : super(BlindTasteState(userAnswer: BlindTasteAnswer()));

  /// 开始新的品鉴（或继续当前轮次）
  Future<void> startNewTasting({
    int maxItemsPerRound = 0,
    String? aromaFilter,
    double? minAlcoholDegree,
    double? maxAlcoholDegree,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.initialize();

      // 如果当前有题目池且未完成一轮，继续当前轮次
      if (state.questionPool.isNotEmpty && state.hasNextItem) {
        await _loadNextItemFromPool();
        return;
      }

      // 创建新的题目池
      final questionPool = await _service.getQuestionPool(
        maxItems: maxItemsPerRound,
        aromaFilter: aromaFilter,
        minAlcoholDegree: minAlcoholDegree,
        maxAlcoholDegree: maxAlcoholDegree,
      );

      if (questionPool.isEmpty) {
        state = state.copyWith(isLoading: false, error: '没有符合条件的品鉴数据');
        return;
      }

      // 获取第一个题目
      final firstItem = questionPool.first;

      state = state.copyWith(
        currentItem: firstItem,
        userAnswer: BlindTasteAnswer(),
        currentIndex: 0,
        isCompleted: false,
        finalScore: null,
        isLoading: false,
        error: null,
        questionPool: questionPool,
        completedItemIds: <int>{},
        totalItemsInPool: questionPool.length,
        isRoundCompleted: false,
        maxItemsPerRound: maxItemsPerRound,
        selectedAromaFilter: aromaFilter,
        minAlcoholDegree: minAlcoholDegree,
        maxAlcoholDegree: maxAlcoholDegree,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载品鉴数据失败: $e');
    }
  }

  /// 从题目池加载下一个题目
  Future<void> _loadNextItemFromPool() async {
    final nextItem = _service.getNextUncompletedItem(
      state.questionPool,
      state.completedItemIds,
    );

    if (nextItem != null) {
      state = state.copyWith(
        currentItem: nextItem,
        userAnswer: BlindTasteAnswer(),
        isCompleted: false,
        finalScore: null,
        isLoading: false,
        error: null,
      );
    } else {
      // 一轮完成
      state = state.copyWith(isRoundCompleted: true, isLoading: false);
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
    if (state.currentItem == null || state.currentItem!.id == null) return;

    // 获取当前设置
    final settings = _ref.read(settingsProvider);

    final score = state.userAnswer.calculateScore(
      state.currentItem!,
      enableAroma: settings.enableBlindTasteAroma,
      enableAlcohol: settings.enableBlindTasteAlcohol,
      enableScore: settings.enableBlindTasteScore,
      enableEquipment: settings.enableBlindTasteEquipment,
      enableFermentation: settings.enableBlindTasteFermentation,
    );

    // 将当前题目标记为已完成
    final newCompletedIds = Set<int>.from(state.completedItemIds);
    newCompletedIds.add(state.currentItem!.id!);

    state = state.copyWith(
      isCompleted: true,
      finalScore: score,
      completedItemIds: newCompletedIds,
    );

    // 自动保存进度（包含已完成的题目信息）
    _autoSaveProgress();
  }

  /// 进入下一题
  Future<void> nextQuestion() async {
    if (state.currentItem?.id != null) {
      // 确保当前题目已标记为完成
      final newCompletedIds = Set<int>.from(state.completedItemIds);
      newCompletedIds.add(state.currentItem!.id!);

      state = state.copyWith(completedItemIds: newCompletedIds);
    }

    // 检查是否完成一轮
    if (_service.isRoundCompleted(state.questionPool, state.completedItemIds)) {
      state = state.copyWith(isRoundCompleted: true);
      clearSavedProgress(); // 一轮完成后清除进度
      return;
    }

    // 加载下一题
    await _loadNextItemFromPool();
  }

  /// 开始新一轮
  Future<void> startNewRound() async {
    await startNewTasting(
      maxItemsPerRound: state.maxItemsPerRound,
      aromaFilter: state.selectedAromaFilter,
      minAlcoholDegree: state.minAlcoholDegree,
      maxAlcoholDegree: state.maxAlcoholDegree,
    );
  }

  /// 重置状态
  void reset() {
    state = BlindTasteState(userAnswer: BlindTasteAnswer());
  }

  /// 自动保存当前进度
  Future<void> _autoSaveProgress() async {
    if (state.currentItem != null && state.questionPool.isNotEmpty) {
      final progress = QuizProgress.fromBlindTasteState(state);
      await _progressService.saveBlindTasteProgress(progress);
    }
  }

  /// 恢复进度
  Future<bool> restoreProgress() async {
    final progress = await _progressService.loadBlindTasteProgress();
    if (progress != null && progress.isValid) {
      // 恢复题目池状态
      if (progress.blindTasteQuestionPool != null &&
          progress.blindTasteQuestionPool!.isNotEmpty) {
        BlindTasteItemModel? currentItem;
        if (progress.blindTasteItemId != null) {
          currentItem = await _service.getItemById(progress.blindTasteItemId!);
        }

        state = BlindTasteState(
          currentItem: currentItem,
          userAnswer: progress.blindTasteAnswer ?? BlindTasteAnswer(),
          currentIndex: progress.currentIndex,
          isCompleted: false,
          isLoading: false,
          questionPool: progress.blindTasteQuestionPool!,
          completedItemIds: progress.blindTasteCompletedIds ?? <int>{},
          totalItemsInPool: progress.blindTasteQuestionPool!.length,
          isRoundCompleted: false,
          maxItemsPerRound: progress.blindTasteMaxItems ?? 0,
          selectedAromaFilter: progress.blindTasteAromaFilter,
          minAlcoholDegree: progress.blindTasteMinAlcohol,
          maxAlcoholDegree: progress.blindTasteMaxAlcohol,
        );
        return true;
      }
    }
    return false;
  }

  /// 清除保存的进度
  Future<void> clearSavedProgress() async {
    await _progressService.clearBlindTasteProgress();
  }

  /// 检查是否有保存的进度
  Future<bool> hasSavedProgress() async {
    return await _progressService.hasBlindTasteProgress();
  }

  /// 获取保存的进度描述
  Future<String?> getSavedProgressDescription() async {
    final progress = await _progressService.loadBlindTasteProgress();
    return progress?.description;
  }
}

/// 品鉴状态Provider
final blindTasteProvider =
    StateNotifierProvider<BlindTasteNotifier, BlindTasteState>((ref) {
      final service = ref.watch(blindTasteServiceProvider);
      final progressService = ref.watch(blindTasteProgressServiceProvider);
      return BlindTasteNotifier(service, progressService, ref);
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
