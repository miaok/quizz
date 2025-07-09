import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/database_service.dart';

// 数据库服务Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// 题目分类Provider
final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  return await dbService.getAllCategories();
});

// 题目总数Provider
final questionCountProvider = FutureProvider<int>((ref) async {
  final dbService = ref.read(databaseServiceProvider);
  return await dbService.getQuestionCount();
});

// 答题状态枚举
enum QuizStatus { initial, loading, inProgress, completed, error }

// 答题模式枚举
enum QuizMode {
  practice, // 练习模式（开始答题）
  exam, // 考试模式（模拟考试）
}

// 答题状态类
class QuizState {
  final QuizStatus status;
  final QuizMode mode; // 答题模式
  final List<QuestionModel> questions;
  final int currentQuestionIndex;
  final Map<int, dynamic> userAnswers; // 用户答案
  final Map<int, DateTime> questionStartTimes; // 每题开始时间
  final DateTime? quizStartTime; // 答题开始时间
  final String? selectedCategory;
  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.initial,
    this.mode = QuizMode.exam, // 默认考试模式
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.questionStartTimes = const {},
    this.quizStartTime,
    this.selectedCategory,
    this.errorMessage,
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizMode? mode,
    List<QuestionModel>? questions,
    int? currentQuestionIndex,
    Map<int, dynamic>? userAnswers,
    Map<int, DateTime>? questionStartTimes,
    DateTime? quizStartTime,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      questionStartTimes: questionStartTimes ?? this.questionStartTimes,
      quizStartTime: quizStartTime ?? this.quizStartTime,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // 获取当前题目
  QuestionModel? get currentQuestion {
    if (currentQuestionIndex < questions.length) {
      return questions[currentQuestionIndex];
    }
    return null;
  }

  // 获取进度
  double get progress {
    if (questions.isEmpty) return 0.0;
    return currentQuestionIndex / questions.length;
  }

  // 是否是最后一题
  bool get isLastQuestion => currentQuestionIndex >= questions.length - 1;

  // 获取已回答题目数
  int get answeredCount => userAnswers.length;
}

// 答题控制器
class QuizController extends StateNotifier<QuizState> {
  final DatabaseService _databaseService;

  QuizController(this._databaseService) : super(const QuizState());

  // 开始答题
  Future<void> startQuiz({String? category, int questionCount = 10}) async {
    state = state.copyWith(
      status: QuizStatus.loading,
      selectedCategory: category,
    );

    try {
      List<QuestionModel> questions;
      if (category != null && category != '全部') {
        questions = await _databaseService.getRandomQuestionsByCategory(
          category,
          questionCount,
        );
      } else {
        questions = await _databaseService.getRandomQuestions(questionCount);
      }

      if (questions.isEmpty) {
        state = state.copyWith(
          status: QuizStatus.error,
          errorMessage: '没有找到题目',
        );
        return;
      }

      state = state.copyWith(
        status: QuizStatus.inProgress,
        questions: questions,
        currentQuestionIndex: 0,
        userAnswers: {},
        questionStartTimes: {0: DateTime.now()},
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: '加载题目失败: $e',
      );
    }
  }

  // 根据设置开始答题
  Future<void> startQuizWithSettings({
    required int singleCount,
    required int multipleCount,
    required int booleanCount,
    required bool shuffleOptions,
  }) async {
    state = state.copyWith(status: QuizStatus.loading);

    try {
      final questions = await _databaseService.getQuestionsBySettings(
        singleCount: singleCount,
        multipleCount: multipleCount,
        booleanCount: booleanCount,
        shuffleOptions: shuffleOptions,
      );

      if (questions.isEmpty) {
        state = state.copyWith(
          status: QuizStatus.error,
          errorMessage: '没有找到题目',
        );
        return;
      }

      final now = DateTime.now();
      state = state.copyWith(
        status: QuizStatus.inProgress,
        mode: QuizMode.exam, // 考试模式
        questions: questions,
        currentQuestionIndex: 0,
        userAnswers: {},
        questionStartTimes: {0: now},
        quizStartTime: now,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: '加载题目失败: $e',
      );
    }
  }

