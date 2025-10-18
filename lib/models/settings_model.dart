import 'package:flutter/material.dart';

// 练习模式乱序枚举
enum PracticeShuffleMode {
  fullRandom, // 完全乱序：题型和题型内部题目顺序均乱序
  ordered, // 题型不乱序，题目不乱序：使用默认顺序
  typeOrderedQuestionRandom, // 题型不乱序，内部题目乱序
}

// 设置数据模型
class QuizSettings {
  final int singleChoiceCount;
  final int multipleChoiceCount;
  final int booleanCount;
  final bool shuffleOptions;
  final bool autoNextQuestion;
  final bool enableProgressSave; // 是否启用进度保存
  final int examTimeMinutes; // 考试时间（分钟）
  final bool enableSecondShuffle; // 二次乱序（练习模式答错后再次打乱选项并动画）
  final ThemeMode themeMode;

  // 品鉴模式项目设置
  final bool enableBlindTasteAroma; // 是否启用香型品鉴
  final bool enableBlindTasteAlcohol; // 是否启用酒度品鉴
  final bool enableBlindTasteScore; // 是否启用总分品鉴
  final bool enableBlindTasteEquipment; // 是否启用设备品鉴
  final bool enableBlindTasteFermentation; // 是否启用发酵剂品鉴
  final bool enableBlindTasteRandomOrder; // 品鉴模式是否随机酒样顺序
  final bool enableFlashcardRandomOrder; // 闪卡模式是否随机酒样顺序
  final bool enableDefaultContinueProgress; // 是否默认继续进度（不显示确认对话框）
  final PracticeShuffleMode practiceShuffleMode; // 练习模式乱序模式
  final bool enableWineSimulationSameWineSeries; // 是否启用同酒样系列模式
  final int wineSimulationSampleCount; // 酒样练习模式的酒杯数量
  final double wineSimulationDuplicateProbability; // 酒样练习重复概率 (0.0-1.0)
  final int wineSimulationMaxDuplicateGroups; // 酒样练习最大重复组数
  final int multipleChoiceAutoSwitchDelay; // 多选题自动切题延迟时间（毫秒），范围1000-10000ms

  const QuizSettings({
    this.singleChoiceCount = 33,
    this.multipleChoiceCount = 33,
    this.booleanCount = 34,
    this.shuffleOptions = true,
    this.autoNextQuestion = true,
    this.enableProgressSave = true, // 默认启用进度保存
    this.examTimeMinutes = 15, // 默认考试时间15分钟
    this.enableSecondShuffle = false, // 默认关闭二次乱序
    this.enableBlindTasteAroma = false, // 默认启用香型品鉴
    this.enableBlindTasteAlcohol = true, // 默认启用酒度品鉴
    this.enableBlindTasteScore = true, // 默认启用总分品鉴
    this.enableBlindTasteEquipment = true, // 默认启用设备品鉴
    this.enableBlindTasteFermentation = true, // 默认启用发酵剂品鉴
    this.enableBlindTasteRandomOrder = true, // 默认启用品鉴模式随机酒样顺序
    this.enableFlashcardRandomOrder = true, // 默认启用闪卡模式随机酒样顺序
    this.enableDefaultContinueProgress = true, // 默认启用默认继续进度
    this.practiceShuffleMode = PracticeShuffleMode.fullRandom, // 默认完全乱序
    this.enableWineSimulationSameWineSeries = false, // 默认关闭同酒样系列模式
    this.wineSimulationSampleCount = 5, // 默认酒样练习模式酒杯数量为5
    this.wineSimulationDuplicateProbability = 0.3, // 默认30%概率出现重复酒样
    this.wineSimulationMaxDuplicateGroups = 1, // 默认最多1组重复酒样
    this.multipleChoiceAutoSwitchDelay = 1200, // 默认多选题自动切题延迟1200ms
    this.themeMode = ThemeMode.system,
  });

