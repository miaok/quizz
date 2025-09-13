import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blind_taste_model.dart';
import '../services/blind_taste_service.dart';
import '../providers/settings_provider.dart';

// 酒杯状态枚举
enum WineGlassStatus {
  empty, // 未开始
  answered, // 已回答
}

// 单个酒杯的状态
class WineGlassState {
  final int index; // 酒杯索引
  final BlindTasteItemModel? wineItem; // 分配的酒样
  final BlindTasteAnswer? userAnswer; // 用户答案
  final WineGlassStatus status; // 状态
  final double? score; // 得分

  const WineGlassState({
    required this.index,
    this.wineItem,
    this.userAnswer,
    this.status = WineGlassStatus.empty,
    this.score,
  });

  WineGlassState copyWith({
    int? index,
    BlindTasteItemModel? wineItem,
    BlindTasteAnswer? userAnswer,
    WineGlassStatus? status,
    double? score,
  }) {
    return WineGlassState(
      index: index ?? this.index,
      wineItem: wineItem ?? this.wineItem,
      userAnswer: userAnswer ?? this.userAnswer,
      status: status ?? this.status,
      score: score ?? this.score,
    );
  }
}

// 酒样练习整体状态
class WineSimulationState {
  final List<WineGlassState> wineGlasses; // 所有酒杯状态
  final bool isLoading; // 是否加载中
  final String? error; // 错误信息
  final bool isCompleted; // 是否全部完成
  final bool showResults; // 是否显示结果
  final Map<String, List<int>> duplicateGroups; // 重复酒样分组

  const WineSimulationState({
    this.wineGlasses = const [],
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
    this.showResults = false,
    this.duplicateGroups = const {},
  });

  WineSimulationState copyWith({
    List<WineGlassState>? wineGlasses,
    bool? isLoading,
    String? error,
    bool? isCompleted,
    bool? showResults,
    Map<String, List<int>>? duplicateGroups,
  }) {
    return WineSimulationState(
      wineGlasses: wineGlasses ?? this.wineGlasses,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCompleted: isCompleted ?? this.isCompleted,
      showResults: showResults ?? this.showResults,
      duplicateGroups: duplicateGroups ?? this.duplicateGroups,
    );
  }

  // 获取已完成的酒杯数量
  int get completedCount {
    return wineGlasses
        .where((glass) => glass.status == WineGlassStatus.answered)
        .length;
  }

  // 检查是否所有酒杯都已完成
  bool get allCompleted {
    return wineGlasses.isNotEmpty &&
        wineGlasses.every((glass) => glass.status == WineGlassStatus.answered);
  }
}

// 酒样练习状态管理器
class WineSimulationNotifier extends StateNotifier<WineSimulationState> {
  final BlindTasteService _service;
  final Ref _ref;

  WineSimulationNotifier(this._service, this._ref)
    : super(const WineSimulationState());

  /// 开始新的酒样练习
  Future<void> startNewSimulation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.initialize();

      // 获取设置中的酒杯数量
      final settings = _ref.read(settingsProvider);
      final glassCount = settings.wineSimulationSampleCount;

      // 获取所有可用的酒样
      final allWines = await _service.getAllItems();
      if (allWines.isEmpty) {
        state = state.copyWith(isLoading: false, error: '没有可用的酒样数据');
        return;
      }

      // 生成酒样分配（包含重复酒样）
      final wineAssignment = _generateWineAssignment(allWines, glassCount);

      // 创建酒杯状态列表
      final wineGlasses = List.generate(glassCount, (index) {
        return WineGlassState(
          index: index,
          wineItem: wineAssignment['wines'][index],
        );
      });

