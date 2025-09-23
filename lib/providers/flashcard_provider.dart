import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flashcard_model.dart';
import '../models/blind_taste_model.dart';
import '../models/progress_model.dart';
import '../services/blind_taste_service.dart';
import '../services/progress_service.dart';
import 'settings_provider.dart';

/// 闪卡记忆Provider
final flashcardProvider =
    StateNotifierProvider<FlashcardController, FlashcardState>((ref) {
      return FlashcardController(ref);
    });

/// 闪卡记忆控制器
class FlashcardController extends StateNotifier<FlashcardState> {
  final BlindTasteService _service = BlindTasteService();
  final ProgressService _progressService = ProgressService();
  late final Ref _ref;

  FlashcardController(Ref ref) : super(const FlashcardState()) {
    _ref = ref;
  }

  /// 加载闪卡数据
  Future<void> loadFlashcards({
    String? aromaFilter,
    double? minAlcohol,
    double? maxAlcohol,
    bool? randomOrder, // 改为可选参数，如果不提供则从设置中读取
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 获取随机顺序设置，优先使用传入参数，否则从设置中读取
      final settings = _ref.read(settingsProvider);
      final useRandomOrder = randomOrder ?? settings.enableFlashcardRandomOrder;

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
      if (useRandomOrder) {
        // 使用固定种子确保每次的随机顺序一致，避免进度恢复时顺序不匹配
        filteredItems.shuffle(Random(42));
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
      // 如果当前已经是最后一张卡片，则标记轮次完成
      if (state.currentIndex == state.items.length - 1) {
        state = state.copyWith(isRoundCompleted: true);
        // 如果完成了一轮，清除保存的进度
        await clearProgress();
        return;
      }

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
        isRoundCompleted: false, // 只有当用户从最后一张卡片再次点击下一张时才完成
      );

      // 自动保存进度
      await _autoSaveProgress();
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

    // 更新已查看的卡片ID集合（保持原有的，并添加当前的）
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
      isRoundCompleted: false, // 跳转到卡片时不应该立即完成
    );

    // 自动保存进度
    await _autoSaveProgress();
  }

  /// 开始新一轮
  Future<void> startNewRound() async {
    // 从设置中获取最新的随机顺序设置
    final settings = _ref.read(settingsProvider);
    await loadFlashcards(
      aromaFilter: state.selectedAromaFilter,
      minAlcohol: state.minAlcoholDegree,
      maxAlcohol: state.maxAlcoholDegree,
      randomOrder: settings.enableFlashcardRandomOrder, // 使用最新的设置
    );
  }

  /// 重置闪卡状态
  void reset() {
    state = const FlashcardState();
  }

  /// 自动保存进度
  Future<void> _autoSaveProgress() async {
    if (state.items.isNotEmpty && state.currentCard != null) {
      // 获取当前设置中的随机顺序
      final settings = _ref.read(settingsProvider);
      final progress = QuizProgress.fromFlashcardState(
        state,
        randomOrder: settings.enableFlashcardRandomOrder,
      );
      await _progressService.saveFlashcardProgress(progress);
    }
  }

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
  Future<bool> restoreProgress({bool? randomOrder}) async {
    final progress = await _progressService.loadFlashcardProgress();
    if (progress == null) return false;

    // 获取当前设置
    final settings = _ref.read(settingsProvider);
    final currentRandomOrder =
        randomOrder ?? settings.enableFlashcardRandomOrder;

    try {
      // 检查随机顺序设置是否匹配
      if (progress.flashcardRandomOrder != null &&
          progress.flashcardRandomOrder != currentRandomOrder) {
        debugPrint(
          'Random order setting changed, clearing progress for consistency',
        );
        await clearProgress();
        return false; // 返回false，让调用方重新开始
      }

      // 直接恢复状态，不调用loadFlashcards避免状态被重置
      await _service.initialize();
      final allItems = await _service.getAllItems();

      // 应用筛选条件
      List<BlindTasteItemModel> filteredItems = allItems;

      if (progress.flashcardAromaFilter != null &&
          progress.flashcardAromaFilter!.isNotEmpty) {
        filteredItems = filteredItems
            .where((item) => item.aroma == progress.flashcardAromaFilter!)
            .toList();
      }

      if (progress.flashcardMinAlcohol != null) {
        filteredItems = filteredItems
            .where(
              (item) => item.alcoholDegree >= progress.flashcardMinAlcohol!,
            )
            .toList();
      }

      if (progress.flashcardMaxAlcohol != null) {
        filteredItems = filteredItems
            .where(
              (item) => item.alcoholDegree <= progress.flashcardMaxAlcohol!,
            )
            .toList();
      }

      if (filteredItems.isEmpty) {
        return false;
      }

      // 如果启用随机顺序，则打乱列表（使用与新开始时相同的固定种子）
      if (progress.flashcardRandomOrder == true) {
        // 使用固定种子确保与保存时的顺序一致
        final random = Random(42); // 与loadFlashcards中使用的种子一致
        filteredItems.shuffle(random);
      }

      // 检查保存的索引是否有效
      if (progress.currentIndex >= filteredItems.length) {
        debugPrint('Saved index out of range, clearing progress');
        await clearProgress();
        return false;
      }

      // 获取当前卡片
      final currentItem = filteredItems[progress.currentIndex];
      final currentCard = FlashcardModel(item: currentItem);

      // 计算当前进度
      final currentProgress =
          (progress.currentIndex + 1) / filteredItems.length;

      // 注意：随机顺序设置现在直接从settings provider中读取

      // 恢复完整状态
      state = state.copyWith(
        isLoading: false,
        error: null,
        items: filteredItems,
        currentIndex: progress.currentIndex,
        currentCard: currentCard,
        totalCards: filteredItems.length,
        progress: currentProgress,
        selectedAromaFilter: progress.flashcardAromaFilter,
        minAlcoholDegree: progress.flashcardMinAlcohol,
        maxAlcoholDegree: progress.flashcardMaxAlcohol,
        viewedCardIds: progress.flashcardViewedIds ?? <int>{},
        isRoundCompleted: false, // 恢复进度时不应该立即完成
      );

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
