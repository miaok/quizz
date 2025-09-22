/// 理论模拟得分记录模型
class ScoreRecord {
  final DateTime examTime; // 考试时间
  final Duration duration; // 用时
  final double score; // 得分百分比
  final int totalQuestions; // 总题数
  final int correctAnswers; // 正确答案数
  final int singleChoiceCount; // 单选题数量
  final int multipleChoiceCount; // 多选题数量
  final int booleanCount; // 判断题数量

  const ScoreRecord({
    required this.examTime,
    required this.duration,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.singleChoiceCount,
    required this.multipleChoiceCount,
    required this.booleanCount,
  });

  /// 获取错误答案数
  int get wrongAnswers => totalQuestions - correctAnswers;

  /// 获取得分等级
  String get scoreLevel {
    if (score >= 90) return '优秀';
    if (score >= 80) return '良好';
    if (score >= 60) return '及格';
    return '不及格';
  }

  /// 获取用时文本
  String get durationText {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours小时$minutes分$seconds秒';
    } else if (minutes > 0) {
      return '$minutes分$seconds秒';
    } else {
      return '$seconds秒';
    }
  }

  /// 获取考试时间文本
  String get examTimeText {
    return '${examTime.year}-${examTime.month.toString().padLeft(2, '0')}-${examTime.day.toString().padLeft(2, '0')} '
        '${examTime.hour.toString().padLeft(2, '0')}:${examTime.minute.toString().padLeft(2, '0')}';
  }

  /// 获取得分文本
  String get scoreText {
    return '${score.toStringAsFixed(1)}分';
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'examTime': examTime.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'singleChoiceCount': singleChoiceCount,
      'multipleChoiceCount': multipleChoiceCount,
      'booleanCount': booleanCount,
    };
  }

  /// 从JSON创建
  factory ScoreRecord.fromJson(Map<String, dynamic> json) {
    return ScoreRecord(
      examTime: DateTime.fromMillisecondsSinceEpoch(json['examTime'] as int),
      duration: Duration(milliseconds: json['duration'] as int),
      score: (json['score'] as num).toDouble(),
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      singleChoiceCount: json['singleChoiceCount'] as int,
      multipleChoiceCount: json['multipleChoiceCount'] as int,
      booleanCount: json['booleanCount'] as int,
    );
  }

  /// 从答题结果创建记录
  factory ScoreRecord.fromQuizResult({
    required dynamic result, // QuizResult类型
    required int singleChoiceCount,
    required int multipleChoiceCount,
    required int booleanCount,
  }) {
    return ScoreRecord(
      examTime: result.completedAt,
      duration: result.totalTimeSpent,
      score: result.score,
      totalQuestions: result.totalQuestions,
      correctAnswers: result.correctAnswers,
      singleChoiceCount: singleChoiceCount,
      multipleChoiceCount: multipleChoiceCount,
      booleanCount: booleanCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScoreRecord &&
        other.examTime == examTime &&
        other.duration == duration &&
        other.score == score &&
        other.totalQuestions == totalQuestions &&
        other.correctAnswers == correctAnswers;
  }

  @override
  int get hashCode {
    return examTime.hashCode ^
        duration.hashCode ^
        score.hashCode ^
        totalQuestions.hashCode ^
        correctAnswers.hashCode;
  }
}