      state = state.copyWith(
        wineGlasses: wineGlasses,
        isLoading: false,
        error: null,
        isCompleted: false,
        showResults: false,
        duplicateGroups: wineAssignment['duplicateGroups'],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '初始化酒样练习失败: $e');
    }
  }

  /// 生成酒样分配（包含重复酒样逻辑）
  Map<String, dynamic> _generateWineAssignment(
    List<BlindTasteItemModel> allWines,
    int glassCount,
  ) {
    final List<BlindTasteItemModel> assignedWines = [];
    final Map<String, List<int>> duplicateGroups = {};

    // 获取用户设置
    final settings = _ref.read(settingsProvider);
    final duplicateProbability = settings.wineSimulationDuplicateProbability;
    final maxDuplicateGroups = settings.wineSimulationMaxDuplicateGroups;

    // 随机打乱酒样列表
    final shuffledWines = List<BlindTasteItemModel>.from(allWines)..shuffle();

    // 根据概率决定是否生成重复酒样
    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    final shouldHaveDuplicates = random < duplicateProbability;

    if (!shouldHaveDuplicates || glassCount < 4) {
      // 不生成重复酒样，直接分配不同的酒样
      for (int i = 0; i < glassCount; i++) {
        assignedWines.add(shuffledWines[i % shuffledWines.length]);
      }
      return {'wines': assignedWines, 'duplicateGroups': duplicateGroups};
    }

    // 计算实际重复组数（基于酒杯数量和用户设置）
    final actualMaxGroups = (glassCount / 2).floor().clamp(
      1,
      maxDuplicateGroups,
    );
    final duplicateGroupCount = (actualMaxGroups * 0.8).ceil(); // 80%概率达到最大组数

    // 为每个重复组选择酒样
    final usedWineIndices = <int>{};
    int currentGlassIndex = 0;

    for (
      int groupIndex = 0;
      groupIndex < duplicateGroupCount && currentGlassIndex < glassCount - 1;
      groupIndex++
    ) {
      // 选择一个未使用的酒样
      int wineIndex = 0;
      while (usedWineIndices.contains(wineIndex) &&
          wineIndex < shuffledWines.length) {
        wineIndex++;
      }

      if (wineIndex >= shuffledWines.length) break;

      final selectedWine = shuffledWines[wineIndex];
      usedWineIndices.add(wineIndex);

      // 重复酒样固定为2个（更符合实际品鉴需求）
      const duplicateCount = 2;
      final glassIndices = <int>[];

      // 确保有足够的酒杯来分配重复酒样
      if (currentGlassIndex + duplicateCount <= glassCount) {
        // 分配到多个酒杯
        for (int i = 0; i < duplicateCount; i++) {
          assignedWines.add(selectedWine);
          glassIndices.add(currentGlassIndex);
          currentGlassIndex++;
        }

        duplicateGroups[selectedWine.name] = glassIndices;
      } else {
        // 如果剩余酒杯不足，跳出循环
        usedWineIndices.remove(wineIndex); // 回退，这个酒样可以用于非重复分配
        break;
      }
    }

    // 填充剩余的酒杯（使用不重复的酒样）
    while (currentGlassIndex < glassCount) {
      int wineIndex = 0;
      while (usedWineIndices.contains(wineIndex) &&
          wineIndex < shuffledWines.length) {
        wineIndex++;
      }

      if (wineIndex < shuffledWines.length) {
        assignedWines.add(shuffledWines[wineIndex]);
        usedWineIndices.add(wineIndex);
      } else {
        // 如果没有足够的不重复酒样，随机选择一个
        assignedWines.add(
          shuffledWines[currentGlassIndex % shuffledWines.length],
        );
      }
      currentGlassIndex++;
    }

    // 对最终的酒样分配进行打乱，确保重复酒样不会相邻
    final shuffledAssignment = _shuffleWineAssignment(
      assignedWines,
      duplicateGroups,
    );

    return {
      'wines': shuffledAssignment['wines'],
      'duplicateGroups': shuffledAssignment['duplicateGroups'],
    };
  }

  /// 打乱酒样分配顺序，确保重复酒样尽可能分散
  Map<String, dynamic> _shuffleWineAssignment(
    List<BlindTasteItemModel> wines,
    Map<String, List<int>> duplicateGroups,
  ) {
    final glassCount = wines.length;
    final List<BlindTasteItemModel> shuffledWines = List.filled(
      glassCount,
      wines[0],
    );
    final Map<String, List<int>> newDuplicateGroups = {};

    // 创建索引映射表
    final List<int> availablePositions = List.generate(
      glassCount,
      (index) => index,
    );
    availablePositions.shuffle();

    // 先处理重复酒样，确保它们尽可能分散
    for (final entry in duplicateGroups.entries) {
      final wineName = entry.key;
      final originalIndices = entry.value;
      final newIndices = <int>[];

      // 为重复酒样选择分散的位置
      for (int i = 0; i < originalIndices.length; i++) {
        if (availablePositions.isNotEmpty) {
          // 尝试选择一个与已选位置距离较远的位置
          int bestPosition = availablePositions[0];
          if (newIndices.isNotEmpty && availablePositions.length > 1) {
            int maxDistance = 0;
            for (final pos in availablePositions) {
              int minDistanceToExisting = glassCount;
              for (final existingPos in newIndices) {
                final distance = (pos - existingPos).abs();
                if (distance < minDistanceToExisting) {
                  minDistanceToExisting = distance;
                }
              }
              if (minDistanceToExisting > maxDistance) {
                maxDistance = minDistanceToExisting;
                bestPosition = pos;
              }
            }
          }

          newIndices.add(bestPosition);
          availablePositions.remove(bestPosition);

          // 找到原始酒样
          final originalWine = wines[originalIndices[i]];
          shuffledWines[bestPosition] = originalWine;
        }
      }

      if (newIndices.length > 1) {
        newDuplicateGroups[wineName] = newIndices;
      }
    }

    // 填充剩余位置
    int wineIndex = 0;
    for (final position in availablePositions) {
      // 找到一个不在重复组中的酒样
      while (wineIndex < wines.length &&
          _isWineInDuplicateGroup(wines[wineIndex], duplicateGroups)) {
        wineIndex++;
      }

      if (wineIndex < wines.length) {
        shuffledWines[position] = wines[wineIndex];
        wineIndex++;
      } else {
        // 如果没有更多非重复酒样，使用任意酒样
        shuffledWines[position] = wines[position % wines.length];
      }
    }

    return {'wines': shuffledWines, 'duplicateGroups': newDuplicateGroups};
  }

  /// 检查酒样是否在重复组中
  bool _isWineInDuplicateGroup(
    BlindTasteItemModel wine,
    Map<String, List<int>> duplicateGroups,
  ) {
    return duplicateGroups.containsKey(wine.name);
  }

  /// 更新指定酒杯的答案
  void updateGlassAnswer(int glassIndex, BlindTasteAnswer answer) {
    if (glassIndex < 0 || glassIndex >= state.wineGlasses.length) return;

    final updatedGlasses = List<WineGlassState>.from(state.wineGlasses);
    updatedGlasses[glassIndex] = updatedGlasses[glassIndex].copyWith(
      userAnswer: answer,
      status: WineGlassStatus.answered,
    );

    state = state.copyWith(wineGlasses: updatedGlasses);
  }

  /// 手动提交所有答案并计算结果
  void submitAllAnswers() {
    if (!state.allCompleted) return;
    _calculateResults(state);
  }

  /// 计算所有酒杯的结果
  void _calculateResults(WineSimulationState currentState) {
    final settings = _ref.read(settingsProvider);
    final updatedGlasses = <WineGlassState>[];

    for (final glass in currentState.wineGlasses) {
      if (glass.userAnswer != null && glass.wineItem != null) {
        final score = glass.userAnswer!.calculateScore(
          glass.wineItem!,
          enableAroma: settings.enableBlindTasteAroma,
          enableAlcohol: settings.enableBlindTasteAlcohol,
          enableScore: settings.enableBlindTasteScore,
          enableEquipment: settings.enableBlindTasteEquipment,
          enableFermentation: settings.enableBlindTasteFermentation,
        );

        updatedGlasses.add(glass.copyWith(score: score));
      } else {
        updatedGlasses.add(glass);
      }
    }

    state = currentState.copyWith(
      wineGlasses: updatedGlasses,
      isCompleted: true,
      showResults: true,
    );
  }

  /// 重置练习状态
  void resetSimulation() {
    state = const WineSimulationState();
  }

  /// 显示结果
  void showResults() {
    state = state.copyWith(showResults: true);
  }

  /// 隐藏结果
  void hideResults() {
    state = state.copyWith(showResults: false);
  }
}

// Provider定义
final wineSimulationProvider =
    StateNotifierProvider<WineSimulationNotifier, WineSimulationState>((ref) {
      final service = BlindTasteService();
      return WineSimulationNotifier(service, ref);
    });
