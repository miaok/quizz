import 'package:flutter/foundation.dart';
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

  // 用户答案保存 - 按题目ID保存答案
  final Map<int, BlindTasteAnswer> savedAnswers;

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
    this.savedAnswers = const {},
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
    Map<int, BlindTasteAnswer>? savedAnswers,
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
      savedAnswers: savedAnswers ?? this.savedAnswers,
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
    : super(BlindTasteState(userAnswer: BlindTasteAnswer(), savedAnswers: {}));

  /// 开始新的品鉴（或继续当前轮次）
  Future<void> startNewTasting({
    int maxItemsPerRound = 0,
    String? aromaFilter,
    double? minAlcoholDegree,
    double? maxAlcoholDegree,
  }) async {
    debugPrint(
      'Starting new blind taste session with params: maxItems=$maxItemsPerRound, aroma=$aromaFilter, minAlc=$minAlcoholDegree, maxAlc=$maxAlcoholDegree',
    );

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.initialize();

      // 获取随机顺序设置
      final settings = _ref.read(settingsProvider);

      // 创建新的题目池
      final questionPool = await _service.getQuestionPool(
        maxItems: maxItemsPerRound,
        aromaFilter: aromaFilter,
        minAlcoholDegree: minAlcoholDegree,
        maxAlcoholDegree: maxAlcoholDegree,
        randomOrder: settings.enableBlindTasteRandomOrder,
      );

      debugPrint('Generated question pool: ${questionPool.length} items');

      if (questionPool.isEmpty) {
        debugPrint('Question pool is empty, no matching items found');
        state = state.copyWith(isLoading: false, error: '没有符合条件的品鉴数据');
        return;
      }

      // 获取第一个题目
      final firstItem = questionPool.first;
      debugPrint('First item: ${firstItem.name} (ID: ${firstItem.id})');

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

      debugPrint('New blind taste session initialized successfully');

      // 自动保存进度
      await _autoSaveProgress();
    } catch (e) {
      debugPrint('Error starting new blind taste session: $e');
      state = state.copyWith(isLoading: false, error: '加载品鉴数据失败: $e');
    }
  }

  /// 保存当前题目的答案
  void _saveCurrentAnswer() {
    if (state.currentItem?.id != null) {
      final newSavedAnswers = Map<int, BlindTasteAnswer>.from(
        state.savedAnswers,
      );
      newSavedAnswers[state.currentItem!.id!] = BlindTasteAnswer(
        selectedAroma: state.userAnswer.selectedAroma,
        selectedAlcoholDegree: state.userAnswer.selectedAlcoholDegree,
        selectedTotalScore: state.userAnswer.selectedTotalScore,
        selectedEquipment: List.from(state.userAnswer.selectedEquipment),
        selectedFermentationAgent: List.from(
          state.userAnswer.selectedFermentationAgent,
        ),
      );

      state = state.copyWith(savedAnswers: newSavedAnswers);
    }
  }

  /// 从题目池加载下一个题目（按序号顺序）
  Future<void> _loadNextItemFromPool() async {
    // 保存当前题目的答案
    _saveCurrentAnswer();

    // 计算下一个题目的索引（按序号顺序）
    int nextIndex = state.currentIndex + 1;

    // 检查是否超出题目池范围
    if (nextIndex >= state.questionPool.length) {
      // 一轮完成
      state = state.copyWith(isRoundCompleted: true, isLoading: false);
      return;
    }

    // 获取下一个题目
    final nextItem = state.questionPool[nextIndex];

    // 尝试恢复该题目的已保存答案
    BlindTasteAnswer restoredAnswer =
        state.savedAnswers[nextItem.id] ?? BlindTasteAnswer();

    state = state.copyWith(
      currentItem: nextItem,
      userAnswer: restoredAnswer,
      currentIndex: nextIndex,
      isCompleted: false,
      finalScore: null,
      isLoading: false,
      error: null,
    );

    // 自动保存进度
    await _autoSaveProgress();
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

    // 保存当前题目的答案
    _saveCurrentAnswer();

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

    // 保存当前题目的答案
    _saveCurrentAnswer();

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 调整总分
  void adjustTotalScore(double delta) {
    final newScore = (state.userAnswer.selectedTotalScore + delta).clamp(
      84.0,
      98.0,
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

    // 保存当前题目的答案
    _saveCurrentAnswer();

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 设置总分
  void setTotalScore(double score) {
    final newScore = score.clamp(87.0, 95.0);

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

    // 保存当前题目的答案
    _saveCurrentAnswer();

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

    // 保存当前题目的答案
    _saveCurrentAnswer();

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

    // 保存当前题目的答案
    _saveCurrentAnswer();

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 重置当前题目的答案到默认状态
  void resetCurrentAnswer() {
    // 从保存的答案中移除当前题目
    if (state.currentItem?.id != null) {
      final newSavedAnswers = Map<int, BlindTasteAnswer>.from(
        state.savedAnswers,
      );
      newSavedAnswers.remove(state.currentItem!.id!);

      state = state.copyWith(
        userAnswer: BlindTasteAnswer(),
        isCompleted: false,
        finalScore: null,
        savedAnswers: newSavedAnswers,
      );
    } else {
      state = state.copyWith(
        userAnswer: BlindTasteAnswer(),
        isCompleted: false,
        finalScore: null,
      );
    }

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

  /// 跳过当前酒样（视为已答但不计算得分）
  void skipCurrentItem() {
    if (state.currentItem == null || state.currentItem!.id == null) return;

    // 将当前题目标记为已完成
    final newCompletedIds = Set<int>.from(state.completedItemIds);
    newCompletedIds.add(state.currentItem!.id!);

    state = state.copyWith(
      isCompleted: true,
      finalScore: 0.0, // 跳过的题目得分为0
      completedItemIds: newCompletedIds,
    );

    // 自动保存进度（包含已完成的题目信息）
    _autoSaveProgress();
  }

  /// 进入下一题（按序号顺序）
  Future<void> nextQuestion() async {
    if (state.currentItem?.id != null) {
      // 确保当前题目已标记为完成
      final newCompletedIds = Set<int>.from(state.completedItemIds);
      newCompletedIds.add(state.currentItem!.id!);

      state = state.copyWith(completedItemIds: newCompletedIds);
    }

    // 直接加载下一题（按序号顺序）
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
    state = BlindTasteState(userAnswer: BlindTasteAnswer(), savedAnswers: {});
  }

  /// 跳转到指定的题目（支持跳转到任意题目的作答页面）
  void goToQuestion(int index) {
    if (index < 0 ||
        index >= state.totalItemsInPool ||
        state.questionPool.isEmpty) {
      debugPrint('Invalid question index: $index or empty question pool');
      return;
    }

    // 保存当前题目的答案
    _saveCurrentAnswer();

    // 直接从题目池中获取目标题目
    final targetItem = state.questionPool[index];

    // 尝试恢复该题目的已保存答案
    BlindTasteAnswer userAnswer =
        state.savedAnswers[targetItem.id] ?? BlindTasteAnswer();

    // 更新状态到作答页面（不是结果页面）
    state = state.copyWith(
      currentItem: targetItem,
      userAnswer: userAnswer,
      currentIndex: index,
      isCompleted: false, // 设为false，显示作答页面
      finalScore: null, // 清除分数，因为要重新作答
    );

    debugPrint('Jumped to question $index: ${targetItem.name}');

    // 自动保存进度
    _autoSaveProgress();
  }

  /// 自动保存当前进度
  Future<void> _autoSaveProgress() async {
    if (state.currentItem != null && state.questionPool.isNotEmpty) {
      final settings = _ref.read(settingsProvider);
      final progress = QuizProgress.fromBlindTasteState(
        state,
        randomOrder: settings.enableBlindTasteRandomOrder,
      );
      await _progressService.saveBlindTasteProgress(progress);
    }
  }

  /// 恢复进度
  Future<bool> restoreProgress() async {
    debugPrint('Attempting to restore blind taste progress...');
    final progress = await _progressService.loadBlindTasteProgress();

    if (progress == null) {
      debugPrint('No saved progress found');
      return false;
    }

    if (!progress.isValid) {
      debugPrint('Saved progress is invalid');
      return false;
    }

    debugPrint(
      'Found valid saved progress: type=${progress.type}, currentIndex=${progress.currentIndex}, itemId=${progress.blindTasteItemId}',
    );

    try {
      // 重新初始化服务，确保应用重启后能正常工作
      await _service.initialize();
      debugPrint('Service initialized successfully');

      // 检查随机顺序设置是否匹配
      final settings = _ref.read(settingsProvider);
      if (progress.blindTasteRandomOrder != null &&
          progress.blindTasteRandomOrder !=
              settings.enableBlindTasteRandomOrder) {
        debugPrint(
          'Blind taste random order setting changed, clearing progress for consistency',
        );
        await clearSavedProgress();
        return false; // 返回false，让调用方重新开始
      }

      // 恢复题目池状态
      if (progress.blindTasteQuestionPool != null &&
          progress.blindTasteQuestionPool!.isNotEmpty) {
        debugPrint(
          'Restoring question pool with ${progress.blindTasteQuestionPool!.length} items',
        );

        BlindTasteItemModel? currentItem;
        BlindTasteAnswer? currentAnswer = progress.blindTasteAnswer;
        bool isCompleted = false;

        // 首先尝试恢复当前题目
        if (progress.blindTasteItemId != null) {
          debugPrint(
            'Attempting to restore current item with ID: ${progress.blindTasteItemId}',
          );

          // 检查当前题目是否已完成
          final isCurrentCompleted =
              progress.blindTasteCompletedIds != null &&
              progress.blindTasteCompletedIds!.contains(
                progress.blindTasteItemId!,
              );

          debugPrint('Current item completed status: $isCurrentCompleted');

          if (isCurrentCompleted) {
            // 当前题目已完成，找下一题
            debugPrint(
              'Current item is completed, looking for next uncompleted item',
            );
            currentItem = _service.getNextUncompletedItem(
              progress.blindTasteQuestionPool!,
              progress.blindTasteCompletedIds!,
            );
            if (currentItem != null) {
              debugPrint(
                'Found next uncompleted item: ${currentItem.name} (ID: ${currentItem.id})',
              );
              currentAnswer = BlindTasteAnswer(); // 新题目使用空答案
              isCompleted = false;
            } else {
              debugPrint('No more uncompleted items found');
            }
          } else {
            // 当前题目未完成，尝试恢复
            debugPrint('Current item is not completed, attempting to restore');
            try {
              currentItem = await _service.getItemById(
                progress.blindTasteItemId!,
              );
              if (currentItem != null) {
                debugPrint(
                  'Successfully restored current item: ${currentItem.name}',
                );
                isCompleted = false; // 未完成的题目
              } else {
                debugPrint('Failed to find current item by ID');
              }
            } catch (e) {
              debugPrint('Failed to restore current item: $e');
            }
          }
        }

        // 如果仍然没有currentItem，从题目池中获取第一个未完成的
        if (currentItem == null) {
          debugPrint(
            'No current item found, getting first uncompleted item from pool',
          );
          currentItem = _service.getNextUncompletedItem(
            progress.blindTasteQuestionPool!,
            progress.blindTasteCompletedIds ?? <int>{},
          );
          if (currentItem != null) {
            debugPrint(
              'Found first uncompleted item: ${currentItem.name} (ID: ${currentItem.id})',
            );
            currentAnswer = BlindTasteAnswer();
            isCompleted = false;
          } else {
            debugPrint('No uncompleted items available in question pool');
          }
        }

        // 如果还是没有题目，说明轮次已完成
        if (currentItem == null) {
          debugPrint('No available items in question pool, round completed');
        }

        // 计算轮次是否完成
        final isRoundCompleted = _service.isRoundCompleted(
          progress.blindTasteQuestionPool!,
          progress.blindTasteCompletedIds ?? <int>{},
        );

        debugPrint('Round completed status: $isRoundCompleted');

        state = BlindTasteState(
          currentItem: currentItem,
          userAnswer: currentAnswer ?? BlindTasteAnswer(),
          currentIndex: progress.currentIndex,
          isCompleted: isCompleted,
          finalScore: isCompleted && currentItem != null
              ? progress.blindTasteAnswer?.calculateScore(
                  currentItem,
                  enableAroma: settings.enableBlindTasteAroma,
                  enableAlcohol: settings.enableBlindTasteAlcohol,
                  enableScore: settings.enableBlindTasteScore,
                  enableEquipment: settings.enableBlindTasteEquipment,
                  enableFermentation: settings.enableBlindTasteFermentation,
                )
              : null,
          isLoading: false,
          questionPool: progress.blindTasteQuestionPool!,
          completedItemIds: progress.blindTasteCompletedIds ?? <int>{},
          totalItemsInPool: progress.blindTasteQuestionPool!.length,
          isRoundCompleted: isRoundCompleted,
          maxItemsPerRound: progress.blindTasteMaxItems ?? 0,
          selectedAromaFilter: progress.blindTasteAromaFilter,
          minAlcoholDegree: progress.blindTasteMinAlcohol,
          maxAlcoholDegree: progress.blindTasteMaxAlcohol,
        );

        debugPrint(
          'Progress restored successfully. Current item: ${currentItem?.name ?? "null"}',
        );
        return true;
      } else {
        debugPrint('No question pool found in saved progress');
      }
    } catch (e) {
      debugPrint('Error restoring blind taste progress: $e');
      await clearSavedProgress();
      return false;
    }

    debugPrint('Failed to restore progress');
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