  // 开始全题库答题（使用用户设置）
  Future<void> startAllQuestionsQuiz({required bool shuffleOptions}) async {
    state = state.copyWith(status: QuizStatus.loading);

    try {
      List<QuestionModel> questions = await _databaseService.getAllQuestions();

      if (questions.isEmpty) {
        state = state.copyWith(
          status: QuizStatus.error,
          errorMessage: '没有找到题目',
        );
        return;
      }

      // 打乱题目顺序
      questions.shuffle();

      // 如果需要乱序选项
      if (shuffleOptions) {
        questions = questions.map((q) => q.shuffleOptions()).toList();
      }

      final now = DateTime.now();
      state = state.copyWith(
        status: QuizStatus.inProgress,
        mode: QuizMode.practice, // 练习模式
        questions: questions,
        currentQuestionIndex: 0,
        userAnswers: {},
        questionStartTimes: {0: now},
        quizStartTime: now,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        errorMessage: '加载题目失败: $e',
      );
    }
  }

  // 提交答案
  void submitAnswer(dynamic answer) {
    if (state.status != QuizStatus.inProgress) return;

    final newAnswers = Map<int, dynamic>.from(state.userAnswers);
    newAnswers[state.currentQuestionIndex] = answer;

    state = state.copyWith(userAnswers: newAnswers);
  }

  // 检查当前答案是否正确（用于练习模式）
  bool isCurrentAnswerCorrect() {
    if (state.questions.isEmpty ||
        state.currentQuestionIndex >= state.questions.length) {
      return false;
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final userAnswer = state.userAnswers[state.currentQuestionIndex];

    return currentQuestion.isAnswerCorrect(userAnswer);
  }

  // 重置当前题目的答案（用于练习模式答错时）
  void resetCurrentAnswer() {
    if (state.status != QuizStatus.inProgress) return;

    final newAnswers = Map<int, dynamic>.from(state.userAnswers);
    newAnswers.remove(state.currentQuestionIndex);

    state = state.copyWith(userAnswers: newAnswers);
  }

  // 下一题
  void nextQuestion() {
    if (state.status != QuizStatus.inProgress) return;

    final nextIndex = state.currentQuestionIndex + 1;

    if (nextIndex >= state.questions.length) {
      // 答题完成
      state = state.copyWith(status: QuizStatus.completed);
    } else {
      // 进入下一题
      final newStartTimes = Map<int, DateTime>.from(state.questionStartTimes);
      newStartTimes[nextIndex] = DateTime.now();

      state = state.copyWith(
        currentQuestionIndex: nextIndex,
        questionStartTimes: newStartTimes,
      );
    }
  }

  // 上一题
  void previousQuestion() {
    if (state.status != QuizStatus.inProgress) return;
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  // 跳转到指定题目
  void goToQuestion(int index) {
    if (state.status != QuizStatus.inProgress) return;
    if (index >= 0 && index < state.questions.length) {
      final newStartTimes = Map<int, DateTime>.from(state.questionStartTimes);
      if (!newStartTimes.containsKey(index)) {
        newStartTimes[index] = DateTime.now();
      }

      state = state.copyWith(
        currentQuestionIndex: index,
        questionStartTimes: newStartTimes,
      );
    }
  }

  // 获取答题结果
  QuizResult getResult() {
    final questionResults = <QuestionResult>[];
    final now = DateTime.now();

    for (int i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final userAnswer = state.userAnswers[i];
      final isCorrect = question.isAnswerCorrect(userAnswer);

      // 计算答题时间（简化处理）
      final startTime = state.questionStartTimes[i] ?? now;
      final timeSpent = now.difference(startTime);

      questionResults.add(
        QuestionResult(
          question: question,
          userAnswer: userAnswer,
          isCorrect: isCorrect,
          timeSpent: timeSpent,
        ),
      );
    }

    final correctCount = questionResults.where((r) => r.isCorrect).length;

    // 计算总答题用时
    final totalTimeSpent = state.quizStartTime != null
        ? now.difference(state.quizStartTime!)
        : Duration.zero;

    return QuizResult(
      totalQuestions: state.questions.length,
      correctAnswers: correctCount,
      questionResults: questionResults,
      completedAt: now,
      totalTimeSpent: totalTimeSpent,
    );
  }

  // 重置答题状态
  void reset() {
    state = const QuizState();
  }
}

// 答题控制器Provider
final quizControllerProvider = StateNotifierProvider<QuizController, QuizState>(
  (ref) {
    final databaseService = ref.read(databaseServiceProvider);
    return QuizController(databaseService);
  },
);
