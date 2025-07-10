import 'question_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/blind_taste_provider.dart';
import 'blind_taste_model.dart';

// 进度类型枚举
enum ProgressType {
  quiz, // 答题进度
  blindTaste, // 品鉴进度
}

// 答题进度模型
class QuizProgress {
  final ProgressType type;
  final QuizMode? mode; // 答题模式（仅答题进度有效）
  final List<QuestionModel> questions; // 题目列表（仅答题进度有效）
  final int currentIndex; // 当前题目/品鉴索引
  final Map<int, dynamic> userAnswers; // 用户答案
  final Map<int, DateTime> questionStartTimes; // 每题开始时间
  final DateTime? startTime; // 开始时间
  final String? selectedCategory; // 选择的分类
  final DateTime savedAt; // 保存时间

  // 品鉴相关字段
  final int? blindTasteItemId; // 当前品鉴项目的ID
  final BlindTasteAnswer? blindTasteAnswer; // 品鉴答案
  final List<BlindTasteItemModel>? blindTasteQuestionPool; // 品鉴题目池
  final Set<int>? blindTasteCompletedIds; // 已完成的品鉴题目ID
  final int? blindTasteMaxItems; // 每轮最大题目数
  final String? blindTasteAromaFilter; // 香型筛选
  final double? blindTasteMinAlcohol; // 最小酒度
  final double? blindTasteMaxAlcohol; // 最大酒度

  const QuizProgress({
    required this.type,
    this.mode,
    this.questions = const [],
    this.currentIndex = 0,
    this.userAnswers = const {},
    this.questionStartTimes = const {},
    this.startTime,
    this.selectedCategory,
    required this.savedAt,
    this.blindTasteItemId,
    this.blindTasteAnswer,
    this.blindTasteQuestionPool,
    this.blindTasteCompletedIds,
    this.blindTasteMaxItems,
    this.blindTasteAromaFilter,
    this.blindTasteMinAlcohol,
    this.blindTasteMaxAlcohol,
  });

  // 从答题状态创建进度
  factory QuizProgress.fromQuizState(QuizState state) {
    return QuizProgress(
      type: ProgressType.quiz,
      mode: state.mode,
      questions: state.questions,
      currentIndex: state.currentQuestionIndex,
      userAnswers: state.userAnswers,
      questionStartTimes: state.questionStartTimes,
      startTime: state.quizStartTime,
      selectedCategory: state.selectedCategory,
      savedAt: DateTime.now(),
    );
  }

  // 从品鉴状态创建进度
  factory QuizProgress.fromBlindTasteState(BlindTasteState state) {
    return QuizProgress(
      type: ProgressType.blindTaste,
      currentIndex: state.currentIndex,
      startTime: DateTime.now(), // 品鉴没有开始时间，使用当前时间
      savedAt: DateTime.now(),
      blindTasteItemId: state.currentItem?.id,
      blindTasteAnswer: state.userAnswer,
      blindTasteQuestionPool: state.questionPool,
      blindTasteCompletedIds: state.completedItemIds,
      blindTasteMaxItems: state.maxItemsPerRound,
      blindTasteAromaFilter: state.selectedAromaFilter,
      blindTasteMinAlcohol: state.minAlcoholDegree,
      blindTasteMaxAlcohol: state.maxAlcoholDegree,
    );
  }

  // 复制并更新
  QuizProgress copyWith({
    ProgressType? type,
    QuizMode? mode,
    List<QuestionModel>? questions,
    int? currentIndex,
    Map<int, dynamic>? userAnswers,
    Map<int, DateTime>? questionStartTimes,
    DateTime? startTime,
    String? selectedCategory,
    DateTime? savedAt,
    int? blindTasteItemId,
    BlindTasteAnswer? blindTasteAnswer,
    List<BlindTasteItemModel>? blindTasteQuestionPool,
    Set<int>? blindTasteCompletedIds,
    int? blindTasteMaxItems,
    String? blindTasteAromaFilter,
    double? blindTasteMinAlcohol,
    double? blindTasteMaxAlcohol,
  }) {
    return QuizProgress(
      type: type ?? this.type,
      mode: mode ?? this.mode,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      questionStartTimes: questionStartTimes ?? this.questionStartTimes,
      startTime: startTime ?? this.startTime,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      savedAt: savedAt ?? this.savedAt,
      blindTasteItemId: blindTasteItemId ?? this.blindTasteItemId,
      blindTasteAnswer: blindTasteAnswer ?? this.blindTasteAnswer,
      blindTasteQuestionPool:
          blindTasteQuestionPool ?? this.blindTasteQuestionPool,
      blindTasteCompletedIds:
          blindTasteCompletedIds ?? this.blindTasteCompletedIds,
      blindTasteMaxItems: blindTasteMaxItems ?? this.blindTasteMaxItems,
      blindTasteAromaFilter:
          blindTasteAromaFilter ?? this.blindTasteAromaFilter,
      blindTasteMinAlcohol: blindTasteMinAlcohol ?? this.blindTasteMinAlcohol,
      blindTasteMaxAlcohol: blindTasteMaxAlcohol ?? this.blindTasteMaxAlcohol,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'mode': mode?.name,
      'questions': questions.map((q) => q.toJson()).toList(),
      'currentIndex': currentIndex,
      'userAnswers': userAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'questionStartTimes': questionStartTimes.map(
        (key, value) => MapEntry(key.toString(), value.millisecondsSinceEpoch),
      ),
      'startTime': startTime?.millisecondsSinceEpoch,
      'selectedCategory': selectedCategory,
      'savedAt': savedAt.millisecondsSinceEpoch,
      'blindTasteItemId': blindTasteItemId,
      'blindTasteAnswer': blindTasteAnswer?.toJson(),
      'blindTasteQuestionPool': blindTasteQuestionPool
          ?.map((item) => item.toJson())
          .toList(),
      'blindTasteCompletedIds': blindTasteCompletedIds?.toList(),
      'blindTasteMaxItems': blindTasteMaxItems,
      'blindTasteAromaFilter': blindTasteAromaFilter,
      'blindTasteMinAlcohol': blindTasteMinAlcohol,
      'blindTasteMaxAlcohol': blindTasteMaxAlcohol,
    };
  }