  QuizSettings copyWith({
    int? singleChoiceCount,
    int? multipleChoiceCount,
    int? booleanCount,
    bool? shuffleOptions,
    bool? autoNextQuestion,
    bool? enableProgressSave,
    int? examTimeMinutes,
    bool? enableSecondShuffle,
    bool? enableBlindTasteAroma,
    bool? enableBlindTasteAlcohol,
    bool? enableBlindTasteScore,
    bool? enableBlindTasteEquipment,
    bool? enableBlindTasteFermentation,
    bool? enableBlindTasteRandomOrder,
    bool? enableFlashcardRandomOrder,
    bool? enableDefaultContinueProgress,
    PracticeShuffleMode? practiceShuffleMode,
    bool? enableWineSimulationSameWineSeries,
    int? wineSimulationSampleCount,
    double? wineSimulationDuplicateProbability,
    int? wineSimulationMaxDuplicateGroups,
    int? multipleChoiceAutoSwitchDelay,
    ThemeMode? themeMode,
  }) {
    return QuizSettings(
      singleChoiceCount: singleChoiceCount ?? this.singleChoiceCount,
      multipleChoiceCount: multipleChoiceCount ?? this.multipleChoiceCount,
      booleanCount: booleanCount ?? this.booleanCount,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      autoNextQuestion: autoNextQuestion ?? this.autoNextQuestion,
      enableProgressSave: enableProgressSave ?? this.enableProgressSave,
      examTimeMinutes: examTimeMinutes ?? this.examTimeMinutes,
      enableSecondShuffle: enableSecondShuffle ?? this.enableSecondShuffle,
      enableBlindTasteAroma:
          enableBlindTasteAroma ?? this.enableBlindTasteAroma,
      enableBlindTasteAlcohol:
          enableBlindTasteAlcohol ?? this.enableBlindTasteAlcohol,
      enableBlindTasteScore:
          enableBlindTasteScore ?? this.enableBlindTasteScore,
      enableBlindTasteEquipment:
          enableBlindTasteEquipment ?? this.enableBlindTasteEquipment,
      enableBlindTasteFermentation:
          enableBlindTasteFermentation ?? this.enableBlindTasteFermentation,
      enableBlindTasteRandomOrder:
          enableBlindTasteRandomOrder ?? this.enableBlindTasteRandomOrder,
      enableFlashcardRandomOrder:
          enableFlashcardRandomOrder ?? this.enableFlashcardRandomOrder,
      enableDefaultContinueProgress:
          enableDefaultContinueProgress ?? this.enableDefaultContinueProgress,
      practiceShuffleMode: practiceShuffleMode ?? this.practiceShuffleMode,
      enableWineSimulationSameWineSeries:
          enableWineSimulationSameWineSeries ??
          this.enableWineSimulationSameWineSeries,
      wineSimulationSampleCount:
          wineSimulationSampleCount ?? this.wineSimulationSampleCount,
      wineSimulationDuplicateProbability:
          wineSimulationDuplicateProbability ??
          this.wineSimulationDuplicateProbability,
      wineSimulationMaxDuplicateGroups:
          wineSimulationMaxDuplicateGroups ??
          this.wineSimulationMaxDuplicateGroups,
      multipleChoiceAutoSwitchDelay:
          multipleChoiceAutoSwitchDelay ?? this.multipleChoiceAutoSwitchDelay,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  // 获取总题目数
  int get totalQuestions =>
      singleChoiceCount + multipleChoiceCount + booleanCount;

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'singleChoiceCount': singleChoiceCount,
      'multipleChoiceCount': multipleChoiceCount,
      'booleanCount': booleanCount,
      'shuffleOptions': shuffleOptions,
      'autoNextQuestion': autoNextQuestion,
      'enableProgressSave': enableProgressSave,
      'examTimeMinutes': examTimeMinutes,
      'enableSecondShuffle': enableSecondShuffle,
      'enableBlindTasteAroma': enableBlindTasteAroma,
      'enableBlindTasteAlcohol': enableBlindTasteAlcohol,
      'enableBlindTasteScore': enableBlindTasteScore,
      'enableBlindTasteEquipment': enableBlindTasteEquipment,
      'enableBlindTasteFermentation': enableBlindTasteFermentation,
      'enableBlindTasteRandomOrder': enableBlindTasteRandomOrder,
      'enableFlashcardRandomOrder': enableFlashcardRandomOrder,
      'enableDefaultContinueProgress': enableDefaultContinueProgress,
      'practiceShuffleMode': practiceShuffleMode.name,
      'enableWineSimulationSameWineSeries': enableWineSimulationSameWineSeries,
      'wineSimulationSampleCount': wineSimulationSampleCount,
      'wineSimulationDuplicateProbability': wineSimulationDuplicateProbability,
      'wineSimulationMaxDuplicateGroups': wineSimulationMaxDuplicateGroups,
      'multipleChoiceAutoSwitchDelay': multipleChoiceAutoSwitchDelay,
    };
  }

