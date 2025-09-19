import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../widgets/immersive_scaffold.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final questionCountAsync = ref.watch(questionCountProvider);
    final settings = ref.watch(settingsProvider);

    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 横屏模式减小内边距和间距
    final mainPadding = isLandscape ? 10.0 : 14.0;
    final mainSpacing = isLandscape ? 8.0 : 14.0;
    final bottomSpacing = isLandscape ? 8.0 : 12.0;

    return ImmersiveScaffold(
      appBar: AppBar(
        title: const Text('酒韵', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
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
              // 欢迎区域
              _buildWelcomeSection(questionCountAsync, settings),

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

  // 构建欢迎区域 - 优雅的渐变设计
  Widget _buildWelcomeSection(
    AsyncValue<int> questionCountAsync,
    QuizSettings settings,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.wine_bar,
                    size: 40,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '欢迎来到酒韵',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '专业的白酒品鉴学习平台',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 构建功能卡片 - 错落有致的布局
  Widget _buildFeatureCards(BuildContext context) {
    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 横屏模式减小间距
    final verticalSpacing = isLandscape ? 6.0 : 10.0;
    final horizontalSpacing = isLandscape ? 8.0 : 10.0;
    final bottomSpacing = isLandscape ? 8.0 : 12.0;

    final features = [
      _FeatureCard(
        title: '理论模拟',
        subtitle: '模拟考试，检验能力',
        icon: Icons.assignment,
        color: Colors.orange,
        onTap: () => _startMockExam(context, ref),
        isLarge: true,
      ),
      _FeatureCard(
        title: '理论练习',
        subtitle: '巩固基础，提升理论',
        icon: Icons.school,
        color: Colors.blue,
        onTap: () => _startQuiz(context, ref),
        isLarge: false,
      ),
      _FeatureCard(
        title: '酒样闪卡',
        subtitle: '记忆酒样特征，提升识别能力',
        icon: Icons.card_membership,
        color: Colors.purple,
        onTap: () => _startFlashcard(context, ref),
        isLarge: false,
      ),
      _FeatureCard(
        title: '品评模拟',
        subtitle: '模拟流程，提升经验',
        icon: Icons.local_bar,
        color: Colors.teal,
        onTap: () => appRouter.goToWineSimulation(),
        isLarge: true,
      ),
      _FeatureCard(
        title: '品评练习',
        subtitle: '盲品练习，记忆标准',
        icon: Icons.wine_bar,
        color: Colors.red,
        onTap: () => _startBlindTaste(context, ref),
        isLarge: false,
      ),
      _FeatureCard(
        title: '题库搜索',
        subtitle: '快速查找题目，精准学习',
        icon: Icons.search,
        color: Colors.green,
        onTap: () => appRouter.goToSearch(),
        isLarge: false,
      ),
    ];

    return Column(
      children: [
        // 第一行：大卡片
        _buildFeatureCard(features[0]),
        SizedBox(height: verticalSpacing),

        // 第二行：两个小卡片
        Row(
          children: [
            Expanded(child: _buildFeatureCard(features[1])),
            SizedBox(width: horizontalSpacing),
            Expanded(child: _buildFeatureCard(features[2])),
          ],
        ),
        SizedBox(height: verticalSpacing),

        // 第三行：大卡片
        _buildFeatureCard(features[3]),
        SizedBox(height: bottomSpacing),

        // 第四行：两个小卡片
        Row(
          children: [
            Expanded(child: _buildFeatureCard(features[4])),
            SizedBox(width: horizontalSpacing),
            Expanded(child: _buildFeatureCard(features[5])),
          ],
        ),
      ],
    );
  }

  // 构建单个功能卡片 - 错落有致的布局
  Widget _buildFeatureCard(_FeatureCard feature) {
    if (feature.isLarge) {
      return _buildLargeCard(feature);
    } else {
      return _buildSmallCard(feature);
    }
  }

  // 大卡片 - 横向布局
  Widget _buildLargeCard(_FeatureCard feature) {
    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 横屏模式下减小卡片高度和内边距
    final cardHeight = isLandscape ? 80.0 : 100.0;
    final cardPadding = isLandscape ? 16.0 : 20.0;
    final iconSize = isLandscape ? 52.0 : 64.0;
    final iconIconSize = isLandscape ? 26.0 : 32.0;
    final titleFontSize = isLandscape ? 18.0 : null;

    return Card(
      elevation: 3,
      shadowColor: feature.color.withValues(alpha: 0.3),
      surfaceTintColor: feature.color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                feature.color.withValues(alpha: 0.1),
                feature.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              children: [
                // 图标容器
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        feature.color.withValues(alpha: 0.9),
                        feature.color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: feature.color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    feature.icon,
                    size: iconIconSize,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isLandscape ? 16 : 20),
                // 文本内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        feature.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: titleFontSize,
                        ),
                      ),
                      SizedBox(height: isLandscape ? 2 : 6),
                      Text(
                        feature.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                          fontSize: isLandscape ? 13 : null, // 横屏模式字体更小
                        ),
                        maxLines: isLandscape ? 1 : 2, // 横屏模式只显示一行
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 箭头图标
                Container(
                  width: isLandscape ? 28 : 32,
                  height: isLandscape ? 28 : 32,
                  decoration: BoxDecoration(
                    color: feature.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: isLandscape ? 14 : 16,
                    color: feature.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 小卡片 - 简洁的垂直布局
  Widget _buildSmallCard(_FeatureCard feature) {
    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 横屏模式下减小卡片高度和内边距
    final cardHeight = isLandscape ? 90.0 : 120.0;
    final cardPadding = isLandscape ? 12.0 : 18.0;
    final iconSize = isLandscape ? 40.0 : 52.0;
    final iconPadding = isLandscape ? 12.0 : 16.0;
    final textSpacing = isLandscape ? 4.0 : 8.0;

    return Card(
      elevation: 2,
      shadowColor: feature.color.withValues(alpha: 0.2),
      surfaceTintColor: feature.color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: cardHeight,
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标容器 - 更大更突出
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      feature.color.withValues(alpha: 0.8),
                      feature.color.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(iconPadding),
                  boxShadow: [
                    BoxShadow(
                      color: feature.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  feature.icon,
                  size: isLandscape ? 24 : 32,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: textSpacing),
              // 标题 - 居中显示
              Text(
                feature.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: isLandscape ? 13 : 16, // 横屏模式字体更小
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
            // 重置状态，确保从头开始
            flashcardController.reset();
          }
        } else {
          // 用户选择不恢复，清除保存的进度
          await flashcardController.clearProgress();
          // 重置状态，确保从头开始
          flashcardController.reset();
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
}

// 功能卡片数据类
class _FeatureCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;
  final bool isLarge;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLarge = false,
  });
}
