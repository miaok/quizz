// 题目类型枚举
enum QuestionType {
  single, // 单选题
  multiple, // 多选题
  boolean, // 判断题
}

// 题目数据模型
class QuestionModel {
  final String question;
  final List<String> options;
  final QuestionType type;
  final dynamic answer; // 可能是String或List<String>
  final String? explanation;
  final String category;
  final List<int>? originalIndices; // 原始选项索引，用于乱序后的答案映射

  QuestionModel({
    required this.question,
    required this.options,
    required this.type,
    required this.answer,
    this.explanation,
    this.category = '通用',
    this.originalIndices,
  });

  // 从JSON创建QuestionModel
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    QuestionType type;
    switch (json['type'] as String) {
      case 'single':
        type = QuestionType.single;
        break;
      case 'multiple':
        type = QuestionType.multiple;
        break;
      case 'boolean':
        type = QuestionType.boolean;
        break;
      default:
        type = QuestionType.single;
    }

    return QuestionModel(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      type: type,
      answer: json['answer'],
      explanation: json['explanation'] as String?,
      category: json['category'] as String? ?? '通用',
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'type': type.name,
      'answer': answer,
      'explanation': explanation,
      'category': category,
    };
  }

  // 创建乱序选项的题目副本
  QuestionModel shuffleOptions() {
    if (options.length <= 1) return this; // 选项太少，无需乱序

    // 创建索引列表并乱序
    final indices = List.generate(options.length, (index) => index);
    indices.shuffle();

    // 根据乱序后的索引重新排列选项
    final shuffledOptions = indices.map((i) => options[i]).toList();

    // 更新答案以匹配新的选项顺序
    dynamic newAnswer;
    if (type == QuestionType.multiple && answer is List) {
      final correctAnswers = answer as List;
      newAnswer = correctAnswers.map((ans) {
        final originalIndex = options.indexOf(ans.toString());
        if (originalIndex != -1) {
          final newIndex = indices.indexOf(originalIndex);
          return shuffledOptions[newIndex];
        }
        return ans;
      }).toList();
    } else {
      final originalIndex = options.indexOf(answer.toString());
      if (originalIndex != -1) {
        final newIndex = indices.indexOf(originalIndex);
        newAnswer = shuffledOptions[newIndex];
      } else {
        newAnswer = answer;
      }
    }

    return QuestionModel(
      question: question,
      options: shuffledOptions,
      type: type,
      answer: newAnswer,
      explanation: explanation,
      category: category,
      originalIndices: indices,
    );
  }

  // 获取正确答案的索引列表（用于数据库存储）
  List<int> getCorrectAnswerIndices() {
    if (type == QuestionType.multiple) {
      if (answer is List) {
        final correctAnswers = answer as List;
        return correctAnswers
            .map((ans) => options.indexOf(ans.toString()))
            .where((index) => index != -1)
            .toList();
      } else {
        return [];
      }
    } else {
      final correctAnswer = answer.toString();
      final index = options.indexOf(correctAnswer);
      return index != -1 ? [index] : [];
    }
  }

  // 检查答案是否正确
  bool isAnswerCorrect(dynamic userAnswer) {
    if (userAnswer == null) return false;

    if (type == QuestionType.multiple) {
      // 安全地处理正确答案
      Set<String> correctAnswers;
      if (answer is List) {
        correctAnswers = Set<String>.from(
          (answer as List).map((e) => e.toString()),
        );
      } else {
        return false;
      }

      // 安全地处理用户答案
      Set<String> userAnswers;
      if (userAnswer is List) {
        userAnswers = Set<String>.from(userAnswer.map((e) => e.toString()));
      } else {
        return false; // 多选题用户答案必须是列表
      }

      return correctAnswers.difference(userAnswers).isEmpty &&
          userAnswers.difference(correctAnswers).isEmpty;
    } else {
      return answer.toString() == userAnswer.toString();
    }
  }

  // 获取正确答案的显示文本
  String getCorrectAnswerText() {
    if (type == QuestionType.multiple) {
      if (answer is List) {
        final correctAnswers = answer as List;
        return correctAnswers.map((e) => e.toString()).join(', ');
      } else {
        return answer.toString();
      }
    } else {
      return answer.toString();
    }
  }
}

// 答题结果模型
class QuizResult {
  final int totalQuestions;
  final int correctAnswers;
  final List<QuestionResult> questionResults;
  final DateTime completedAt;
  final Duration totalTimeSpent; // 总答题用时

  QuizResult({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questionResults,
    required this.completedAt,
    required this.totalTimeSpent,
  });

  double get score =>
      totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;

  String get scoreText => '${score.toStringAsFixed(1)}%';

  // 格式化总用时显示
  String get totalTimeText {
    final minutes = totalTimeSpent.inMinutes;
    final seconds = totalTimeSpent.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// 单题结果模型
class QuestionResult {
  final QuestionModel question;
  final dynamic userAnswer;
  final bool isCorrect;
  final Duration timeSpent;

  QuestionResult({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpent,
  });

  String get userAnswerText {
    if (userAnswer == null) return '未作答';

    if (question.type == QuestionType.multiple) {
      if (userAnswer is List) {
        final answers = userAnswer.map((e) => e.toString()).toList();
        return answers.isEmpty ? '未作答' : answers.join(', ');
      } else {
        return '未作答';
      }
    } else {
      return userAnswer.toString();
    }
  }
}