  // 从JSON创建
  factory QuizSettings.fromJson(Map<String, dynamic> json) {
    return QuizSettings(
      singleChoiceCount: json['singleChoiceCount'] ?? 5,
      multipleChoiceCount: json['multipleChoiceCount'] ?? 3,
      booleanCount: json['booleanCount'] ?? 2,
      shuffleOptions: json['shuffleOptions'] ?? true,
      autoNextQuestion: json['autoNextQuestion'] ?? false,
      enableProgressSave: json['enableProgressSave'] ?? true,
      examTimeMinutes: json['examTimeMinutes'] ?? 15,
      enableSecondShuffle: json['enableSecondShuffle'] ?? false,
      enableBlindTasteAroma: json['enableBlindTasteAroma'] ?? false,
      enableBlindTasteAlcohol: json['enableBlindTasteAlcohol'] ?? true,
      enableBlindTasteScore: json['enableBlindTasteScore'] ?? true,
      enableBlindTasteEquipment: json['enableBlindTasteEquipment'] ?? true,
      enableBlindTasteFermentation:
          json['enableBlindTasteFermentation'] ?? true,
      enableBlindTasteRandomOrder: json['enableBlindTasteRandomOrder'] ?? true,
      enableFlashcardRandomOrder: json['enableFlashcardRandomOrder'] ?? true,
      enableDefaultContinueProgress:
          json['enableDefaultContinueProgress'] ?? true,
      practiceShuffleMode: _parsePracticeShuffleMode(
        json['practiceShuffleMode'],
      ),
      enableWineSimulationSameWineSeries:
          json['enableWineSimulationSameWineSeries'] ?? false,
      wineSimulationSampleCount: json['wineSimulationSampleCount'] ?? 5,
      wineSimulationDuplicateProbability:
          json['wineSimulationDuplicateProbability'] ?? 0.3,
      wineSimulationMaxDuplicateGroups:
          json['wineSimulationMaxDuplicateGroups'] ?? 1,
      multipleChoiceAutoSwitchDelay:
          json['multipleChoiceAutoSwitchDelay'] ?? 1200,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizSettings &&
        other.singleChoiceCount == singleChoiceCount &&
        other.multipleChoiceCount == multipleChoiceCount &&
        other.booleanCount == booleanCount &&
        other.shuffleOptions == shuffleOptions &&
        other.autoNextQuestion == autoNextQuestion &&
        other.enableProgressSave == enableProgressSave &&
        other.examTimeMinutes == examTimeMinutes &&
        other.enableSecondShuffle == enableSecondShuffle &&
        other.enableBlindTasteAroma == enableBlindTasteAroma &&
        other.enableBlindTasteAlcohol == enableBlindTasteAlcohol &&
        other.enableBlindTasteScore == enableBlindTasteScore &&
        other.enableBlindTasteEquipment == enableBlindTasteEquipment &&
        other.enableBlindTasteFermentation == enableBlindTasteFermentation &&
        other.enableBlindTasteRandomOrder == enableBlindTasteRandomOrder &&
        other.enableFlashcardRandomOrder == enableFlashcardRandomOrder &&
        other.enableDefaultContinueProgress == enableDefaultContinueProgress &&
        other.practiceShuffleMode == practiceShuffleMode &&
        other.enableWineSimulationSameWineSeries ==
            enableWineSimulationSameWineSeries &&
        other.wineSimulationSampleCount == wineSimulationSampleCount &&
        other.wineSimulationDuplicateProbability ==
            wineSimulationDuplicateProbability &&
        other.wineSimulationMaxDuplicateGroups ==
            wineSimulationMaxDuplicateGroups &&
        other.multipleChoiceAutoSwitchDelay == multipleChoiceAutoSwitchDelay;
  }

  @override
  int get hashCode {
    return singleChoiceCount.hashCode ^
        multipleChoiceCount.hashCode ^
        booleanCount.hashCode ^
        shuffleOptions.hashCode ^
        autoNextQuestion.hashCode ^
        enableProgressSave.hashCode ^
        examTimeMinutes.hashCode ^
        enableSecondShuffle.hashCode ^
        enableBlindTasteAroma.hashCode ^
        enableBlindTasteAlcohol.hashCode ^
        enableBlindTasteScore.hashCode ^
        enableBlindTasteEquipment.hashCode ^
        enableBlindTasteFermentation.hashCode ^
        enableBlindTasteRandomOrder.hashCode ^
        enableFlashcardRandomOrder.hashCode ^
        enableDefaultContinueProgress.hashCode ^
        practiceShuffleMode.hashCode ^
        enableWineSimulationSameWineSeries.hashCode ^
        wineSimulationSampleCount.hashCode ^
        wineSimulationDuplicateProbability.hashCode ^
        wineSimulationMaxDuplicateGroups.hashCode ^
        multipleChoiceAutoSwitchDelay.hashCode;
  }

  // 解析练习模式乱序模式
  static PracticeShuffleMode _parsePracticeShuffleMode(dynamic value) {
    if (value == null) return PracticeShuffleMode.fullRandom;

    switch (value.toString()) {
      case 'fullRandom':
        return PracticeShuffleMode.fullRandom;
      case 'ordered':
        return PracticeShuffleMode.ordered;
      case 'typeOrderedQuestionRandom':
        return PracticeShuffleMode.typeOrderedQuestionRandom;
      default:
        // 兼容旧版本的布尔值设置
        if (value is bool) {
          return value
              ? PracticeShuffleMode.fullRandom
              : PracticeShuffleMode.ordered;
        }
        return PracticeShuffleMode.fullRandom;
    }
  }

  // 获取练习模式乱序模式的显示名称
  String get practiceShuffleModeDisplayName {
    switch (practiceShuffleMode) {
      case PracticeShuffleMode.fullRandom:
        return '完全乱序';
      case PracticeShuffleMode.ordered:
        return '默认顺序';
      case PracticeShuffleMode.typeOrderedQuestionRandom:
        return '题型顺序，题目乱序';
    }
  }

  // 获取练习模式乱序模式的描述
  String get practiceShuffleModeDescription {
    switch (practiceShuffleMode) {
      case PracticeShuffleMode.fullRandom:
        return '题型和题型内部题目顺序均乱序';
      case PracticeShuffleMode.ordered:
        return '题型不乱序，题目不乱序，使用默认顺序';
      case PracticeShuffleMode.typeOrderedQuestionRandom:
        return '题型不乱序，内部题目乱序';
    }
  }

  // 兼容性方法：获取是否为随机模式（用于向后兼容）
  bool get enablePracticeRandomOrder {
    return practiceShuffleMode == PracticeShuffleMode.fullRandom;
  }

  // 强制香型品评始终禁用（覆盖原始值）
  bool get enableBlindTasteAromaForced => false;
}
