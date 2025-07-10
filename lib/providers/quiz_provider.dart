import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/progress_model.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';

// 数据库服务Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// 进度保存服务Provider
final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
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
  final DateTime? quizCompletedTime; // 答题完成时间
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
    this.quizCompletedTime,
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
    DateTime? quizCompletedTime,
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
      quizCompletedTime: quizCompletedTime ?? this.quizCompletedTime,
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
  final ProgressService _progressService;

  QuizController(this._databaseService, this._progressService)
    : super(const QuizState());

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

    // 自动保存进度（练习模式）
    _autoSaveProgress();
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
      // 答题完成，记录完成时间并清除保存的进度
      state = state.copyWith(
        status: QuizStatus.completed,
        quizCompletedTime: DateTime.now(),
      );
      if (state.mode == QuizMode.practice) {
        clearSavedProgress();
      }
    } else {
      // 进入下一题
      final newStartTimes = Map<int, DateTime>.from(state.questionStartTimes);
      newStartTimes[nextIndex] = DateTime.now();

      state = state.copyWith(
        currentQuestionIndex: nextIndex,
        questionStartTimes: newStartTimes,
      );

      // 自动保存进度（练习模式）
      _autoSaveProgress();
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
    // 使用完成时间，如果没有则使用当前时间（兼容性处理）
    final completedTime = state.quizCompletedTime ?? DateTime.now();

    for (int i = 0; i < state.questions.length; i++) {
      final question = state.questions[i];
      final userAnswer = state.userAnswers[i];
      final isCorrect = question.isAnswerCorrect(userAnswer);

      // 计算答题时间 - 使用固定的完成时间
      final startTime = state.questionStartTimes[i] ?? completedTime;
      Duration timeSpent;

      if (i < state.questions.length - 1) {
        // 非最后一题：使用下一题的开始时间
        final nextStartTime = state.questionStartTimes[i + 1] ?? completedTime;
        timeSpent = nextStartTime.difference(startTime);
      } else {
        // 最后一题：使用完成时间
        timeSpent = completedTime.difference(startTime);
      }

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

    // 计算总答题用时 - 使用固定的完成时间
    final totalTimeSpent = state.quizStartTime != null
        ? completedTime.difference(state.quizStartTime!)
        : Duration.zero;

    return QuizResult(
      totalQuestions: state.questions.length,
      correctAnswers: correctCount,
      questionResults: questionResults,
      completedAt: completedTime,
      totalTimeSpent: totalTimeSpent,
    );
  }

  // 重置答题状态
  void reset() {
    state = const QuizState();
  }

  // 自动保存当前进度（仅练习模式）
  Future<void> _autoSaveProgress() async {
    if (state.mode == QuizMode.practice &&
        state.status == QuizStatus.inProgress) {
      final progress = QuizProgress.fromQuizState(state);
      await _progressService.saveQuizProgress(progress);
    }
  }

  // 恢复进度
  Future<bool> restoreProgress() async {
    final progress = await _progressService.loadQuizProgress();
    if (progress != null && progress.isValid) {
      state = QuizState(
        status: QuizStatus.inProgress,
        mode: progress.mode!,
        questions: progress.questions,
        currentQuestionIndex: progress.currentIndex,
        userAnswers: progress.userAnswers,
        questionStartTimes: progress.questionStartTimes,
        quizStartTime: progress.startTime,
        selectedCategory: progress.selectedCategory,
      );
      return true;
    }
    return false;
  }

  // 清除保存的进度
  Future<void> clearSavedProgress() async {
    await _progressService.clearQuizProgress();
  }

  // 检查是否有保存的进度
  Future<bool> hasSavedProgress() async {
    return await _progressService.hasQuizProgress();
  }

  // 获取保存的进度描述
  Future<String?> getSavedProgressDescription() async {
    final progress = await _progressService.loadQuizProgress();
    return progress?.description;
  }
}

// 答题控制器Provider
final quizControllerProvider = StateNotifierProvider<QuizController, QuizState>(
  (ref) {
    final databaseService = ref.read(databaseServiceProvider);
    final progressService = ref.read(progressServiceProvider);
    return QuizController(databaseService, progressService);
  },
);
