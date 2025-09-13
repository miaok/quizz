import 'blind_taste_model.dart';

/// 闪卡状态枚举
enum FlashcardSide {
  front, // 正面 - 显示酒样名称
  back, // 背面 - 显示详细信息
}

/// 闪卡数据模型
class FlashcardModel {
  final BlindTasteItemModel item;
  final FlashcardSide currentSide;
  final bool isFlipped;

  const FlashcardModel({
    required this.item,
    this.currentSide = FlashcardSide.front,
    this.isFlipped = false,
  });

  FlashcardModel copyWith({
    BlindTasteItemModel? item,
    FlashcardSide? currentSide,
    bool? isFlipped,
  }) {
    return FlashcardModel(
      item: item ?? this.item,
      currentSide: currentSide ?? this.currentSide,
      isFlipped: isFlipped ?? this.isFlipped,
    );
  }

  /// 翻转卡片
  FlashcardModel flip() {
    return copyWith(
      currentSide: currentSide == FlashcardSide.front
          ? FlashcardSide.back
          : FlashcardSide.front,
      isFlipped: !isFlipped,
    );
  }

  /// 重置到正面
  FlashcardModel resetToFront() {
    return copyWith(currentSide: FlashcardSide.front, isFlipped: false);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'currentSide': currentSide.name,
      'isFlipped': isFlipped,
    };
  }

  /// 从JSON创建
  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      item: BlindTasteItemModel.fromJson(json['item'] as Map<String, dynamic>),
      currentSide: FlashcardSide.values.firstWhere(
        (e) => e.name == json['currentSide'],
        orElse: () => FlashcardSide.front,
      ),
      isFlipped: json['isFlipped'] as bool? ?? false,
    );
  }
}

/// 闪卡记忆状态
class FlashcardState {
  final List<BlindTasteItemModel> items; // 所有闪卡项目（当前轮次的卡片池）
  final int currentIndex; // 当前闪卡索引
  final FlashcardModel? currentCard; // 当前闪卡
  final bool isLoading; // 是否加载中
  final String? error; // 错误信息
  final bool isCompleted; // 是否完成当前卡片
  final bool isRoundCompleted; // 是否完成一轮学习

  // 进度相关
  final Set<int> viewedCardIds; // 已查看的闪卡ID集合（整个轮次）
  final int totalCards; // 总闪卡数
  final double progress; // 进度百分比

  // 筛选设置
  final String? selectedAromaFilter; // 香型筛选
  final double? minAlcoholDegree; // 最小酒度
  final double? maxAlcoholDegree; // 最大酒度

  const FlashcardState({
    this.items = const [],
    this.currentIndex = 0,
    this.currentCard,
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
    this.isRoundCompleted = false,
    this.viewedCardIds = const {},
    this.totalCards = 0,
    this.progress = 0.0,
    this.selectedAromaFilter,
    this.minAlcoholDegree,
    this.maxAlcoholDegree,
  });

