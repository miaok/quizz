// 设置数据模型
class QuizSettings {
  final int singleChoiceCount;
  final int multipleChoiceCount;
  final int booleanCount;
  final bool shuffleOptions;
  final bool autoNextQuestion;
  final bool enableProgressSave; // 是否启用进度保存

  const QuizSettings({
    this.singleChoiceCount = 30,
    this.multipleChoiceCount = 40,
    this.booleanCount = 30,
    this.shuffleOptions = true,
    this.autoNextQuestion = true,
    this.enableProgressSave = true, // 默认启用进度保存
  });

  QuizSettings copyWith({
    int? singleChoiceCount,
    int? multipleChoiceCount,
    int? booleanCount,
    bool? shuffleOptions,
    bool? autoNextQuestion,
    bool? enableProgressSave,
  }) {
    return QuizSettings(
      singleChoiceCount: singleChoiceCount ?? this.singleChoiceCount,
      multipleChoiceCount: multipleChoiceCount ?? this.multipleChoiceCount,
      booleanCount: booleanCount ?? this.booleanCount,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      autoNextQuestion: autoNextQuestion ?? this.autoNextQuestion,
      enableProgressSave: enableProgressSave ?? this.enableProgressSave,
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
        other.enableProgressSave == enableProgressSave;
  }

  @override
  int get hashCode {
    return singleChoiceCount.hashCode ^
        multipleChoiceCount.hashCode ^
        booleanCount.hashCode ^
        shuffleOptions.hashCode ^
        autoNextQuestion.hashCode ^
        enableProgressSave.hashCode;
  }
}
