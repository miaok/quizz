import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/progress_model.dart';
import '../models/settings_model.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../widgets/immersive_scaffold.dart';
import 'score_records_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // 不保持页面状态，确保每次都重建

  // 用于强制更新进度的键
  final ValueNotifier<int> _progressUpdateKey = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // 页面初始化时更新进度
    _updateProgress();
  }

  // 手动刷新进度数据
  void _updateProgress() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _progressUpdateKey.value++;
      }
    });
  }

  @override
  void dispose() {
    _progressUpdateKey.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用super.build
    final questionCountAsync = ref.watch(questionCountProvider);
    final settings = ref.watch(settingsProvider);

    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isSmallScreen = screenHeight < 700; // 小屏幕设备

    // 横屏模式和小屏幕减小内边距和间距
    final mainPadding = isLandscape || isSmallScreen ? 8.0 : 14.0;
    final mainSpacing = isLandscape || isSmallScreen ? 6.0 : 14.0;
    final bottomSpacing = isLandscape || isSmallScreen ? 6.0 : 12.0;

    return ImmersiveScaffold(
      appBar: AppBar(
        title: const Text('酒韵', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _updateProgress();
            },
            icon: const Icon(Icons.refresh),
            tooltip: '刷新进度',
          ),
          IconButton(
            onPressed: () => appRouter.goToSettings(),
            icon: const Icon(Icons.settings),
            tooltip: '设置',
          ),
        ],
      ),
      body: ImmersivePageWrapper(
        padding: EdgeInsets.all(mainPadding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎区域 - 小屏幕时缩小高度
              _buildWelcomeSection(questionCountAsync, settings, isSmallScreen),

              SizedBox(height: mainSpacing),

              // 功能卡片网格
              _buildFeatureCards(context),

              // 底部额外间距，确保不溢出
              SizedBox(height: bottomSpacing),
            ],
          ),
        ),
      ),
    );
  }

  // 构建现代化Hero欢迎区域
  Widget _buildWelcomeSection(
    AsyncValue<int> questionCountAsync,
    QuizSettings settings,
    bool isSmallScreen,
  ) {
    // 响应式高度调整 - 进一步减小
    final welcomeHeight = isSmallScreen ? 50.0 : 110.0;
    final welcomePadding = isSmallScreen ? 4.0 : 10.0;

    return GestureDetector(
      onTap: () => _navigateToScoreRecords(),
      child: Container(
        width: double.infinity,
        height: welcomeHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.06),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24), // 减小圆角
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08), // 减小阴影
              blurRadius: 16, // 减小模糊半径
              offset: const Offset(0, 4), // 减小偏移
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(welcomePadding),
          child: Row(
            // 改为Row布局，在右侧添加箭头提示
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // 改为居中显示
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 主标题
                    Text(
                      '开始学习吧！',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.1, // 减小行高
                            fontSize: isSmallScreen ? 16 : 20, // 调整字体大小
                          ),
                    ),
                    SizedBox(height: isSmallScreen ? 1 : 4), // 进一步减小间距
                    // 进度信息
                    _buildProgressInfo(questionCountAsync, isSmallScreen),
                  ],
                ),
              ),
              // 点击提示箭头
              // Container(
              //   padding: const EdgeInsets.all(8),
              //   decoration: BoxDecoration(
              //     color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              //     shape: BoxShape.circle,
              //   ),
              //   child: Icon(
              //     Icons.arrow_forward_ios,
              //     size: isSmallScreen ? 12 : 16,
              //     color: Theme.of(context).colorScheme.primary,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建进度信息
  Widget _buildProgressInfo(
    AsyncValue<int> questionCountAsync,
    bool isSmallScreen,
  ) {
    return ValueListenableBuilder<int>(
      valueListenable: _progressUpdateKey,
      builder: (context, key, child) {
        return Consumer(
          builder: (context, ref, child) {
            // 获取理论练习进度
            final progressService = ref.read(progressServiceProvider);

            return FutureBuilder<List<QuizProgress?>>(
              // 使用key确保每次都重新加载数据
              key: ValueKey('progress_$key'),
              future: Future.wait([
                progressService.loadQuizProgress(QuizMode.practice),
                progressService.loadBlindTasteProgress(),
                progressService.loadFlashcardProgress(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    '加载进度中...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                    textAlign: TextAlign.center,
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    '进度加载失败',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                    textAlign: TextAlign.center,
                  );
                }

                final progressList = snapshot.data ?? [];
                final theoryProgress = progressList.isNotEmpty
                    ? progressList[0]
                    : null;
                final tasteProgress = progressList.length > 1
                    ? progressList[1]
                    : null;
                final flashcardProgress = progressList.length > 2
                    ? progressList[2]
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // 居中对齐
                  children: [
                    // 理论练习进度
                    _buildProgressRow(
                      icon: Icons.school_outlined,
                      title: '理论练习',
                      progress: theoryProgress,
                      isSmallScreen: isSmallScreen,
                      isCentered: true, // 添加居中参数
                    ),
                    SizedBox(height: isSmallScreen ? 1 : 2), // 进一步减小间距
                    // 品评练习进度
                    _buildProgressRow(
                      icon: Icons.wine_bar_outlined,
                      title: '品评练习',
                      progress: tasteProgress,
                      isSmallScreen: isSmallScreen,
                      isCentered: true, // 添加居中参数
                    ),
                    SizedBox(height: isSmallScreen ? 1 : 2), // 进一步减小间距
                    // 酒样闪卡进度
                    _buildProgressRow(
                      icon: Icons.style_outlined,
                      title: '酒样闪卡',
                      progress: flashcardProgress,
                      isSmallScreen: isSmallScreen,
                      isCentered: true, // 添加居中参数
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // 构建单个进度行
  Widget _buildProgressRow({
    required IconData icon,
    required String title,
    required QuizProgress? progress,
    required bool isSmallScreen,
    bool isCentered = false, // 添加居中参数
  }) {
    String progressText;
    Color textColor;

    if (progress != null && progress.isValid) {
      // 有有效进度
      if (progress.type == ProgressType.quiz) {
        final current = progress.currentIndex + 1;
        final total = progress.questions.length;
        progressText = '第 $current/$total 题';
      } else if (progress.type == ProgressType.blindTaste) {
        final completedCount = progress.blindTasteCompletedIds?.length ?? 0;
        final totalFromPool = progress.blindTasteQuestionPool?.length ?? 0;
        final totalFromSetting = progress.blindTasteMaxItems ?? 0;
        final totalItems = totalFromPool > 0 ? totalFromPool : totalFromSetting;

        if (totalItems > 0) {
          final currentCup = completedCount >= totalItems
              ? totalItems
              : completedCount + 1;
          progressText = '第 $currentCup/$totalItems 杯';
        } else {
          progressText = '进行中';
        }
      } else if (progress.type == ProgressType.flashcard) {
        final currentCard = progress.currentIndex + 1;

        // 对于闪卡，显示当前位置而不是已查看数量
        progressText = '第 $currentCard 张';
      } else {
        progressText = '进行中';
      }
      textColor = Theme.of(context).colorScheme.primary;
    } else {
      // 无进度
      progressText = '未开始';
      textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    Widget content = Row(
      mainAxisSize: isCentered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Icon(icon, size: isSmallScreen ? 12 : 14, color: textColor),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: isSmallScreen ? 11 : 13,
          ),
        ),
        SizedBox(width: isSmallScreen ? 4 : 6),
        Text(
          progressText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontSize: isSmallScreen ? 10 : 12,
          ),
        ),
      ],
    );

    return isCentered ? Center(child: content) : content;
  }

  // 构建现代化功能卡片布局
  Widget _buildFeatureCards(BuildContext context) {
    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isSmallScreen = screenHeight < 700;

    // 响应式间距 - 小屏幕进一步缩小
    final verticalSpacing = isLandscape || isSmallScreen ? 8.0 : 16.0;
    final horizontalSpacing = isLandscape || isSmallScreen ? 8.0 : 16.0;
    final sectionSpacing = isLandscape || isSmallScreen ? 12.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主要功能区 - 两个大卡片
        Text(
          '模拟考试',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: isSmallScreen ? 18 : null,
          ),
        ),
        SizedBox(height: verticalSpacing),

        // 主要功能卡片 - 始终使用水平排列
        Row(
          children: [
            Expanded(
              child: _buildMainFeatureCard(
                title: '理论模拟',
                icon: Icons.assignment_outlined,
                gradientColors: [
                  Colors.orange.shade400,
                  Colors.deepOrange.shade600,
                ],
                onTap: () => _startMockExam(context, ref),
              ),
            ),
            SizedBox(width: horizontalSpacing),
            Expanded(
              child: _buildMainFeatureCard(
                title: '品评模拟',
                icon: Icons.local_bar_outlined,
                gradientColors: [Colors.teal.shade400, Colors.cyan.shade700],
                onTap: () => appRouter.goToWineSimulation(),
              ),
            ),
          ],
        ),

        SizedBox(height: sectionSpacing),

        // 练习工具区 - 四个小卡片
        Text(
          '日常练习',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: isSmallScreen ? 18 : null,
          ),
        ),
        SizedBox(height: verticalSpacing),

        // 练习工具卡片 - 始终使用2x2网格布局
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildPracticeCard(
                    title: '理论练习',
                    icon: Icons.school_outlined,
                    gradientColors: [
                      Colors.blue.shade400,
                      Colors.indigo.shade600,
                    ],
                    onTap: () => _startQuiz(context, ref),
                  ),
                ),
                SizedBox(width: horizontalSpacing),
                Expanded(
                  child: _buildPracticeCard(
                    title: '品评练习',
                    icon: Icons.wine_bar_outlined,
                    gradientColors: [Colors.red.shade400, Colors.pink.shade600],
                    onTap: () => _startBlindTaste(context, ref),
                  ),
                ),
              ],
            ),
            SizedBox(height: verticalSpacing),
            Row(
              children: [
                Expanded(
                  child: _buildPracticeCard(
                    title: '酒样闪卡',
                    icon: Icons.style_outlined,
                    gradientColors: [
                      Colors.purple.shade400,
                      Colors.deepPurple.shade600,
                    ],
                    onTap: () => _startFlashcard(context, ref),
                  ),
                ),

                SizedBox(width: horizontalSpacing),
                Expanded(
                  child: _buildPracticeCard(
                    title: '题库搜索',
                    icon: Icons.search_outlined,
                    gradientColors: [
                      Colors.green.shade400,
                      Colors.teal.shade600,
                    ],
                    onTap: () => appRouter.goToSearch(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 构建主要功能大卡片 - Spotify风格
  Widget _buildMainFeatureCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isSmallScreen = screenHeight < 700;

    // 进一步减小卡片高度
    final cardHeight = isLandscape ? 70.0 : (isSmallScreen ? 80.0 : 100.0);
    final cardPadding = isLandscape || isSmallScreen ? 12.0 : 20.0;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withValues(alpha: 0.1),
            gradientColors[1].withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: gradientColors[0].withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // 图标容器 - 现代化设计
                Container(
                  width: isLandscape || isSmallScreen ? 40 : 60,
                  height: isLandscape || isSmallScreen ? 40 : 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: isLandscape || isSmallScreen ? 20 : 28,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isLandscape || isSmallScreen ? 12 : 20),

                // 文本内容 - 居中显示
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: isLandscape || isSmallScreen ? 14 : 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 构建练习工具小卡片 - Apple Music风格
  Widget _buildPracticeCard({
    required String title,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final isSmallScreen = screenHeight < 700;

    // 响应式卡片尺寸 - 针对小屏幕进一步优化
    final cardHeight = isLandscape ? 90.0 : (isSmallScreen ? 100.0 : 120.0);
    final iconSize = isLandscape || isSmallScreen ? 20.0 : 28.0;
    final fontSize = isLandscape || isSmallScreen ? 12.0 : 16.0;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isLandscape || isSmallScreen ? 12.0 : 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 图标容器
                Container(
                  width: isLandscape || isSmallScreen ? 40 : 56,
                  height: isLandscape || isSmallScreen ? 40 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: iconSize, color: Colors.white),
                ),
                // 减小图标与文字的间距
                SizedBox(height: isLandscape || isSmallScreen ? 4 : 6),

                // 标题
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    try {
      // 检查是否有保存的理论练习进度（使用增强的验证逻辑）
      final hasSavedProgress = await quizController.hasSavedProgressForMode(
        QuizMode.practice,
      );

      if (hasSavedProgress && context.mounted) {
        final description = await quizController.getSavedProgressDescription(
          QuizMode.practice,
        );
        if (!context.mounted) return;

        // 检查是否是已完成的练习
        final progressService = ref.read(progressServiceProvider);
        final progress = await progressService.loadQuizProgress(
          QuizMode.practice,
        );
        final isCompleted =
            progress != null &&
            progress.mode == QuizMode.practice &&
            progress.currentIndex >= progress.questions.length - 1;

        if (!context.mounted) return;

        bool shouldRestore;
        if (isCompleted) {
          // 已完成所有题目，询问是否重新开始
          final dialogResult = await _showRestartCompletedPracticeDialog(
            context,
            description,
          );
          if (dialogResult == null) {
            // 用户点击关闭按钮，取消操作
            return;
          }

          if (dialogResult) {
            // 用户选择重新开始，清除旧进度
            await quizController.clearSavedProgress(QuizMode.practice);
            shouldRestore = false; // 设置为false以开始新练习
          } else {
            // 用户选择查看结果，恢复到已完成状态
            shouldRestore = true;
          }
        } else {
          // 未完成的练习进度
          if (settings.enableProgressSave &&
              settings.enableDefaultContinueProgress) {
            // 启用自动保存且默认继续进度，不显示对话框
            shouldRestore = true;
          } else {
            // 显示确认对话框
            if (!context.mounted) return;
            final dialogResult = await _showRestoreProgressDialog(
              context,
              description,
              isAutoSaveDisabled: !settings.enableProgressSave,
            );
            if (dialogResult == null) {
              // 用户点击关闭按钮，取消操作
              return;
            }
            shouldRestore = dialogResult;
          }
        }

        if (shouldRestore) {
          final restored = await quizController.restoreProgress(
            QuizMode.practice,
          );
          if (restored) {
            // 导航到答题页面
            appRouter.goToQuiz();
            return;
          } else {
            // 恢复失败，清除进度并继续重新开始
            debugPrint('Failed to restore progress, starting new quiz');
            await quizController.clearSavedProgress(QuizMode.practice);
          }
        } else {
          // 用户选择不恢复进度
          if (isCompleted) {
            // 如果是已完成的进度且用户选择查看结果，不应该清除进度
            // 这种情况在上面已经处理，不会走到这里
          } else {
            // 用户明确选择"重新开始"而不是"继续答题"，才清除进度
            await quizController.clearSavedProgress(QuizMode.practice);
          }
        }
      }

      // 开始全题库答题，使用用户的选项乱序设置
      await quizController.startAllQuestionsQuiz(
        shuffleOptions: settings.shuffleOptions,
        shuffleMode: settings.practiceShuffleMode,
      );

      // 导航到答题页面
      appRouter.goToQuiz();
    } catch (e) {
      debugPrint('Error starting quiz: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('启动理论练习失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<bool?> _showRestoreProgressDialog(
    BuildContext context,
    String? description, {
    bool isAutoSaveDisabled = false,
  }) async {
    if (!context.mounted) return null;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('恢复进度'),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAutoSaveDisabled) ...[
                const Text('检测到您已关闭自动保存功能，但仍有之前保存的进度：'),
                const SizedBox(height: 8),
              ] else ...[
                const Text('检测到未完成的答题进度：'),
                const SizedBox(height: 8),
              ],
              Text(
                description ?? '未知进度',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('是否要继续之前的答题？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('重新开始'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续答题'),
            ),
          ],
        ),
      ),
    );
  }

  void _startMockExam(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    // 理论模拟不需要加载任何保存的进度，直接开始新的考试
    // 使用设置中的配置开始模拟考试
    quizController.startQuizWithSettings(
      singleCount: settings.singleChoiceCount,
      multipleCount: settings.multipleChoiceCount,
      booleanCount: settings.booleanCount,
      shuffleOptions: settings.shuffleOptions,
    );

    // 导航到答题页面
    appRouter.goToQuiz();
  }

  void _startBlindTaste(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final blindTasteController = ref.read(blindTasteProvider.notifier);

    // 检查是否有保存的进度
    if (settings.enableProgressSave) {
      final hasSavedProgress = await blindTasteController.hasSavedProgress();
      if (hasSavedProgress && context.mounted) {
        final description = await blindTasteController
            .getSavedProgressDescription();
        if (!context.mounted) return;

        bool? shouldRestoreResult;
        if (settings.enableDefaultContinueProgress) {
          // 默认继续进度，不显示对话框
          shouldRestoreResult = true;
        } else {
          // 显示确认对话框
          shouldRestoreResult = await _showRestoreBlindTasteProgressDialog(
            context,
            description,
          );
        }

        if (shouldRestoreResult == null) {
          return; // 用户点击关闭按钮，取消操作
        }

        if (shouldRestoreResult) {
          debugPrint('User chose to restore progress, attempting restore...');
          final restored = await blindTasteController.restoreProgress();
          if (restored) {
            debugPrint('Progress restored successfully in home page');
            // 直接导航到品评页面，页面不需要再次恢复
            appRouter.goToBlindTaste();
            return;
          } else {
            debugPrint('Failed to restore progress, will start new session');
            // 恢复失败（可能是设置不匹配），清除进度并重新开始
            await blindTasteController.clearSavedProgress();
            // 重置状态，确保从头开始
            blindTasteController.reset();
          }
        } else {
          debugPrint('User chose not to restore, clearing saved progress');
          // 用户选择不恢复，清除保存的进度
          await blindTasteController.clearSavedProgress();
          // 重置状态，确保从头开始
          blindTasteController.reset();
        }
      }
    }

    debugPrint(
      'Navigating to blind taste page (no saved progress or user chose new session)',
    );
    // 导航到品评页面无保存进度或用户选择新开始）
    appRouter.goToBlindTaste();
  }

  void _startFlashcard(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final flashcardController = ref.read(flashcardProvider.notifier);

    // 检查是否有保存的进度
    if (settings.enableProgressSave) {
      final hasSavedProgress = await flashcardController.hasSavedProgress();
      if (hasSavedProgress && context.mounted) {
        final description = await flashcardController
            .getSavedProgressDescription();
        if (!context.mounted) return;

        bool shouldRestore;
        if (settings.enableDefaultContinueProgress) {
          // 默认继续进度，不显示对话框
          shouldRestore = true;
        } else {
          // 显示确认对话框
          final dialogResult = await _showRestoreFlashcardProgressDialog(
            context,
            description,
          );
          if (dialogResult == null) {
            // 用户点击关闭按钮，取消操作
            return;
          }
          shouldRestore = dialogResult;
        }

        if (shouldRestore) {
          final restored = await flashcardController.restoreProgress(
            randomOrder: settings.enableFlashcardRandomOrder,
          );
          if (restored) {
            // 导航到闪卡页面
            appRouter.goToFlashcard();
            return;
          } else {
            // 恢复失败（可能是设置不匹配），清除进度并重新开始
            await flashcardController.clearProgress();
            // 重置状态后不需要再导航，因为会重新开始新的闪卡
          }
        } else {
          // 用户选择不恢复，清除保存的进度
          await flashcardController.clearProgress();
        }
      }
    }

    // 导航到闪卡记忆页面
    appRouter.goToFlashcard();
  }

  Future<bool?> _showRestoreBlindTasteProgressDialog(
    BuildContext context,
    String? description,
  ) async {
    if (!context.mounted) return null;

    return await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('恢复酒样练习进度'),
              IconButton(
                onPressed: () => Navigator.of(context).pop(null),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('检测到未完成的酒样练习进度：'),
              const SizedBox(height: 8),
              Text(
                description ?? '未知进度',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('是否要继续之前的酒样练习？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('重新开始'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续练习'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showRestoreFlashcardProgressDialog(
    BuildContext context,
    String? description,
  ) async {
    if (!context.mounted) return null;

    return await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('恢复闪卡进度'),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('检测到未完成的闪卡记忆进度：'),
              const SizedBox(height: 8),
              Text(
                description ?? '未知进度',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text('是否要继续之前的闪卡记忆？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('重新开始'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('继续记忆'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showRestartCompletedPracticeDialog(
    BuildContext context,
    String? description,
  ) async {
    if (!context.mounted) return null;

    return await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('练习已完成'),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('您已完成了所有练习题目：'),
              const SizedBox(height: 8),
              Text(
                description ?? '练习已完成',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text('您希望：'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('查看结果'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('重新开始'),
            ),
          ],
        ),
      ),
    );
  }

  // 导航到得分记录页面并刷新数据
  void _navigateToScoreRecords() {
    // 先刷新得分记录数据
    ref.invalidate(scoreRecordsProvider);
    ref.invalidate(scoreStatisticsProvider);
    // 然后导航
    appRouter.goToScoreRecords();
  }
}