  FlashcardState copyWith({
    List<BlindTasteItemModel>? items,
    int? currentIndex,
    FlashcardModel? currentCard,
    bool? isLoading,
    String? error,
    bool? isCompleted,
    bool? isRoundCompleted,
    Set<int>? viewedCardIds,
    int? totalCards,
    double? progress,
    String? selectedAromaFilter,
    double? minAlcoholDegree,
    double? maxAlcoholDegree,
  }) {
    return FlashcardState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      currentCard: currentCard ?? this.currentCard,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isCompleted: isCompleted ?? this.isCompleted,
      isRoundCompleted: isRoundCompleted ?? this.isRoundCompleted,
      viewedCardIds: viewedCardIds ?? this.viewedCardIds,
      totalCards: totalCards ?? this.totalCards,
      progress: progress ?? this.progress,
      selectedAromaFilter: selectedAromaFilter ?? this.selectedAromaFilter,
      minAlcoholDegree: minAlcoholDegree ?? this.minAlcoholDegree,
      maxAlcoholDegree: maxAlcoholDegree ?? this.maxAlcoholDegree,
    );
  }

  /// 是否有上一张卡片
  bool get hasPrevious => currentIndex > 0;

  /// 是否有下一张卡片
  bool get hasNext => currentIndex < items.length - 1;

  /// 是否是第一张卡片
  bool get isFirst => currentIndex == 0;

  /// 是否是最后一张卡片
  bool get isLast => currentIndex == items.length - 1;

  /// 是否有未查看的卡片
  bool get hasUnviewedCards {
    return items.any(
      (item) => item.id != null && !viewedCardIds.contains(item.id!),
    );
  }

  /// 获取下一张未查看的卡片索引
  int? get nextUnviewedCardIndex {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.id != null && !viewedCardIds.contains(item.id!)) {
        return i;
      }
    }
    return null;
  }

  /// 获取当前进度描述
  String get progressDescription {
    if (items.isEmpty) return '暂无闪卡';
    return '${currentIndex + 1}/${items.length}';
  }

  /// 获取轮次进度描述
  String get roundProgressDescription {
    if (items.isEmpty) return '暂无闪卡';
    return '${viewedCardIds.length}/${items.length}';
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'currentIndex': currentIndex,
      'currentCard': currentCard?.toJson(),
      'isLoading': isLoading,
      'error': error,
      'isCompleted': isCompleted,
      'isRoundCompleted': isRoundCompleted,
      'viewedCardIds': viewedCardIds.toList(),
      'totalCards': totalCards,
      'progress': progress,
      'selectedAromaFilter': selectedAromaFilter,
      'minAlcoholDegree': minAlcoholDegree,
      'maxAlcoholDegree': maxAlcoholDegree,
    };
  }

  /// 从JSON创建
  factory FlashcardState.fromJson(Map<String, dynamic> json) {
    final itemsList =
        (json['items'] as List<dynamic>?)
            ?.map(
              (item) =>
                  BlindTasteItemModel.fromJson(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    final viewedIds =
        (json['viewedCardIds'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toSet() ??
        <int>{};

    FlashcardModel? currentCard;
    if (json['currentCard'] != null) {
      currentCard = FlashcardModel.fromJson(
        json['currentCard'] as Map<String, dynamic>,
      );
    }

    return FlashcardState(
      items: itemsList,
      currentIndex: json['currentIndex'] as int? ?? 0,
      currentCard: currentCard,
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isRoundCompleted: json['isRoundCompleted'] as bool? ?? false,
      viewedCardIds: viewedIds,
      totalCards: json['totalCards'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      selectedAromaFilter: json['selectedAromaFilter'] as String?,
      minAlcoholDegree: (json['minAlcoholDegree'] as num?)?.toDouble(),
      maxAlcoholDegree: (json['maxAlcoholDegree'] as num?)?.toDouble(),
    );
  }
}

/// 闪卡记忆进度模型
class FlashcardProgress {
  final int currentIndex;
  final Set<int> viewedCardIds;
  final String? selectedAromaFilter;
  final double? minAlcoholDegree;
  final double? maxAlcoholDegree;
  final DateTime savedAt;

  const FlashcardProgress({
    required this.currentIndex,
    required this.viewedCardIds,
    this.selectedAromaFilter,
    this.minAlcoholDegree,
    this.maxAlcoholDegree,
    required this.savedAt,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'currentIndex': currentIndex,
      'viewedCardIds': viewedCardIds.toList(),
      'selectedAromaFilter': selectedAromaFilter,
      'minAlcoholDegree': minAlcoholDegree,
      'maxAlcoholDegree': maxAlcoholDegree,
      'savedAt': savedAt.millisecondsSinceEpoch,
    };
  }

  /// 从JSON创建
  factory FlashcardProgress.fromJson(Map<String, dynamic> json) {
    final viewedIds =
        (json['viewedCardIds'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toSet() ??
        <int>{};

    return FlashcardProgress(
      currentIndex: json['currentIndex'] as int? ?? 0,
      viewedCardIds: viewedIds,
      selectedAromaFilter: json['selectedAromaFilter'] as String?,
      minAlcoholDegree: (json['minAlcoholDegree'] as num?)?.toDouble(),
      maxAlcoholDegree: (json['maxAlcoholDegree'] as num?)?.toDouble(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        json['savedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// 获取进度描述
  String get description {
    return '闪卡记忆进度：第${currentIndex + 1}张，已查看${viewedCardIds.length}张';
  }

  /// 检查进度是否有效
  bool get isValid {
    return currentIndex >= 0 &&
        savedAt.isAfter(DateTime.now().subtract(const Duration(days: 7)));
  }
}
