import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';

class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  dynamic currentAnswer;
  Set<String> multipleAnswers = {};
  late PageController _pageController;
  late ScrollController _questionCardScrollController;
  Timer? _autoNextTimer;
  Timer? _countdownTimer;
  Timer? _multipleChoiceCheckTimer;
  bool _isAutoSwitching = false;
  bool _showingWrongAnswer = false; // 用于跟踪是否正在显示错误答案
  bool _showingCorrectAnswer = false; // 用于跟踪是否正在显示正确答案
  bool _showingHintAnswer = false; // 用于跟踪是否正在显示提示答案

  // 用于跟踪上一次的题目状态，以便检测选项是否发生变化
  List<QuestionModel>? _previousQuestions;

  // 倒计时相关
  int _totalTimeInSeconds = 15 * 60; // 默认15分钟，将从设置中读取
  int _remainingTimeInSeconds = 15 * 60;

  // 动画参数常量
  static const Duration _buttonSwitchDuration = Duration(milliseconds: 250);
  static const Duration _autoSwitchDuration = Duration(milliseconds: 300);
  static const Duration _cardJumpDuration = Duration(milliseconds: 300);
  static const Curve _smoothCurve = Curves.easeInOutCubic;
  static const Curve _autoSwitchCurve = Curves.easeOutQuart;

  // UI样式常量
  static const double _optionCardRadius = 12.0;
  static const double _buttonRadius = 10.0;
  static const EdgeInsets _optionPadding = EdgeInsets.symmetric(
    horizontal: 2,
    vertical: 2,
  );
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 20,
  );

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0, // 确保每页占满整个视口
    );
    _questionCardScrollController = ScrollController();
    // 只在考试模式下启动倒计时器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(quizControllerProvider);
      if (state.mode == QuizMode.exam) {
        _initializeExamTimer();
      }
    });
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    _countdownTimer?.cancel();
    _multipleChoiceCheckTimer?.cancel();
    _pageController.dispose();
    _questionCardScrollController.dispose();
    super.dispose();
  }

  // 初始化考试计时器
  void _initializeExamTimer() async {
    final settings = ref.read(settingsProvider);
    _totalTimeInSeconds = settings.examTimeMinutes * 60;
    _remainingTimeInSeconds = _totalTimeInSeconds;
    _startCountdownTimer();
  }

  // 启动倒计时器
  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTimeInSeconds > 0) {
            _remainingTimeInSeconds--;
          } else {
            // 时间到，自动结束答题
            timer.cancel();
            _handleTimeUp();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  // 处理时间到的情况
  void _handleTimeUp() {
    _countdownTimer?.cancel(); // 确保倒计时器被停止
    final controller = ref.read(quizControllerProvider.notifier);
    controller.nextQuestion(); // 强制结束答题，进入结果页面
  }

  // 显示提示答案
  void _showHintAnswer(QuizState state) {
    if (state.mode == QuizMode.practice && state.questions.isNotEmpty) {
      setState(() {
        _showingHintAnswer = true;
      });
    }
  }

  // 隐藏提示答案
  void _hideHintAnswer() {
    setState(() {
      _showingHintAnswer = false;
    });
  }

  // 检查选项是否为正确答案
  bool _isCorrectAnswer(String option) {
    final quizState = ref.read(quizControllerProvider);
    if (quizState.questions.isEmpty) return false;

    final currentQuestion = quizState.questions[quizState.currentQuestionIndex];
    final correctAnswer = currentQuestion.answer;

    if (currentQuestion.type == QuestionType.multiple) {
      // 多选题：检查选项是否在正确答案列表中
      if (correctAnswer is List) {
        return correctAnswer.contains(option);
      }
    } else {
      // 单选题和判断题：直接比较
      return correctAnswer == option;
    }

    return false;
  }

  // 格式化时间显示
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 处理练习模式的答案判断
  void _handlePracticeModeAnswer(QuizController controller) {
    final isCorrect = controller.isCurrentAnswerCorrect();

    if (isCorrect) {
      // 答案正确，显示绿色高亮状态
      setState(() {
        _showingCorrectAnswer = true;
      });

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('回答正确！'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // 延迟1秒后切换到下一题，让用户看到绿色高亮
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {
            _showingCorrectAnswer = false;
          });
          _goToNextQuestion(controller, ref.read(quizControllerProvider));
        }
      });
    } else {
      // 答案错误，显示错误状态
      setState(() {
        _showingWrongAnswer = true;
      });

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('回答错误，请重新选择'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // 延迟重置答案，让用户看到错误选项的高亮显示
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          // 重置当前答案
          controller.resetCurrentAnswer();
          setState(() {
            currentAnswer = null;
            multipleAnswers.clear();
            _showingWrongAnswer = false;
          });
        }
      });
    }
  }

  // 安排多选题的延迟检查（给用户时间选择多个选项）
  void _scheduleMultipleChoiceCheck(QuizController controller) {
    // 取消之前的检查定时器
    _multipleChoiceCheckTimer?.cancel();

    // 设置1.2秒后检查答案
    _multipleChoiceCheckTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _handlePracticeModeAnswer(controller);
      }
    });
  }

  // 安排考试模式下多选题的延迟切题（给用户时间选择多个选项）
  void _scheduleExamModeMultipleChoiceAutoNext(QuizController controller) {
    // 取消之前的检查定时器
    _multipleChoiceCheckTimer?.cancel();

    final settings = ref.read(settingsProvider);
    final quizState = ref.read(quizControllerProvider);

    // 检查是否需要自动切题
    if (settings.autoNextQuestion && !quizState.isLastQuestion) {
      setState(() {
        _isAutoSwitching = true;
      });

      // 设置1.2秒后自动切换到下一题
      _multipleChoiceCheckTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted && !quizState.isLastQuestion) {
          _autoSwitchToNext(controller);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    return PopScope(
      canPop: false, // 禁止直接返回
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackPressed(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(quizState.mode == QuizMode.practice ? '理论练习' : '理论模拟'),
          // 使用新的MD3主题，移除自定义背景色
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackPressed(context),
          ),
        ),
        body: SafeArea(
          bottom: false, // 底部不需要安全区域
          child: _buildBody(quizState, quizController),
        ),
      ),
    );
  }

  Widget _buildBody(QuizState state, QuizController controller) {
    switch (state.status) {
      case QuizStatus.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('正在加载题目...'),
            ],
          ),
        );

      case QuizStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 14),
              Text(state.errorMessage ?? '加载失败'),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: () => appRouter.goToHome(),
                child: const Text('返回首页'),
              ),
            ],
          ),
        );

      case QuizStatus.inProgress:
        return _buildQuizContent(state, controller);

      case QuizStatus.completed:
        // 答题完成，停止倒计时器并导航到结果页
        _countdownTimer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appRouter.goToResult();
        });
        return const Center(child: CircularProgressIndicator());

      default:
        return const Center(child: Text('初始化中...'));
    }
  }

  Widget _buildQuizContent(QuizState state, QuizController controller) {
    if (state.questions.isEmpty) return const Center(child: Text('没有题目'));

    // 检测题目是否发生变化（选项重新洗牌）
    if (_previousQuestions != null &&
        _previousQuestions!.length == state.questions.length) {
      final currentIndex = state.currentQuestionIndex;
      if (currentIndex < _previousQuestions!.length &&
          currentIndex < state.questions.length) {
        final previousQuestion = _previousQuestions![currentIndex];
        final currentQuestion = state.questions[currentIndex];

        // 检查选项是否发生变化
        if (previousQuestion.question == currentQuestion.question &&
            !_areOptionsEqual(
              previousQuestion.options,
              currentQuestion.options,
            )) {
          // 选项发生了变化，需要更新本地答案状态
          _updateAnswerStateAfterShuffle(
            previousQuestion,
            currentQuestion,
            state,
          );
        }
      }
    }

    // 更新题目状态记录
    _previousQuestions = List.from(state.questions);

    // 确保PageController与当前题目索引同步
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients &&
          _pageController.page?.round() != state.currentQuestionIndex) {
        _pageController.animateToPage(
          state.currentQuestionIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });

    return Column(
      children: [
        // 进度条
        _buildProgressBar(state),

        // 题目内容 - 使用PageView实现滑动切换
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: state.questions.length,
            physics: const BouncingScrollPhysics(), // 使用弹性滚动物理效果
            onPageChanged: (index) {
              // 滑动切换题目时更新状态
              controller.goToQuestion(index);
              // 取消自动切题状态和错误状态
              setState(() {
                _isAutoSwitching = false;
                _showingWrongAnswer = false;
                _showingCorrectAnswer = false;
              });
            },
            itemBuilder: (context, index) {
              final question = state.questions[index];
              return _buildQuestionPage(index, question, state, controller);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionPage(
    int index,
    QuestionModel question,
    QuizState state,
    QuizController controller,
  ) {
    // 恢复当前题目的答案状态
    _restoreAnswerState(index, question, state);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (_) => _showHintAnswer(state),
        onLongPressEnd: (_) => _hideHintAnswer(),
        child: Padding(
          key: ValueKey(index), // 确保AnimatedSwitcher能正确识别不同的题目
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 题目编号和题干
              _buildQuestionHeader(state, question, index),

              const SizedBox(height: 24),

              // 选项
              Expanded(child: _buildOptions(question, controller)),

              // 导航按钮
              _buildNavigationButtons(state, controller),
            ],
          ),
        ),
      ),
    );
  }

  void _restoreAnswerState(int index, QuestionModel question, QuizState state) {
    if (state.userAnswers.containsKey(index)) {
      final savedAnswer = state.userAnswers[index];
      if (question.type == QuestionType.multiple) {
        // 安全地处理多选题答案，支持List<dynamic>到List<String>的转换
        if (savedAnswer is List) {
          multipleAnswers = Set<String>.from(
            savedAnswer.map((e) => e.toString()),
          );
        } else {
          multipleAnswers.clear();
        }
      } else {
        currentAnswer = savedAnswer;
      }
    } else {
      currentAnswer = null;
      multipleAnswers.clear();
    }
  }

  Widget _buildProgressBar(QuizState state) {
    // 获取当前题目信息用于显示题型和题号
    final currentQuestion = state.questions.isNotEmpty
        ? state.questions[state.currentQuestionIndex]
        : null;
    String typeText = '';
    Color typeColor = Theme.of(context).colorScheme.primary;

    if (currentQuestion != null) {
      switch (currentQuestion.type) {
        case QuestionType.single:
          typeText = '单选题';
          typeColor = Theme.of(context).colorScheme.primary;
          break;
        case QuestionType.multiple:
          typeText = '多选题';
          typeColor = Theme.of(context).colorScheme.secondary;
          break;
        case QuestionType.boolean:
          typeText = '判断题';
          typeColor = Theme.of(context).colorScheme.tertiary;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: GestureDetector(
        onTap: () => _showQuestionCard(context, state),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: _isAutoSwitching
                ? Border.all(color: Colors.green.shade400, width: 2)
                : Border.all(
                    color: Colors.grey.withValues(alpha: 0.15),
                    width: 1,
                  ),
            boxShadow: [
              BoxShadow(
                color: _isAutoSwitching
                    ? Colors.green.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.08),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _isAutoSwitching ? Icons.fast_forward : Icons.quiz,
                    size: 20,
                    color: _isAutoSwitching ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAutoSwitching ? '切题中' : '答题卡',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isAutoSwitching ? Colors.green : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 题型标签
                  if (currentQuestion != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        typeText,
                        style: TextStyle(
                          fontSize: 10,
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 题号标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '第${state.currentQuestionIndex + 1}题',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  // 倒计时显示 - 只在考试模式下显示
                  if (state.mode == QuizMode.exam) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _remainingTimeInSeconds <=
                                300 // 最后5分钟显示红色警告
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _remainingTimeInSeconds <= 300
                              ? Colors.red.withValues(alpha: 0.3)
                              : Colors.blue.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 10,
                            color: _remainingTimeInSeconds <= 300
                                ? Colors.red
                                : Colors.blue,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(_remainingTimeInSeconds),
                            style: TextStyle(
                              fontSize: 10,
                              color: _remainingTimeInSeconds <= 300
                                  ? Colors.red
                                  : Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                duration: _isAutoSwitching
                    ? _autoSwitchDuration
                    : _buttonSwitchDuration,
                curve: _isAutoSwitching ? _autoSwitchCurve : _smoothCurve,
                tween: Tween<double>(
                  begin: 0,
                  end:
                      (state.currentQuestionIndex + 1) / state.questions.length,
                ),
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isAutoSwitching
                          ? Colors.green
                          : _getProgressColor(
                              state.answeredCount / state.questions.length,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.5) return Colors.orange;
    return Colors.blue;
  }

  // 获取主题相关的颜色
  Color _getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color _getOptionBackgroundColor(
    BuildContext context,
    bool isSelected,
    bool isAutoSwitching, {
    bool isWrongAnswer = false,
    bool isCorrectAnswer = false,
    bool isHintAnswer = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isCorrectAnswer && isSelected) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (isWrongAnswer && isSelected) {
      return Theme.of(context).colorScheme.errorContainer;
    }
    if (isHintAnswer) {
      return Colors.orange.withValues(alpha: 0.2);
    }
    if (isAutoSwitching) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (isSelected) {
      // 在深色模式下使用更明显的背景色，确保文字可见
      return isDarkMode
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.2);
    }
    return Theme.of(context).cardColor;
  }

  Color _getOptionBorderColor(
    BuildContext context,
    bool isSelected,
    bool isAutoSwitching, {
    bool isWrongAnswer = false,
    bool isCorrectAnswer = false,
    bool isHintAnswer = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isCorrectAnswer && isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    if (isWrongAnswer && isSelected) {
      return Theme.of(context).colorScheme.error;
    }
    if (isHintAnswer) {
      return Colors.orange;
    }
    if (isAutoSwitching) {
      return Theme.of(context).colorScheme.primary;
    }
    if (isSelected) {
      // 在深色模式下使用更明显的边框
      return isDarkMode
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.4);
    }
    return Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
  }

  Color _getOptionTextColor(
    BuildContext context,
    bool isSelected,
    bool isAutoSwitching, {
    bool isWrongAnswer = false,
    bool isCorrectAnswer = false,
    bool isHintAnswer = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isCorrectAnswer && isSelected) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    if (isWrongAnswer && isSelected) {
      return Theme.of(context).colorScheme.onErrorContainer;
    }
    if (isHintAnswer) {
      return Colors.orange.shade800;
    }
    if (isAutoSwitching) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    if (isSelected) {
      // 在深色模式下确保文字有足够的对比度
      return isDarkMode
          ? Theme.of(context).colorScheme.onSurface
          : Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  Widget _buildQuestionHeader(
    QuizState state,
    QuestionModel question, [
    int? questionIndex,
  ]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        question.question,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildOptions(QuestionModel question, QuizController controller) {
    return ListView.builder(
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];

        switch (question.type) {
          case QuestionType.single:
          case QuestionType.boolean:
            return _buildSingleChoiceOption(option, controller);

          case QuestionType.multiple:
            return _buildMultipleChoiceOption(option, controller);
        }
      },
    );
  }

  Widget _buildSingleChoiceOption(String option, QuizController controller) {
    final isSelected = currentAnswer == option;
    final isAutoSwitching = isSelected && _isAutoSwitching;
    final isWrongAnswer = _showingWrongAnswer && isSelected;
    final isCorrectAnswer = _showingCorrectAnswer && isSelected;
    final isHintAnswer = _showingHintAnswer && _isCorrectAnswer(option);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: isSelected ? 3 : 1,
        borderRadius: BorderRadius.circular(_optionCardRadius),
        shadowColor: isCorrectAnswer
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
            : isWrongAnswer
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.3)
            : isHintAnswer
            ? Colors.orange.withValues(alpha: 0.4)
            : isAutoSwitching
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _getOptionBackgroundColor(
              context,
              isSelected,
              isAutoSwitching,
              isWrongAnswer: isWrongAnswer,
              isCorrectAnswer: isCorrectAnswer,
              isHintAnswer: isHintAnswer,
            ),
            borderRadius: BorderRadius.circular(_optionCardRadius),
            border: Border.all(
              color: _getOptionBorderColor(
                context,
                isSelected,
                isAutoSwitching,
                isWrongAnswer: isWrongAnswer,
                isCorrectAnswer: isCorrectAnswer,
                isHintAnswer: isHintAnswer,
              ),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            contentPadding: _optionPadding,
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _getOptionTextColor(
                  context,
                  isSelected,
                  isAutoSwitching,
                  isWrongAnswer: isWrongAnswer,
                  isCorrectAnswer: isCorrectAnswer,
                  isHintAnswer: isHintAnswer,
                ),
                fontSize: 18,
                height: 1.4,
              ),
              child: Text(option),
            ),
            value: option,
            groupValue: currentAnswer,
            onChanged: (value) {
              _handleSingleChoiceSelection(value, controller);
            },
            activeColor: isCorrectAnswer
                ? Colors.green.shade700
                : isWrongAnswer
                ? Colors.red.shade600
                : isHintAnswer
                ? Colors.orange.shade600
                : isAutoSwitching
                ? Colors.green.shade600
                : _getPrimaryColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_optionCardRadius),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSingleChoiceSelection(String? value, QuizController controller) {
    if (value == null) return;

    // 取消之前的自动切题定时器
    _autoNextTimer?.cancel();

    setState(() {
      currentAnswer = value;
      _isAutoSwitching = false;
    });

    // 提交答案
    controller.submitAnswer(value);

    final settings = ref.read(settingsProvider);
    final quizState = ref.read(quizControllerProvider);

    // 练习模式：立即判断对错
    if (quizState.mode == QuizMode.practice) {
      _handlePracticeModeAnswer(controller);
      return;
    }

    // 考试模式：检查是否需要自动切题

    if (settings.autoNextQuestion && !quizState.isLastQuestion) {
      setState(() {
        _isAutoSwitching = true;
      });

      // 延迟0.6秒后自动切换到下一题
      _autoNextTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !quizState.isLastQuestion) {
          _autoSwitchToNext(controller);
        }
      });
    }
  }

  Widget _buildMultipleChoiceOption(String option, QuizController controller) {
    final isSelected = multipleAnswers.contains(option);
    final isWrongAnswer = _showingWrongAnswer && isSelected;
    final isCorrectAnswer = _showingCorrectAnswer && isSelected;
    final isHintAnswer = _showingHintAnswer && _isCorrectAnswer(option);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: isSelected ? 2.5 : 1,
        borderRadius: BorderRadius.circular(_optionCardRadius),
        shadowColor: isCorrectAnswer
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
            : isWrongAnswer
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.25)
            : isHintAnswer
            ? Colors.orange.withValues(alpha: 0.3)
            : isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
            : Theme.of(context).colorScheme.shadow.withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _getOptionBackgroundColor(
              context,
              isSelected,
              false,
              isWrongAnswer: isWrongAnswer,
              isCorrectAnswer: isCorrectAnswer,
              isHintAnswer: isHintAnswer,
            ),
            borderRadius: BorderRadius.circular(_optionCardRadius),
            border: Border.all(
              color: _getOptionBorderColor(
                context,
                isSelected,
                false,
                isWrongAnswer: isWrongAnswer,
                isCorrectAnswer: isCorrectAnswer,
                isHintAnswer: isHintAnswer,
              ),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            contentPadding: _optionPadding,
            controlAffinity: ListTileControlAffinity.leading,
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: _getOptionTextColor(
                  context,
                  isSelected,
                  false,
                  isWrongAnswer: isWrongAnswer,
                  isCorrectAnswer: isCorrectAnswer,
                  isHintAnswer: isHintAnswer,
                ),
                fontSize: 16,
                height: 1.4,
              ),
              child: Text(option),
            ),
            value: isSelected,
            onChanged: (value) {
              // 取消自动切题定时器
              _autoNextTimer?.cancel();
              setState(() {
                _isAutoSwitching = false;
                if (value == true) {
                  multipleAnswers.add(option);
                } else {
                  multipleAnswers.remove(option);
                }
              });
              controller.submitAnswer(multipleAnswers.toList());

              // 根据模式处理延迟逻辑
              final quizState = ref.read(quizControllerProvider);
              if (quizState.mode == QuizMode.practice) {
                // 练习模式下，延迟判断答案（给用户时间选择多个选项）
                _scheduleMultipleChoiceCheck(controller);
              } else if (quizState.mode == QuizMode.exam) {
                // 考试模式下，延迟自动切题（给用户时间选择多个选项）
                _scheduleExamModeMultipleChoiceAutoNext(controller);
              }
            },
            activeColor: isCorrectAnswer
                ? Colors.green.shade700
                : isWrongAnswer
                ? Colors.red.shade600
                : isHintAnswer
                ? Colors.orange.shade600
                : _getPrimaryColor(context),
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_optionCardRadius),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(QuizState state, QuizController controller) {
    final settings = ref.watch(settingsProvider);
    final isAutoNextMode = settings.autoNextQuestion;

    return Container(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          // 在快速切题模式下隐藏上一题按钮
          if (!isAutoNextMode && state.currentQuestionIndex > 0)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: OutlinedButton(
                  onPressed: () => _goToPreviousQuestion(controller),
                  style: OutlinedButton.styleFrom(
                    padding: _buttonPadding,
                    side: BorderSide(
                      color: _getPrimaryColor(context).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_buttonRadius),
                    ),
                    foregroundColor: _getPrimaryColor(context),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_ios, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '上一题',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!isAutoNextMode && state.currentQuestionIndex > 0)
            const SizedBox(width: 16),

          // 在快速切题模式下，只显示最后一题的完成按钮，或者非快速切题模式下显示下一题/完成按钮
          if (!isAutoNextMode || state.isLastQuestion)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: ElevatedButton(
                  onPressed: () {
                    if (isAutoNextMode && state.isLastQuestion) {
                      // 快速切题模式下的结束答题
                      _countdownTimer?.cancel(); // 停止倒计时器
                      controller.nextQuestion();
                    } else {
                      // 正常模式下的下一题/完成答题
                      _goToNextQuestion(controller, state);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: _buttonPadding,
                    backgroundColor:
                        (isAutoNextMode && state.isLastQuestion) ||
                            state.isLastQuestion
                        ? Colors.green.shade600
                        : _getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor:
                        (isAutoNextMode && state.isLastQuestion) ||
                            state.isLastQuestion
                        ? Colors.green.withValues(alpha: 0.3)
                        : _getPrimaryColor(context).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_buttonRadius),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Row(
                      key: ValueKey(
                        '${isAutoNextMode}_${state.isLastQuestion}',
                      ),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (isAutoNextMode && state.isLastQuestion) ||
                                  state.isLastQuestion
                              ? '结束答题'
                              : '下一题',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          (isAutoNextMode && state.isLastQuestion) ||
                                  state.isLastQuestion
                              ? Icons.check_circle
                              : Icons.arrow_forward_ios,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToPreviousQuestion(QuizController controller) {
    // 取消自动切题
    _autoNextTimer?.cancel();
    setState(() {
      _isAutoSwitching = false;
    });

    if (_pageController.hasClients) {
      _pageController.previousPage(
        duration: _buttonSwitchDuration,
        curve: _smoothCurve,
      );
    } else {
      controller.previousQuestion();
    }
  }

  void _goToNextQuestion(QuizController controller, QuizState state) {
    // 取消自动切题
    _autoNextTimer?.cancel();
    setState(() {
      _isAutoSwitching = false;
      _showingWrongAnswer = false; // 重置错误状态
      _showingCorrectAnswer = false; // 重置正确状态
    });

    if (_pageController.hasClients) {
      if (state.isLastQuestion) {
        _countdownTimer?.cancel(); // 停止倒计时器
        controller.nextQuestion(); // 完成答题
      } else {
        _pageController.nextPage(
          duration: _buttonSwitchDuration,
          curve: _smoothCurve,
        );
      }
    } else {
      if (state.isLastQuestion) {
        _countdownTimer?.cancel(); // 停止倒计时器
      }
      controller.nextQuestion();
    }
  }

  // 专门用于自动切题的方法，使用更平滑的动画
  void _autoSwitchToNext(QuizController controller) {
    setState(() {
      _isAutoSwitching = false; // 动画开始时重置状态
    });

    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: _autoSwitchDuration,
        curve: _autoSwitchCurve,
      );
    } else {
      controller.nextQuestion();
    }
  }

  void _goToQuestionByIndex(int index, QuizController controller) {
    // 取消自动切题
    _autoNextTimer?.cancel();
    setState(() {
      _isAutoSwitching = false;
      _showingWrongAnswer = false; // 重置错误状态
      _showingCorrectAnswer = false; // 重置正确状态
    });

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: _cardJumpDuration,
        curve: _smoothCurve,
      );
    } else {
      controller.goToQuestion(index);
    }
  }

  void _showQuestionCard(BuildContext context, QuizState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuestionCard(state),
    );

    // 答题卡展开时，延迟滚动到当前题目位置
    // 使用更长的延迟确保答题卡完全展开后再滚动
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scrollToCurrentQuestion(state.currentQuestionIndex);
      }
    });
  }

  // 滚动到指定题目位置
  void _scrollToCurrentQuestion(int currentIndex) {
    if (!_questionCardScrollController.hasClients) return;

    // 计算网格参数（与GridView.builder中的参数保持一致）
    const int crossAxisCount = 5; // 每行5个题目
    const double crossAxisSpacing = 12.0; // 横轴间距
    const double mainAxisSpacing = 12.0; // 主轴间距
    const double childAspectRatio = 1.0; // 宽高比
    const double padding = 16.0; // 容器内边距

    // 计算当前题目所在的行
    final int row = currentIndex ~/ crossAxisCount;

    // 获取GridView的可用宽度
    final double availableWidth =
        MediaQuery.of(context).size.width - (padding * 2);

    // 计算每个item的实际尺寸
    final double itemWidth =
        (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
        crossAxisCount;
    final double itemHeight = itemWidth / childAspectRatio;

    // 计算目标滚动位置，让当前题目所在行居中显示
    final double targetOffset =
        (row * (itemHeight + mainAxisSpacing)) - (itemHeight + mainAxisSpacing);

    // 确保滚动位置在有效范围内
    final double maxScrollExtent =
        _questionCardScrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

    // 执行滚动动画
    _questionCardScrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildQuestionCard(QuizState state) {
    final controller = ref.read(quizControllerProvider.notifier);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 顶部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                const Text(
                  '答题卡',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${state.answeredCount}/${state.questions.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 题目网格
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                controller: _questionCardScrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: state.questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionItem(index, state, controller);
                },
              ),
            ),
          ),

          // 底部统计信息
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '已答',
                  state.answeredCount,
                  Theme.of(context).colorScheme.primary,
                ),
                _buildStatItem(
                  '未答',
                  state.questions.length - state.answeredCount,
                  Theme.of(context).colorScheme.outline,
                ),
                _buildStatItem(
                  '当前',
                  state.currentQuestionIndex + 1,
                  Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(
    int index,
    QuizState state,
    QuizController controller,
  ) {
    final isAnswered = state.userAnswers.containsKey(index);
    final isCurrent = index == state.currentQuestionIndex;

    Color backgroundColor;
    Color textColor;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isCurrent) {
      backgroundColor = Theme.of(context).colorScheme.secondary;
      textColor = Theme.of(context).colorScheme.onSecondary;
    } else if (isAnswered) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else {
      // 未答题的按钮在深色模式下使用更明显的对比色
      backgroundColor = isDarkMode
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surfaceContainer;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return GestureDetector(
      onTap: () {
        _goToQuestionByIndex(index, controller);
        Navigator.of(context).pop(); // 关闭答题卡
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent
              ? Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _handleBackPressed(BuildContext context) {
    final quizState = ref.read(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);
    final settings = ref.read(settingsProvider);

    // 检查是否启用进度保存
    if (settings.enableProgressSave) {
      // 启用进度保存：根据默认继续进度设置决定是否显示对话框
      if (settings.enableDefaultContinueProgress) {
        // 默认继续进度：自动保存并退出
        _saveProgressAndExit(quizController);
      } else {
        // 显示保存进度确认对话框
        _showSaveProgressDialog(context, quizController);
      }
    } else {
      // 未启用进度保存：根据模式决定处理方式
      if (quizState.mode == QuizMode.practice) {
        // 练习模式：直接退出
        quizController.reset();
        appRouter.goToHome();
      } else {
        // 考试模式：显示确认对话框
        _showExitDialog(context);
      }
    }
  }

  // 保存进度并退出
  Future<void> _saveProgressAndExit(QuizController quizController) async {
    await quizController.saveCurrentProgress();
    quizController.reset();
    appRouter.goToHome();
  }

  // 显示保存进度确认对话框
  void _showSaveProgressDialog(
    BuildContext context,
    QuizController quizController,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存进度'),
        content: const Text('是否保存当前答题进度？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 不保存进度，直接退出
              quizController.reset();
              appRouter.goToHome();
            },
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 保存进度并退出
              _saveProgressAndExit(quizController);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出答题吗？当前进度将会丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(quizControllerProvider.notifier).reset();
              appRouter.goToHome();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 检查两个选项列表是否相等
  bool _areOptionsEqual(List<String> options1, List<String> options2) {
    if (options1.length != options2.length) return false;
    for (int i = 0; i < options1.length; i++) {
      if (options1[i] != options2[i]) return false;
    }
    return true;
  }

  // 在选项重新洗牌后更新本地答案状态
  void _updateAnswerStateAfterShuffle(
    QuestionModel previousQuestion,
    QuestionModel currentQuestion,
    QuizState state,
  ) {
    final currentIndex = state.currentQuestionIndex;
    final userAnswer = state.userAnswers[currentIndex];

    if (userAnswer == null) {
      // 没有用户答案，清空本地状态
      setState(() {
        currentAnswer = null;
        multipleAnswers.clear();
      });
      return;
    }

    if (currentQuestion.type == QuestionType.multiple) {
      // 多选题：更新 multipleAnswers
      if (userAnswer is List) {
        final validAnswers = userAnswer
            .where(
              (answer) => currentQuestion.options.contains(answer.toString()),
            )
            .map((answer) => answer.toString())
            .toSet();
        setState(() {
          multipleAnswers = validAnswers;
          currentAnswer = null;
        });
      } else {
        setState(() {
          multipleAnswers.clear();
          currentAnswer = null;
        });
      }
    } else {
      // 单选题和判断题：更新 currentAnswer
      if (currentQuestion.options.contains(userAnswer.toString())) {
        setState(() {
          currentAnswer = userAnswer;
          multipleAnswers.clear();
        });
      } else {
        setState(() {
          currentAnswer = null;
          multipleAnswers.clear();
        });
      }
    }
  }
}
