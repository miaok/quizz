import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../router/app_router.dart';
import '../utils/memory_manager.dart';
import '../utils/haptic_manager.dart';
import '../widgets/answer_card.dart';

/// Quiz页面的答题卡项目实现
class QuizAnswerCardItem implements AnswerCardItem {
  final int index;
  final QuizState state;

  QuizAnswerCardItem(this.index, this.state);

  @override
  String get id => index.toString();

  @override
  int get displayNumber => index + 1;

  @override
  bool get isCurrent => index == state.currentQuestionIndex;

  @override
  bool get isCompleted => state.userAnswers.containsKey(index);

  @override
  bool get hasAnswer => isCompleted;
}

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

  // 防止频繁更新的标志
  bool _isUpdatingUI = false;
  DateTime? _lastUIUpdate;
  static const Duration _uiUpdateThrottle = Duration(milliseconds: 100);

  // 防快速点击相关
  bool _isProcessingAnswer = false; // 是否正在处理答案
  Timer? _optionLockTimer; // 选项锁定定时器
  static const Duration _optionLockDuration = Duration(
    milliseconds: 800,
  ); // 选项锁定时长

  // 进度卡片下沉动画标志
  bool _progressCardSinking = false;

  // 鼠标拖拽相关变量（仅在Windows平台使用）
  bool _isDragging = false;
  double? _dragStartX;
  static const double _dragThreshold = 50.0; // 拖拽阈值

  // 动画参数常量
  static const Duration _buttonSwitchDuration = Duration(milliseconds: 250);
  static const Duration _autoSwitchDuration = Duration(milliseconds: 300);
  static const Duration _cardJumpDuration = Duration(milliseconds: 300);
  static const Curve _smoothCurve = Curves.easeInOutCubic;
  static const Curve _autoSwitchCurve = Curves.easeOutQuart;

  // UI样式常量
  static const double _optionCardRadius = 12.0;
  static const double _buttonRadius = 10.0;
  static const double _optionButtonSize = 24.0; // 统一选项按钮大小
  static const EdgeInsets _optionPadding = EdgeInsets.symmetric(
    horizontal: 16, // 统一水平内边距
    vertical: 2, // 统一垂直内边距
  );
  static const EdgeInsets _buttonPadding = EdgeInsets.symmetric(
    vertical: 12,
    horizontal: 20,
  );

  // 按钮样式方法
  ButtonStyle _secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      );

  ButtonStyle _primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      );

  // ===== MD3 配色辅助方法 =====
  // 尽量靠近 Material 3 的表面/边框/阴影语义，增强层级对比
  // 移除未使用的方法（_md3Surface）

  Color _md3CardBackground(BuildContext context) {
    // 卡片采用更接近 cardColor 的表面容器色
    // 若主题未特别配置，cardColor 通常已与 M3 对齐
    return Theme.of(context).cardColor;
  }

  Color _md3SurfaceVariant(BuildContext context) {
    // 用于进度条背景、轻度分隔等
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Color _md3Outline(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  Color _md3OutlineSoft(BuildContext context) {
    // 更柔和的描边
    return _md3Outline(context).withValues(alpha: 0.18);
  }

  Color _md3Shadow(BuildContext context, {bool strong = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (strong) {
      return isDark
          ? Colors.black.withValues(alpha: 0.5)
          : Colors.black.withValues(alpha: 0.18);
    }
    return isDark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.10);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 1.0, // 确保每页占满整个视口
    );
    _questionCardScrollController = ScrollController();

    // 优化答题页面内存使用
    MemoryManager.optimizeForQuizPage();

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
    _optionLockTimer?.cancel();
    _pageController.dispose();
    _questionCardScrollController.dispose();

    // 页面销毁时进行内存清理
    MemoryManager.lightCleanup();

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
      if (mounted && !_isUpdatingUI) {
        // 防抖动机制，避免频繁更新UI
        final now = DateTime.now();
        if (_lastUIUpdate != null &&
            now.difference(_lastUIUpdate!) < _uiUpdateThrottle) {
          return;
        }

        _isUpdatingUI = true;
        _lastUIUpdate = now;

        setState(() {
          if (_remainingTimeInSeconds > 0) {
            _remainingTimeInSeconds--;
          } else {
            // 时间到，自动结束答题
            timer.cancel();
            _handleTimeUp();
          }
        });

        _isUpdatingUI = false;
      } else if (!mounted) {
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

  // 处理鼠标拖拽开始（仅在Windows平台使用）
  void _handleMouseDragStart(PointerDownEvent event) {
    if (Platform.isWindows && event.buttons == 1) {
      // 仅响应鼠标左键
      _isDragging = true;
      _dragStartX = event.position.dx;
    }
  }

  // 处理鼠标拖拽结束（仅在Windows平台使用）
  void _handleMouseDragEnd(PointerUpEvent event) {
    if (Platform.isWindows && _isDragging && _dragStartX != null) {
      final dragDistance = event.position.dx - _dragStartX!;
      final quizState = ref.read(quizControllerProvider);
      final controller = ref.read(quizControllerProvider.notifier);

      // 如果拖拽距离超过阈值，则切换题目
      if (dragDistance.abs() > _dragThreshold) {
        if (dragDistance > 0) {
          // 向右拖拽，切换到上一题
          if (quizState.currentQuestionIndex > 0) {
            _goToPreviousQuestion(controller);
          }
        } else {
          // 向左拖拽，切换到下一题
          if (!quizState.isLastQuestion) {
            _goToNextQuestion(controller, quizState);
          } else {
            // 最后一题，完成答题
            _countdownTimer?.cancel();
            controller.nextQuestion();
          }
        }
      }

      _isDragging = false;
      _dragStartX = null;
    }
  }

  // 处理鼠标拖拽取消（仅在Windows平台使用）
  void _handleMouseDragCancel(PointerCancelEvent event) {
    if (Platform.isWindows) {
      _isDragging = false;
      _dragStartX = null;
    }
  }

  // 显示提示答案
  void _showHintAnswer(QuizState state) {
    if (state.mode == QuizMode.practice && state.questions.isNotEmpty) {
      // 触发长按查看答案的震动反馈
      HapticManager.showHint();
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
    final quizState = ref.read(quizControllerProvider);
    final currentQuestion = quizState.questions[quizState.currentQuestionIndex];

    // 设置处理状态，防止快速点击
    setState(() {
      _isProcessingAnswer = true;
    });

    if (isCorrect) {
      // 答案正确，显示绿色高亮状态，触发轻快震动
      HapticManager.correctAnswer();

      final settings = ref.read(settingsProvider);

      setState(() {
        _showingCorrectAnswer = true;
        // 只有在开启自动切题且不是最后一题时，才显示切题动画
        if (settings.autoNextQuestion && !quizState.isLastQuestion) {
          _isAutoSwitching = true;
          _progressCardSinking = true; // 同步下沉动画开始
        }
      });

      // 检查是否开启了自动切题功能
      if (settings.autoNextQuestion && !quizState.isLastQuestion) {
        // 开启了自动切题：延迟800毫秒后切换到下一题，让用户看到绿色高亮
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            // 确保在切题前最后一次保存正确答案
            final currentIndex = ref
                .read(quizControllerProvider)
                .currentQuestionIndex;
            final currentAnswer = ref
                .read(quizControllerProvider)
                .userAnswers[currentIndex];
            if (currentAnswer != null) {
              // 再次确认答案已保存
              controller.submitAnswer(currentAnswer);
            }

            setState(() {
              _showingCorrectAnswer = false;
              _isAutoSwitching = false;
              _progressCardSinking = false; // 同步结束下沉动画
              _isProcessingAnswer = false; // 重置处理状态
            });
            HapticManager.switchQuestion();
            _goToNextQuestion(controller, ref.read(quizControllerProvider));
          }
        });
      } else {
        // 未开启自动切题：只显示正确答案高亮，然后重置状态让用户手动切题
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _showingCorrectAnswer = false;
              _isProcessingAnswer = false; // 重置处理状态，允许用户手动切题
            });
          }
        });
      }
    } else {
      // 答案错误，显示错误状态，触发稍强震动
      HapticManager.wrongAnswer();
      setState(() {
        _showingWrongAnswer = true;
        // 保持 _isProcessingAnswer = true，禁止用户在变色期间点击其他选项
      });

      // 根据题目类型确定延迟时间：多选题使用更长时间让用户看清楚错误，单选题使用较长时间让用户看清楚
      final resetDelay = currentQuestion.type == QuestionType.multiple
          ? const Duration(milliseconds: 700) // 多选题：延长变色时间让用户看清楚错误
          : const Duration(milliseconds: 600); // 单选题：延迟重置让用户看到错误选项

      // 延迟重置答案，让用户看到错误选项的高亮显示
      Future.delayed(resetDelay, () {
        if (mounted) {
          // 重置当前答案
          final settings = ref.read(settingsProvider);
          if (settings.enableSecondShuffle) {
            // 如果开启了二次乱序，则对当前题目选项进行洗牌
            controller.shuffleCurrentQuestionOptions();
          }

          controller.resetCurrentAnswer();
          setState(() {
            currentAnswer = null;
            multipleAnswers.clear();
            _showingWrongAnswer = false;
            _isProcessingAnswer = false; // 现在在延迟后重置处理状态，允许重新选择
          });
        }
      });
    }
  }

  // 安排多选题的延迟检查（给用户时间选择多个选项）
  void _scheduleMultipleChoiceCheck(QuizController controller) {
    // 取消之前的检查定时器
    _multipleChoiceCheckTimer?.cancel();

    // 设置自定义延迟后检查答案
    _multipleChoiceCheckTimer = Timer(
      Duration(
        milliseconds: ref.read(settingsProvider).multipleChoiceAutoSwitchDelay,
      ),
      () {
        if (mounted) {
          _handlePracticeModeAnswer(controller);
        }
      },
    );
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
        _progressCardSinking = true; // 同步下沉动画开始
        // 不在这里设置 _isProcessingAnswer = true，让用户能继续选择其他选项
      });

      // 设置自定义延迟后自动切换到下一题并添加切题震动
      _multipleChoiceCheckTimer = Timer(
        Duration(milliseconds: settings.multipleChoiceAutoSwitchDelay),
        () {
          if (mounted && !quizState.isLastQuestion) {
            HapticManager.switchQuestion();
            setState(() {
              _isProcessingAnswer = true; // 只在切题前禁用选项
            });
            _autoSwitchToNext(controller);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    // 监听触感设置变化并更新HapticManager
    ref.listen<HapticSettings>(hapticSettingsProvider, (previous, current) {
      HapticManager.updateSettings(hapticEnabled: current.hapticEnabled);
    });

    // 初始化时也要更新设置
    final hapticSettings = ref.read(hapticSettingsProvider);
    HapticManager.updateSettings(hapticEnabled: hapticSettings.hapticEnabled);

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
        // 根据模式决定显示方式
        if (state.mode == QuizMode.practice) {
          // 练习模式：显示完成页面
          return _buildCompletedView(state, controller);
        } else {
          // 模拟模式：跳转到结果页显示得分和错题统计
          _countdownTimer?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appRouter.goToResult();
          });
          return const Center(child: CircularProgressIndicator());
        }

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

    // 确保PageController与当前题目索引同步 - 添加防抖动
    if (!_isUpdatingUI) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            _pageController.hasClients &&
            _pageController.page?.round() != state.currentQuestionIndex) {
          _pageController.animateToPage(
            state.currentQuestionIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return Column(
      children: [
        // 进度条（切题时轻微下沉与缩放动画）
        AnimatedSlide(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          offset: _progressCardSinking ? const Offset(0, 0.02) : Offset.zero,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: _progressCardSinking ? 0.98 : 1.0,
            curve: Curves.easeOutCubic,
            child: _buildProgressBar(state),
          ),
        ),

        // 题目内容 - 使用PageView实现滑动切换
        Expanded(
          child: Platform.isWindows
              ? Listener(
                  onPointerDown: _handleMouseDragStart,
                  onPointerUp: _handleMouseDragEnd,
                  onPointerCancel: _handleMouseDragCancel,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: state.questions.length,
                    physics: const BouncingScrollPhysics(), // 使用弹性滚动物理效果
                    onPageChanged: (index) {
                      // 滑动切换题目时更新状态
                      controller.goToQuestion(index);
                      // 取消自动切题状态和错误状态，重置选项锁定状态
                      setState(() {
                        _isAutoSwitching = false;
                        _progressCardSinking = false; // 同步结束下沉动画
                        _isAutoSwitching = false;
                        _progressCardSinking = false; // 同步结束下沉动画
                        _showingWrongAnswer = false;
                        _showingCorrectAnswer = false;
                        _isProcessingAnswer = false; // 重置选项锁定状态
                      });

                      // 页面切换时进行内存优化
                      MemoryManager.onPageTransition();
                    },
                    itemBuilder: (context, index) {
                      final question = state.questions[index];
                      return _buildQuestionPage(
                        index,
                        question,
                        state,
                        controller,
                      );
                    },
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: state.questions.length,
                  physics: const BouncingScrollPhysics(), // 使用弹性滚动物理效果
                  onPageChanged: (index) {
                    // 滑动切换题目时更新状态
                    controller.goToQuestion(index);
                    controller.goToQuestion(index);
                    // 取消自动切题状态和错误状态，重置选项锁定状态
                    setState(() {
                      _isAutoSwitching = false;
                      _showingWrongAnswer = false;
                      _showingCorrectAnswer = false;
                      _isProcessingAnswer = false; // 重置选项锁定状态
                    });

                    // 页面切换时进行内存优化
                    MemoryManager.onPageTransition();
                  },
                  itemBuilder: (context, index) {
                    final question = state.questions[index];
                    return _buildQuestionPage(
                      index,
                      question,
                      state,
                      controller,
                    );
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
        onTap: () {
          HapticManager.openQuestionCard();
          _showQuestionCard(context, state);
        },
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: _md3CardBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: _isAutoSwitching
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.55),
                    width: 1.5,
                  )
                : Border.all(color: _md3OutlineSoft(context), width: 1),
            boxShadow: [
              BoxShadow(
                color: _isAutoSwitching
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.18)
                    : _md3Shadow(context),
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
                    _isAutoSwitching ? '下一题' : '答题卡',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _isAutoSwitching
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
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
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.28),
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
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.28),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        '第${state.currentQuestionIndex + 1}题',
                        style: TextStyle(
                          fontSize: 10,
                          color: typeColor,
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
                        color: _remainingTimeInSeconds <= 300
                            ? Theme.of(
                                context,
                              ).colorScheme.error.withValues(alpha: 0.10)
                            : Theme.of(
                                context,
                              ).colorScheme.tertiary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _remainingTimeInSeconds <= 300
                              ? Theme.of(
                                  context,
                                ).colorScheme.error.withValues(alpha: 0.28)
                              : Theme.of(
                                  context,
                                ).colorScheme.tertiary.withValues(alpha: 0.28),
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
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.tertiary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatTime(_remainingTimeInSeconds),
                            style: TextStyle(
                              fontSize: 10,
                              color: _remainingTimeInSeconds <= 300
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.tertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  //const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
                    backgroundColor: _md3SurfaceVariant(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isAutoSwitching
                          ? Theme.of(context).colorScheme.primary
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
    bool isDisabled = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 禁用状态：未选项更灰一些
    if (isDisabled && !isSelected) {
      return scheme.surfaceContainerHighest.withValues(
        alpha: isDarkMode ? 0.22 : 0.32,
      );
    }

    if (isCorrectAnswer && isSelected) {
      return scheme.primaryContainer; // 正确：使用主容器色
    }
    if (isWrongAnswer && isSelected) {
      return scheme.errorContainer; // 错误：使用错误容器色
    }
    if (isHintAnswer) {
      // 提示态：使用 tertiaryContainer 更贴近 MD3 提示强调
      return scheme.tertiaryContainer.withValues(alpha: 0.6);
    }
    if (isAutoSwitching) {
      return scheme.primaryContainer; // 自动切题动画：同正确的容器色
    }
    if (isSelected) {
      // 选中但未定性：用 surfaceVariant 提升对比度
      return scheme.surfaceContainerHighest.withValues(
        alpha: isDarkMode ? 0.35 : 0.42,
      );
    }
    return _md3CardBackground(context);
  }

  // 已统一为 BoxDecoration 的 boxShadow，移除未使用的选项阴影计算方法

  Color _getOptionTextColor(
    BuildContext context,
    bool isSelected,
    bool isAutoSwitching, {
    bool isWrongAnswer = false,
    bool isCorrectAnswer = false,
    bool isHintAnswer = false,
    bool isDisabled = false,
  }) {
    final scheme = Theme.of(context).colorScheme;

    if (isDisabled && !isSelected) {
      return scheme.onSurface.withValues(alpha: 0.6);
    }
    if (isCorrectAnswer && isSelected) {
      return scheme.onPrimaryContainer;
    }
    if (isWrongAnswer && isSelected) {
      return scheme.onErrorContainer;
    }
    if (isHintAnswer) {
      return scheme.onTertiaryContainer;
    }
    if (isAutoSwitching) {
      return scheme.onPrimaryContainer;
    }
    if (isSelected) {
      // 选中但未定性：在 surfaceVariant 上的前景
      return scheme.onSurfaceVariant;
    }
    return scheme.onSurface;
  }

  Widget _buildQuestionHeader(
    QuizState state,
    QuestionModel question, [
    int? questionIndex,
  ]) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _md3CardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _md3OutlineSoft(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: _md3Shadow(context),
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
        elevation: 0, // 使用与题干容器一致的悬浮效果（由 BoxShadow 提供）
        borderRadius: BorderRadius.circular(_optionCardRadius),
        shadowColor: Colors.transparent,
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
              isDisabled: _isProcessingAnswer && !_showingWrongAnswer,
            ),
            borderRadius: BorderRadius.circular(_optionCardRadius),
            border: Border.all(color: _md3OutlineSoft(context), width: 1),
            boxShadow: [
              BoxShadow(
                color: _md3Shadow(context),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: _optionPadding,
            leading: GestureDetector(
              onTap: (_isProcessingAnswer || _showingWrongAnswer)
                  ? null
                  : () {
                      _handleSingleChoiceSelection(option, controller);
                    },
              child: Container(
                width: _optionButtonSize,
                height: _optionButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        (_isProcessingAnswer &&
                            !_showingWrongAnswer &&
                            !isSelected)
                        ? _md3OutlineSoft(context)
                        : isSelected
                        ? (isCorrectAnswer
                              ? Colors.green.shade700
                              : isWrongAnswer
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red.shade800
                                    : Colors.red.shade600)
                              : isHintAnswer
                              ? Colors.orange.shade600
                              // : isAutoSwitching
                              // ? Colors.green.shade700
                              : _getPrimaryColor(context))
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected
                      ? (isCorrectAnswer
                            ? Colors.green.shade700
                            : isWrongAnswer
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade800
                                  : Colors.red.shade600)
                            : isHintAnswer
                            ? Theme.of(context).colorScheme.tertiary
                            : isAutoSwitching
                            ? Theme.of(context).colorScheme.primary
                            : _getPrimaryColor(context))
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.circle, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: _getOptionTextColor(
                      context,
                      isSelected,
                      isAutoSwitching,
                      isWrongAnswer: isWrongAnswer,
                      isCorrectAnswer: isCorrectAnswer,
                      isHintAnswer: isHintAnswer,
                      isDisabled: _isProcessingAnswer && !_showingWrongAnswer,
                    ),
                    fontSize: 18, // 增大单选题字体大小
                    height: 1.4,
                  ) ??
                  const TextStyle(),
              child: Text(option),
            ),
            onTap: (_isProcessingAnswer || _showingWrongAnswer)
                ? null
                : () {
                    _handleSingleChoiceSelection(option, controller);
                  },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_optionCardRadius),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSingleChoiceSelection(String? value, QuizController controller) {
    if (value == null || _isProcessingAnswer || _showingWrongAnswer) return;

    // 设置处理状态，防止快速点击
    setState(() {
      _isProcessingAnswer = true;
    });

    // 取消之前的自动切题定时器和选项锁定定时器
    _autoNextTimer?.cancel();
    _optionLockTimer?.cancel();

    setState(() {
      currentAnswer = value;
      _isAutoSwitching = false;
    });

    // 立即提交答案并确保保存
    controller.submitAnswer(value);

    // 立即再次确认答案已保存到状态中
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentIndex = ref
            .read(quizControllerProvider)
            .currentQuestionIndex;
        final savedAnswer = ref
            .read(quizControllerProvider)
            .userAnswers[currentIndex];
        if (savedAnswer != value) {
          // 如果答案未正确保存，再次提交
          controller.submitAnswer(value);
        }
      }
    });

    final settings = ref.read(settingsProvider);
    final quizState = ref.read(quizControllerProvider);

    // 练习模式：立即判断对错
    if (quizState.mode == QuizMode.practice) {
      _handlePracticeModeAnswer(controller);
      // 不启动选项锁定定时器，因为：
      // - 如果答对，_handlePracticeModeAnswer 会保持 _isProcessingAnswer = true 直到切题
      // - 如果答错，_handlePracticeModeAnswer 会立即重置 _isProcessingAnswer = false，允许重新选择
      return;
    }

    // 考试模式：立即触发点击震动反馈
    HapticManager.submitAnswer();

    // 考试模式：检查是否需要自动切题
    if (settings.autoNextQuestion && !quizState.isLastQuestion) {
      setState(() {
        _isAutoSwitching = true;
        _progressCardSinking = true; // 同步下沉动画开始
      });

      // 延迟0.6秒后自动切换到下一题并添加切题震动
      _autoNextTimer = Timer(const Duration(milliseconds: 600), () {
        if (mounted && !quizState.isLastQuestion) {
          // 切题前再次确认答案已保存
          final currentIndex = ref
              .read(quizControllerProvider)
              .currentQuestionIndex;
          final savedAnswer = ref
              .read(quizControllerProvider)
              .userAnswers[currentIndex];
          if (savedAnswer != value) {
            controller.submitAnswer(value);
          }

          HapticManager.switchQuestion();
          _autoSwitchToNext(controller);
        }
      });
    }

    // 启动选项锁定定时器
    _startOptionLockTimer();
  }

  void _handleMultipleChoiceSelection(
    String option,
    QuizController controller,
  ) {
    if (_isProcessingAnswer || _showingWrongAnswer) return;

    // 取消自动切题定时器
    _autoNextTimer?.cancel();
    setState(() {
      _isAutoSwitching = false;
      if (multipleAnswers.contains(option)) {
        multipleAnswers.remove(option);
      } else {
        multipleAnswers.add(option);
      }
    });
    controller.submitAnswer(multipleAnswers.toList());

    // 根据模式处理延迟逻辑
    final quizState = ref.read(quizControllerProvider);
    if (quizState.mode == QuizMode.practice) {
      // 练习模式：立即触发点击震动反馈
      HapticManager.submitAnswer();
      // 练习模式下，延迟判断答案（给用户时间选择多个选项）
      _scheduleMultipleChoiceCheck(controller);
    } else if (quizState.mode == QuizMode.exam) {
      // 考试模式：立即触发点击震动反馈
      HapticManager.submitAnswer();
      // 考试模式下，延迟自动切题（给用户时间选择多个选项）
      _scheduleExamModeMultipleChoiceAutoNext(controller);
    }
  }

  // 启动选项锁定定时器，防止快速点击
  void _startOptionLockTimer() {
    _optionLockTimer?.cancel();
    _optionLockTimer = Timer(_optionLockDuration, () {
      if (mounted) {
        setState(() {
          _isProcessingAnswer = false;
        });
      }
    });
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
        elevation: 0, // 使用与题干容器一致的悬浮效果（由 BoxShadow 提供）
        borderRadius: BorderRadius.circular(_optionCardRadius),
        shadowColor: Colors.transparent,
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
            border: Border.all(color: _md3OutlineSoft(context), width: 1),
            boxShadow: [
              BoxShadow(
                color: _md3Shadow(context),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: _optionPadding,
            leading: GestureDetector(
              onTap: (_isProcessingAnswer || _showingWrongAnswer)
                  ? null
                  : () {
                      _handleMultipleChoiceSelection(option, controller);
                    },
              child: Container(
                width: _optionButtonSize,
                height: _optionButtonSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color:
                        (_isProcessingAnswer &&
                            !_showingWrongAnswer &&
                            !isSelected)
                        ? _md3OutlineSoft(context)
                        : isSelected
                        ? (isCorrectAnswer
                              ? Colors.green.shade700
                              : isWrongAnswer
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red.shade800
                                    : Colors.red.shade600)
                              : isHintAnswer
                              ? Colors.orange.shade600
                              : _getPrimaryColor(context))
                        : Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                  color: isSelected
                      ? (isCorrectAnswer
                            ? Colors.green.shade700
                            : isWrongAnswer
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade800
                                  : Colors.red.shade600)
                            : isHintAnswer
                            ? Theme.of(context).colorScheme.tertiary
                            : _getPrimaryColor(context))
                      : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: _getOptionTextColor(
                      context,
                      isSelected,
                      false,
                      isWrongAnswer: isWrongAnswer,
                      isCorrectAnswer: isCorrectAnswer,
                      isHintAnswer: isHintAnswer,
                      isDisabled: _isProcessingAnswer && !_showingWrongAnswer,
                    ),
                    fontSize: 18, // 增大多选题字体大小
                    height: 1.4,
                  ) ??
                  const TextStyle(),
              child: Text(option),
            ),
            onTap: (_isProcessingAnswer || _showingWrongAnswer)
                ? null
                : () {
                    _handleMultipleChoiceSelection(option, controller);
                  },
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
                        ? Colors.green.shade700
                        : _getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor:
                        (isAutoNextMode && state.isLastQuestion) ||
                            state.isLastQuestion
                        ? Colors.green.shade700
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
    // 取消自动切题和选项锁定定时器
    _autoNextTimer?.cancel();
    _optionLockTimer?.cancel();
    setState(() {
      _isAutoSwitching = false;
      _progressCardSinking = false; // 同步结束下沉动画
      _isProcessingAnswer = false; // 重置处理状态，允许选项点击
    });

    if (_pageController.hasClients) {
      // 触发进度卡片下沉动画
      setState(() => _progressCardSinking = true);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _progressCardSinking = false);
      });
      _pageController.previousPage(
        duration: _buttonSwitchDuration,
        curve: _smoothCurve,
      );
    } else {
      controller.previousQuestion();
    }
  }

  void _goToNextQuestion(QuizController controller, QuizState state) {
    // 取消自动切题和选项锁定定时器
    _autoNextTimer?.cancel();
    _optionLockTimer?.cancel();
    setState(() {
      _isAutoSwitching = false;
      _progressCardSinking = false; // 同步结束下沉动画
      _showingWrongAnswer = false; // 重置错误状态
      _showingCorrectAnswer = false; // 重置正确状态
      _isProcessingAnswer = false; // 重置处理状态，允许下一题的选项点击
    });

    if (_pageController.hasClients) {
      if (state.isLastQuestion) {
        _countdownTimer?.cancel(); // 停止倒计时器
        controller.nextQuestion(); // 完成答题
      } else {
        // 触发进度卡片下沉动画
        setState(() => _progressCardSinking = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _progressCardSinking = false);
        });
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
      _progressCardSinking = false; // 同步结束下沉动画
      _isProcessingAnswer = false; // 重置处理状态，允许下一题的选项点击
    });

    if (_pageController.hasClients) {
      // 触发进度卡片下沉动画
      setState(() => _progressCardSinking = true);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _progressCardSinking = false);
      });
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
      _progressCardSinking = false; // 同步结束下沉动画
      _showingWrongAnswer = false; // 重置错误状态
      _showingCorrectAnswer = false; // 重置正确状态
      _isProcessingAnswer = false; // 重置选项锁定状态
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
    final items = List.generate(
      state.questions.length,
      (index) => QuizAnswerCardItem(index, state),
    );

    final config = AnswerCardConfig(
      title: '理论答题卡',
      icon: Icons.quiz,
      //progressTextBuilder: (completedCount, totalCount) =>
      //'$completedCount/$totalCount',
      stats: [
        AnswerCardStats(
          label: '当前',
          count: state.currentQuestionIndex + 1,
          color: Theme.of(context).colorScheme.secondary,
        ),
        AnswerCardStats(
          label: '已答',
          count: state.answeredCount,
          color: Theme.of(context).colorScheme.primary,
        ),
        AnswerCardStats(
          label: '未答',
          count: state.questions.length - state.answeredCount,
          color: Theme.of(context).colorScheme.outline,
        ),
      ],
      onItemTapped: (index) {
        final controller = ref.read(quizControllerProvider.notifier);
        _goToQuestionByIndex(index, controller);
      },
      scrollController: _questionCardScrollController,
    );

    AnswerCardHelper.showAnswerCard(context, items, config);

    // 答题卡展开时，延迟滚动到当前题目位置
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        AnswerCardHelper.scrollToCurrentItem(
          _questionCardScrollController,
          state.currentQuestionIndex,
          context: this.context,
        );
      }
    });
  }

  // 构建完成界面
  Widget _buildCompletedView(QuizState state, QuizController controller) {
    // 停止倒计时器
    _countdownTimer?.cancel();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              state.mode == QuizMode.practice ? '恭喜完成理论练习！' : '恭喜完成理论模拟！',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '您已完成 ${state.questions.length} 道题目',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // 开始新一轮按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticManager.medium();
                  // 重新开始答题
                  final currentMode = state.mode;
                  final settings = ref.read(settingsProvider);
                  controller.reset(currentMode);

                  // 根据模式使用对应的启动方法
                  if (currentMode == QuizMode.practice) {
                    // 练习模式：使用全题库答题
                    await controller.startAllQuestionsQuiz(
                      shuffleOptions: settings.shuffleOptions,
                      shuffleMode: settings.practiceShuffleMode,
                    );
                  } else {
                    // 考试模式：使用设置启动
                    await controller.startQuizWithSettings(
                      singleCount: settings.singleChoiceCount,
                      multipleCount: settings.multipleChoiceCount,
                      booleanCount: settings.booleanCount,
                      shuffleOptions: settings.shuffleOptions,
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  state.mode == QuizMode.practice ? '开始新一轮练习' : '开始新一轮模拟',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: _primaryButtonStyle(context),
              ),
            ),
            const SizedBox(height: 16),
            // 返回首页按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticManager.medium();
                  controller.reset(state.mode);
                  appRouter.goToHome();
                },
                icon: const Icon(Icons.home),
                label: const Text(
                  '返回首页',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: _secondaryButtonStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackPressed(BuildContext context) {
    //final quizState = ref.read(quizControllerProvider);
    final quizController = ref.read(quizControllerProvider.notifier);
    final settings = ref.read(settingsProvider);

    // 理论模拟（考试模式）：直接显示确认退出对话框
    //if (quizState.mode == QuizMode.exam) {
    //_showExitConfirmDialog(context);
    //return;
    //}

    // 理论练习（练习模式）：检查是否启用进度保存
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
      // 未启用进度保存：显示保存进度确认对话框（让用户选择是否临时保存）
      _showSaveProgressDialog(context, quizController);
    }
  }

  // 保存进度并退出
  Future<void> _saveProgressAndExit(QuizController quizController) async {
    try {
      final currentMode = ref.read(quizControllerProvider).mode;
      debugPrint('Saving progress before exit for ${currentMode.name} mode');
      await quizController.saveCurrentProgress();
      // 注意：不调用 reset(currentMode)，因为这会清除刚保存的进度
      // 只重置 UI 状态，不清除已保存的进度数据
      quizController.reset(); // 不传递模式参数，避免清除进度
      appRouter.goToHome();
    } catch (e) {
      debugPrint('Error saving progress before exit: $e');
      // 即使保存失败也要退出，但不清除进度
      quizController.reset(); // 不传递模式参数
      appRouter.goToHome();
    }
  }

  // 显示保存进度确认对话框
  void _showSaveProgressDialog(
    BuildContext context,
    QuizController quizController,
  ) {
    final settings = ref.read(settingsProvider);
    final quizState = ref.read(quizControllerProvider);

    // 根据是否启用自动保存显示不同的对话框内容
    String title;
    String content;

    if (settings.enableProgressSave) {
      title = '保存进度';
      content = '是否保存当前答题进度？';
    } else {
      title = '保存进度';
      content =
          '检测到您已关闭自动保存功能，是否要临时保存当前答题进度？\n\n保存后可在下次开始${quizState.mode == QuizMode.practice ? '理论练习' : '理论模拟'}时选择继续。';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 不保存进度，直接退出
              final currentMode = ref.read(quizControllerProvider).mode;
              quizController.reset(currentMode);
              appRouter.goToHome();
            },
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // 保存进度并退出（即使用户关闭了自动保存，也允许临时保存）
              _saveProgressAndExit(quizController);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 显示考试模式的退出确认对话框
  // void _showExitConfirmDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('确认退出'),
  //       content: const Text('确定要退出理论模拟吗？当前进度将会丢失。'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('取消'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             final currentMode = ref.read(quizControllerProvider).mode;
  //             ref.read(quizControllerProvider.notifier).reset(currentMode);
  //             appRouter.goToHome();
  //           },
  //           child: const Text('确定'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
