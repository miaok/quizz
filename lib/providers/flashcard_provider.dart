import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard_model.dart';
import '../models/blind_taste_model.dart';
import '../models/progress_model.dart';
import '../services/blind_taste_service.dart';
import '../services/progress_service.dart';

/// 闪卡记忆Provider
final flashcardProvider =
    StateNotifierProvider<FlashcardController, FlashcardState>((ref) {
      return FlashcardController();
    });

/// 闪卡记忆控制器
class FlashcardController extends StateNotifier<FlashcardState> {
  final BlindTasteService _service = BlindTasteService();
  final ProgressService _progressService = ProgressService();

  FlashcardController() : super(const FlashcardState());

  /// 加载闪卡数据
  Future<void> loadFlashcards({
    String? aromaFilter,
    double? minAlcohol,
    double? maxAlcohol,
    bool randomOrder = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // 记录当前的随机顺序设置
    _currentRandomOrder = randomOrder;

    try {
      // 如果当前有卡片池且未完成一轮，继续当前轮次
      if (state.items.isNotEmpty && !state.isRoundCompleted) {
        state = state.copyWith(isLoading: false); // 确保停止加载状态
        return; // 继续当前状态
      }

      // 初始化服务并获取所有品鉴项目
      await _service.initialize();
      final allItems = await _service.getAllItems();

      // 应用筛选条件
      List<BlindTasteItemModel> filteredItems = allItems;

      if (aromaFilter != null && aromaFilter.isNotEmpty) {
        filteredItems = filteredItems
            .where((item) => item.aroma == aromaFilter)
            .toList();
      }

      if (minAlcohol != null) {
        filteredItems = filteredItems
            .where((item) => item.alcoholDegree >= minAlcohol)
            .toList();
      }

      if (maxAlcohol != null) {
        filteredItems = filteredItems
            .where((item) => item.alcoholDegree <= maxAlcohol)
            .toList();
      }

      if (filteredItems.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: '没有找到符合条件的闪卡',
          items: [],
          totalCards: 0,
        );
        return;
      }

      // 如果启用随机顺序，则打乱列表
      if (randomOrder) {
        filteredItems.shuffle(Random());
      }

      // 创建第一张闪卡
      final firstCard = FlashcardModel(item: filteredItems.first);

      state = state.copyWith(
        isLoading: false,
        items: filteredItems,
        currentIndex: 0,
        currentCard: firstCard,
        totalCards: filteredItems.length,
        progress: 1.0 / filteredItems.length, // 第1张/总数
        selectedAromaFilter: aromaFilter,
        minAlcoholDegree: minAlcohol,
        maxAlcoholDegree: maxAlcohol,
        viewedCardIds: {filteredItems.first.id!},
        isRoundCompleted: false,
      );

      // 自动保存进度
      await _autoSaveProgress();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '加载闪卡失败: $e');
    }
  }

  /// 翻转当前卡片
  void flipCard() {
    try {
      if (state.currentCard != null) {
        final flippedCard = state.currentCard!.flip();
        state = state.copyWith(currentCard: flippedCard);
      }
    } catch (e) {
      // 静默处理错误，避免崩溃
      debugPrint('FlashcardController.flipCard error: $e');
    }
  }

  /// 切换到下一张卡片
  Future<void> nextCard() async {
    try {
      if (!state.hasNext) return;

      final nextIndex = state.currentIndex + 1;
      final nextItem = state.items[nextIndex];
      final nextCard = FlashcardModel(item: nextItem);

      // 标记当前卡片为已查看
      final updatedViewedIds = Set<int>.from(state.viewedCardIds);
      if (state.currentCard?.item.id != null) {
        updatedViewedIds.add(state.currentCard!.item.id!);
      }
      // 标记下一张卡片为已查看
      if (nextItem.id != null) {
        updatedViewedIds.add(nextItem.id!);
      }

      // 计算进度（基于当前位置）
      final progress = (nextIndex + 1) / state.totalCards;

      state = state.copyWith(
        currentIndex: nextIndex,
        currentCard: nextCard,
        viewedCardIds: updatedViewedIds,
        progress: progress,
        isCompleted: nextIndex == state.items.length - 1,
        isRoundCompleted: nextIndex == state.items.length - 1,
      );

      // 自动保存进度
      await _autoSaveProgress();

      // 如果到达最后一张，清除进度
      if (nextIndex == state.items.length - 1) {
        await clearProgress();
      }
    } catch (e) {
      // 静默处理错误，避免崩溃
      debugPrint('FlashcardController.nextCard error: $e');
    }
  }

  /// 切换到上一张卡片
  Future<void> previousCard() async {
    try {
      if (!state.hasPrevious) return;

      final prevIndex = state.currentIndex - 1;
      final prevItem = state.items[prevIndex];
      final prevCard = FlashcardModel(item: prevItem);

      // 计算进度（基于当前位置）
      final progress = (prevIndex + 1) / state.totalCards;

      state = state.copyWith(
        currentIndex: prevIndex,
        currentCard: prevCard,
        progress: progress,
        isCompleted: false,
        isRoundCompleted: false,
      );

      // 自动保存进度
      await _autoSaveProgress();
    } catch (e) {
      // 静默处理错误，避免崩溃
      debugPrint('FlashcardController.previousCard error: $e');
    }
  }

  /// 跳转到指定索引的卡片
  Future<void> goToCard(int index) async {
    if (index < 0 || index >= state.items.length) return;

    final targetItem = state.items[index];
    final targetCard = FlashcardModel(item: targetItem);

    // 更新已查看的卡片ID集合
    final updatedViewedIds = Set<int>.from(state.viewedCardIds);
    if (targetItem.id != null) {
      updatedViewedIds.add(targetItem.id!);
    }

    // 计算进度（基于当前位置）
    final progress = (index + 1) / state.totalCards;

    state = state.copyWith(
      currentIndex: index,
      currentCard: targetCard,
      viewedCardIds: updatedViewedIds,
      progress: progress,
      isCompleted: index == state.items.length - 1,
      isRoundCompleted: index == state.items.length - 1,
    );

    // 自动保存进度
    await _autoSaveProgress();
  }

  /// 开始新一轮
  Future<void> startNewRound() async {
    await loadFlashcards(
      aromaFilter: state.selectedAromaFilter,
      minAlcohol: state.minAlcoholDegree,
      maxAlcohol: state.maxAlcoholDegree,
      randomOrder: _currentRandomOrder, // 使用当前的随机顺序设置
    );
  }

  /// 重置闪卡状态
  void reset() {
    state = const FlashcardState();
  }

  /// 自动保存进度
  Future<void> _autoSaveProgress() async {
    if (state.items.isNotEmpty && state.currentCard != null) {
      final progress = QuizProgress.fromFlashcardState(
        state,
        randomOrder: _currentRandomOrder,
      );
      await _progressService.saveFlashcardProgress(progress);
    }
  }

  // 当前随机顺序设置
  bool _currentRandomOrder = false;

  /// 检查是否有保存的进度
  Future<bool> hasSavedProgress() async {
    return await _progressService.hasFlashcardProgress();
  }

  /// 获取保存的进度描述
  Future<String> getSavedProgressDescription() async {
    final progress = await _progressService.loadFlashcardProgress();
    return progress?.description ?? '无保存的进度';
  }

  /// 恢复保存的进度
  Future<bool> restoreProgress({bool randomOrder = false}) async {
    final progress = await _progressService.loadFlashcardProgress();
    if (progress == null) return false;

    try {
      // 检查随机顺序设置是否匹配
      if (progress.flashcardRandomOrder != null &&
          progress.flashcardRandomOrder != randomOrder) {
        debugPrint(
          'Random order setting changed, clearing progress for consistency',
        );
        await clearProgress();
        return false; // 返回false，让调用方重新开始
      }

      // 重新加载闪卡数据，保持原有的筛选条件和随机顺序设置
      await loadFlashcards(
        aromaFilter: progress.flashcardAromaFilter,
        minAlcohol: progress.flashcardMinAlcohol,
        maxAlcohol: progress.flashcardMaxAlcohol,
        randomOrder: progress.flashcardRandomOrder ?? false, // 使用保存的随机顺序设置
      );

      // 恢复已查看的卡片ID集合和当前位置
      if (progress.flashcardViewedIds != null) {
        // 计算基于当前索引的进度
        final currentProgress = (progress.currentIndex + 1) / state.totalCards;

        state = state.copyWith(
          viewedCardIds: progress.flashcardViewedIds,
          progress: currentProgress,
          isRoundCompleted: progress.currentIndex >= state.totalCards - 1,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error restoring flashcard progress: $e');
      return false;
    }
  }

  /// 清除保存的进度
  Future<void> clearProgress() async {
    await _progressService.clearFlashcardProgress();
  }
}
