// 设置数据模型
class QuizSettings {
  final int singleChoiceCount;
  final int multipleChoiceCount;
  final int booleanCount;
  final bool shuffleOptions;
  final bool autoNextQuestion;
  final bool enableProgressSave; // 是否启用进度保存
  final int examTimeMinutes; // 考试时间（分钟）

  // 品鉴模式项目设置
  final bool enableBlindTasteAroma; // 是否启用香型品鉴
  final bool enableBlindTasteAlcohol; // 是否启用酒度品鉴
  final bool enableBlindTasteScore; // 是否启用总分品鉴
  final bool enableBlindTasteEquipment; // 是否启用设备品鉴
  final bool enableBlindTasteFermentation; // 是否启用发酵剂品鉴

  const QuizSettings({
    this.singleChoiceCount = 33,
    this.multipleChoiceCount = 33,
    this.booleanCount = 34,
    this.shuffleOptions = true,
    this.autoNextQuestion = true,
    this.enableProgressSave = true, // 默认启用进度保存
    this.examTimeMinutes = 15, // 默认考试时间15分钟
    this.enableBlindTasteAroma = true, // 默认启用香型品鉴
    this.enableBlindTasteAlcohol = true, // 默认启用酒度品鉴
    this.enableBlindTasteScore = true, // 默认启用总分品鉴
    this.enableBlindTasteEquipment = true, // 默认启用设备品鉴
    this.enableBlindTasteFermentation = true, // 默认启用发酵剂品鉴
  });

  QuizSettings copyWith({
    int? singleChoiceCount,
    int? multipleChoiceCount,
    int? booleanCount,
    bool? shuffleOptions,
    bool? autoNextQuestion,
    bool? enableProgressSave,
    int? examTimeMinutes,
    bool? enableBlindTasteAroma,
    bool? enableBlindTasteAlcohol,
    bool? enableBlindTasteScore,
    bool? enableBlindTasteEquipment,
    bool? enableBlindTasteFermentation,
  }) {
    return QuizSettings(
      singleChoiceCount: singleChoiceCount ?? this.singleChoiceCount,
      multipleChoiceCount: multipleChoiceCount ?? this.multipleChoiceCount,
      booleanCount: booleanCount ?? this.booleanCount,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      autoNextQuestion: autoNextQuestion ?? this.autoNextQuestion,
      enableProgressSave: enableProgressSave ?? this.enableProgressSave,
      examTimeMinutes: examTimeMinutes ?? this.examTimeMinutes,
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
      'enableBlindTasteAroma': enableBlindTasteAroma,
      'enableBlindTasteAlcohol': enableBlindTasteAlcohol,
      'enableBlindTasteScore': enableBlindTasteScore,
      'enableBlindTasteEquipment': enableBlindTasteEquipment,
      'enableBlindTasteFermentation': enableBlindTasteFermentation,
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
      enableBlindTasteAroma: json['enableBlindTasteAroma'] ?? true,
      enableBlindTasteAlcohol: json['enableBlindTasteAlcohol'] ?? true,
      enableBlindTasteScore: json['enableBlindTasteScore'] ?? true,
      enableBlindTasteEquipment: json['enableBlindTasteEquipment'] ?? true,
      enableBlindTasteFermentation:
          json['enableBlindTasteFermentation'] ?? true,
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
        other.enableBlindTasteAroma == enableBlindTasteAroma &&
        other.enableBlindTasteAlcohol == enableBlindTasteAlcohol &&
        other.enableBlindTasteScore == enableBlindTasteScore &&
        other.enableBlindTasteEquipment == enableBlindTasteEquipment &&
        other.enableBlindTasteFermentation == enableBlindTasteFermentation;
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
        enableBlindTasteAroma.hashCode ^
        enableBlindTasteAlcohol.hashCode ^
        enableBlindTasteScore.hashCode ^
        enableBlindTasteEquipment.hashCode ^
        enableBlindTasteFermentation.hashCode;
  }
}