  // 从JSON创建
  factory QuizProgress.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = ProgressType.values.firstWhere((e) => e.name == typeStr);

    QuizMode? mode;
    if (json['mode'] != null) {
      final modeStr = json['mode'] as String;
      mode = QuizMode.values.firstWhere((e) => e.name == modeStr);
    }

    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    final questions = questionsJson
        .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();

    final userAnswersJson = json['userAnswers'] as Map<String, dynamic>? ?? {};
    final userAnswers = userAnswersJson.map((key, value) {
      // 安全地处理用户答案，特别是多选题的List<String>类型
      dynamic processedValue = value;
      if (value is List) {
        // 如果是列表（多选题答案），确保转换为List<String>
        processedValue = value.map((e) => e.toString()).toList();
      }
      return MapEntry(int.parse(key), processedValue);
    });

    final questionStartTimesJson =
        json['questionStartTimes'] as Map<String, dynamic>? ?? {};
    final questionStartTimes = questionStartTimesJson.map(
      (key, value) => MapEntry(
        int.parse(key),
        DateTime.fromMillisecondsSinceEpoch(value as int),
      ),
    );

    DateTime? startTime;
    if (json['startTime'] != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int);
    }

    final savedAt = DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int);

    BlindTasteAnswer? blindTasteAnswer;
    if (json['blindTasteAnswer'] != null) {
      blindTasteAnswer = BlindTasteAnswer.fromJson(
        json['blindTasteAnswer'] as Map<String, dynamic>,
      );
    }

    // 处理品鉴题目池
    List<BlindTasteItemModel>? blindTasteQuestionPool;
    if (json['blindTasteQuestionPool'] != null) {
      final poolJson = json['blindTasteQuestionPool'] as List<dynamic>;
      blindTasteQuestionPool = poolJson
          .map(
            (item) =>
                BlindTasteItemModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    // 处理已完成题目ID集合
    Set<int>? blindTasteCompletedIds;
    if (json['blindTasteCompletedIds'] != null) {
      final completedJson = json['blindTasteCompletedIds'] as List<dynamic>;
      blindTasteCompletedIds = completedJson.map((id) => id as int).toSet();
    }

    return QuizProgress(
      type: type,
      mode: mode,
      questions: questions,
      currentIndex: json['currentIndex'] as int? ?? 0,
      userAnswers: userAnswers,
      questionStartTimes: questionStartTimes,
      startTime: startTime,
      selectedCategory: json['selectedCategory'] as String?,
      savedAt: savedAt,
      blindTasteItemId: json['blindTasteItemId'] as int?,
      blindTasteAnswer: blindTasteAnswer,
      blindTasteQuestionPool: blindTasteQuestionPool,
      blindTasteCompletedIds: blindTasteCompletedIds,
      blindTasteMaxItems: json['blindTasteMaxItems'] as int?,
      blindTasteAromaFilter: json['blindTasteAromaFilter'] as String?,
      blindTasteMinAlcohol: json['blindTasteMinAlcohol'] as double?,
      blindTasteMaxAlcohol: json['blindTasteMaxAlcohol'] as double?,
    );
  }

  // 检查进度是否有效
  bool get isValid {
    switch (type) {
      case ProgressType.quiz:
        return questions.isNotEmpty &&
            currentIndex >= 0 &&
            currentIndex < questions.length;
      case ProgressType.blindTaste:
        return blindTasteItemId != null;
    }
  }

  // 获取进度描述
  String get description {
    switch (type) {
      case ProgressType.quiz:
        final modeText = mode == QuizMode.practice ? '练习模式' : '考试模式';
        return '$modeText - 第${currentIndex + 1}题/共${questions.length}题';
      case ProgressType.blindTaste:
        return '品鉴模式 - 酒样品鉴进行中';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizProgress &&
        other.type == type &&
        other.mode == mode &&
        other.currentIndex == currentIndex &&
        other.savedAt == savedAt;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        mode.hashCode ^
        currentIndex.hashCode ^
        savedAt.hashCode;
  }
}
