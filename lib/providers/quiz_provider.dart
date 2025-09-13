import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../models/progress_model.dart';
import '../models/settings_model.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';
import 'settings_provider.dart';

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
  final List<QuestionModel> originalQuestions; // 存储原始题目（未处理选项顺序）
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
    this.originalQuestions = const [], // 默认空列表
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
    List<QuestionModel>? originalQuestions,
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
      originalQuestions: originalQuestions ?? this.originalQuestions,
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
  final Ref _ref;

  QuizController(this._databaseService, this._progressService, this._ref)
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
        originalQuestions: questions, // 保存原始题目
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
      // 获取原始题目（不处理选项顺序）
      final originalQuestions = await _databaseService
          .getOriginalQuestionsBySettings(
            singleCount: singleCount,
            multipleCount: multipleCount,
            booleanCount: booleanCount,
          );

      if (originalQuestions.isEmpty) {
        state = state.copyWith(
          status: QuizStatus.error,
          errorMessage: '没有找到题目',
        );
        return;
      }

      // 根据设置处理选项顺序
      final questions = shuffleOptions
          ? originalQuestions.map((q) => q.shuffleOptions()).toList()
          : originalQuestions;

      final now = DateTime.now();
      state = state.copyWith(
        status: QuizStatus.inProgress,
        mode: QuizMode.exam, // 考试模式
        questions: questions,
        originalQuestions: originalQuestions, // 保存原始题目
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
  Future<void> startAllQuestionsQuiz({
    required bool shuffleOptions,
    required PracticeShuffleMode shuffleMode,
  }) async {
    state = state.copyWith(status: QuizStatus.loading);

    try {
      // 获取原始题目（不处理选项顺序）
      List<QuestionModel> originalQuestions = await _databaseService
          .getQuestionsForPractice(
            shuffleMode: shuffleMode,
            shuffleOptions: false, // 先不处理选项顺序
          );

      if (originalQuestions.isEmpty) {
        state = state.copyWith(
          status: QuizStatus.error,
          errorMessage: '没有找到题目',
        );
        return;
      }

      // 根据设置处理选项顺序
      final questions = shuffleOptions
          ? originalQuestions.map((q) => q.shuffleOptions()).toList()
          : originalQuestions;

      final now = DateTime.now();
      state = state.copyWith(
        status: QuizStatus.inProgress,
        mode: QuizMode.practice, // 练习模式
        questions: questions,
        originalQuestions: originalQuestions, // 保存原始题目
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
      // 答题完成时清除保存的进度
      clearSavedProgress();
    } else {
      // 进入下一题
      final newStartTimes = Map<int, DateTime>.from(state.questionStartTimes);
      newStartTimes[nextIndex] = DateTime.now();

      state = state.copyWith(
        currentQuestionIndex: nextIndex,
        questionStartTimes: newStartTimes,
      );

      // 自动保存进度（所有模式）
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

  // 自动保存当前进度（练习模式和考试模式）
  Future<void> _autoSaveProgress() async {
    if (state.status == QuizStatus.inProgress) {
      PracticeShuffleMode? practiceShuffleMode;
      if (state.mode == QuizMode.practice) {
        final settings = _ref.read(settingsProvider);
        practiceShuffleMode = settings.practiceShuffleMode;
      }
      final progress = QuizProgress.fromQuizState(
        state,
        practiceShuffleMode: practiceShuffleMode,
      );
      await _progressService.saveQuizProgress(progress);
    }
  }

  // 手动保存当前进度（用于退出时保存）
  Future<void> saveCurrentProgress() async {
    if (state.status == QuizStatus.inProgress) {
      PracticeShuffleMode? practiceShuffleMode;
      if (state.mode == QuizMode.practice) {
        final settings = _ref.read(settingsProvider);
        practiceShuffleMode = settings.practiceShuffleMode;
      }
      final progress = QuizProgress.fromQuizState(
        state,
        practiceShuffleMode: practiceShuffleMode,
      );
      await _progressService.saveQuizProgress(progress);
    }
  }

  // 恢复进度
  Future<bool> restoreProgress() async {
    final progress = await _progressService.loadQuizProgress();
    if (progress != null && progress.isValid && progress.mode != null) {
      // 检查练习模式乱序设置是否匹配
      if (progress.mode == QuizMode.practice &&
          progress.practiceShuffleMode != null) {
        final settings = _ref.read(settingsProvider);
        if (progress.practiceShuffleMode != settings.practiceShuffleMode) {
          // 设置不匹配，清除进度并返回false
          await clearSavedProgress();
          return false;
        }
      }

      state = QuizState(
        status: QuizStatus.inProgress,
        mode: progress.mode!,
        questions: progress.questions,
        originalQuestions: progress.questions, // 恢复时保存原始题目
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

  // 检查是否有指定模式的保存进度
  Future<bool> hasSavedProgressForMode(QuizMode mode) async {
    final progress = await _progressService.loadQuizProgress();
    if (progress != null && progress.isValid) {
      if (progress.mode == mode) {
        return true;
      } else {
        // 模式不匹配，清除进度
        await clearSavedProgress();
        return false;
      }
    }
    return false;
  }

  // 获取保存的进度描述
  Future<String?> getSavedProgressDescription() async {
    final progress = await _progressService.loadQuizProgress();
    return progress?.description;
  }

  // 更新选项乱序设置并重新处理题目选项
  void updateShuffleOptions(bool shuffleOptions) {
    if (state.status != QuizStatus.inProgress ||
        state.originalQuestions.isEmpty) {
      return; // 只在答题进行中且有原始题目时才处理
    }

    // 基于原始题目重新处理选项顺序
    List<QuestionModel> updatedQuestions;
    if (shuffleOptions) {
      // 开启乱序：对每个题目的选项进行洗牌
      updatedQuestions = state.originalQuestions
          .map((question) => question.shuffleOptions())
          .toList();
    } else {
      // 关闭乱序：使用原始选项顺序
      updatedQuestions = List.from(state.originalQuestions);
    }

    // 重新映射用户答案：基于答案内容而非索引位置
    final updatedUserAnswers = <int, dynamic>{};
    for (final entry in state.userAnswers.entries) {
      final questionIndex = entry.key;
      final userAnswer = entry.value;

      if (questionIndex < state.originalQuestions.length &&
          questionIndex < updatedQuestions.length) {
        final updatedQuestion = updatedQuestions[questionIndex];

        // 基于原始题目的正确答案来映射用户答案
        if (updatedQuestion.type == QuestionType.multiple) {
          // 多选题：保持用户选择的答案内容
          if (userAnswer is List) {
            final userAnswerStrings = userAnswer
                .map((e) => e.toString())
                .toList();
            // 检查用户答案是否仍在新的选项列表中
            final validAnswers = userAnswerStrings
                .where((answer) => updatedQuestion.options.contains(answer))
                .toList();
            if (validAnswers.isNotEmpty) {
              updatedUserAnswers[questionIndex] = validAnswers;
            }
          }
        } else {
          // 单选题和判断题：保持用户选择的答案内容
          if (userAnswer != null) {
            final userAnswerString = userAnswer.toString();
            // 检查用户答案是否仍在新的选项列表中
            if (updatedQuestion.options.contains(userAnswerString)) {
              updatedUserAnswers[questionIndex] = userAnswerString;
            }
          }
        }
      }
    }

    // 更新状态
    state = state.copyWith(
      questions: updatedQuestions,
      userAnswers: updatedUserAnswers,
    );
  }
}

// 答题控制器Provider
final quizControllerProvider = StateNotifierProvider<QuizController, QuizState>(
  (ref) {
    final databaseService = ref.read(databaseServiceProvider);
    final progressService = ref.read(progressServiceProvider);
    return QuizController(databaseService, progressService, ref);
  },
);
