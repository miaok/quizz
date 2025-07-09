import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/settings_provider.dart';
import '../router/app_router.dart';
import '../utils/system_ui_manager.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 设置首页的系统UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemUIManager.restoreDefaultUI();
    });
  }

  @override
  Widget build(BuildContext context) {
    final questionCountAsync = ref.watch(questionCountProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QUIZ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // 使用新的MD3主题，移除自定义背景色
        actions: [
          IconButton(
            onPressed: () => appRouter.goToSettings(),
            icon: const Icon(Icons.settings),
            tooltip: '设置',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false, // 底部不需要安全区域，因为我们隐藏了导航栏
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎区域
              _buildWelcomeSection(questionCountAsync, settings),

              const SizedBox(height: 18),

              // 功能卡片网格
              _buildFeatureCards(context),

              // 底部额外间距，确保不溢出
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 构建欢迎区域 - MD3风格
  Widget _buildWelcomeSection(
    AsyncValue<int> questionCountAsync,
    QuizSettings settings,
  ) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.quiz,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            // 文本内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lets Practice!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  questionCountAsync.when(
                    data: (count) => Text(
                      '题库共有 $count 道题目 • 当前设置：${settings.totalQuestions} 题',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    loading: () => Text(
                      '加载中...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    error: (error, stack) => Text(
                      '题库加载失败',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建功能卡片网格
  Widget _buildFeatureCards(BuildContext context) {
    final features = [
      _FeatureCard(
        title: '刷题练习',
        subtitle: '',
        icon: Icons.play_circle_fill,
        color: Colors.green,
        onTap: () => _startQuiz(context, ref),
      ),
      _FeatureCard(
        title: '酒样品鉴',
        subtitle: '',
        icon: Icons.wine_bar,
        color: Colors.deepOrange,
        onTap: () => _startBlindTaste(context, ref),
      ),
      _FeatureCard(
        title: '模拟考试',
        subtitle: '',
        icon: Icons.assignment,
        color: Colors.blue,
        onTap: () => _startMockExam(context, ref),
      ),
      _FeatureCard(
        title: '错题回顾',
        subtitle: '',
        icon: Icons.error_outline,
        color: Colors.orange,
        onTap: () => _showComingSoon(context, '错题回顾'),
      ),
      _FeatureCard(
        title: '统计记录',
        subtitle: '',
        icon: Icons.analytics,
        color: Colors.purple,
        onTap: () => _showComingSoon(context, '统计记录'),
      ),
      _FeatureCard(
        title: '题库搜索',
        subtitle: '',
        icon: Icons.search,
        color: Colors.teal,
        onTap: () => _showComingSoon(context, '题库搜索'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4, // 进一步增加宽高比，减少高度
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature);
      },
    );
  }

  // 构建单个功能卡片 - MD3风格
  Widget _buildFeatureCard(_FeatureCard feature) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: feature.color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: feature.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 图标容器 - MD3风格，更紧凑
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  size: 24,
                  color: feature.color.shade700,
                ),
              ),
              const SizedBox(height: 8),
              // 标题
              Text(
                feature.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // 只有当subtitle不为空时才显示
              if (feature.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  feature.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

    // 检查是否有保存的进度
    if (settings.enableProgressSave) {
      final hasSavedProgress = await quizController.hasSavedProgress();
      if (hasSavedProgress && context.mounted) {
        final description = await quizController.getSavedProgressDescription();
        final shouldRestore = await _showRestoreProgressDialog(
          context,
          description,
        );

        if (shouldRestore) {
          final restored = await quizController.restoreProgress();
          if (restored) {
            // 导航到答题页面
            appRouter.goToQuiz();
            return;
          }
        } else {
          // 用户选择不恢复，清除保存的进度
          await quizController.clearSavedProgress();
        }
      }
    }

    // 开始全题库答题，使用用户的选项乱序设置
    quizController.startAllQuestionsQuiz(
      shuffleOptions: settings.shuffleOptions,
    );

    // 导航到答题页面
    appRouter.goToQuiz();
  }

  Future<bool> _showRestoreProgressDialog(
    BuildContext context,
    String? description,
  ) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('恢复进度'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('检测到未完成的答题进度：'),
                const SizedBox(height: 8),
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
        ) ??
        false;
  }

  void _startMockExam(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    final quizController = ref.read(quizControllerProvider.notifier);

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
        final shouldRestore = await _showRestoreBlindTasteProgressDialog(
          context,
          description,
        );

        if (shouldRestore) {
          final restored = await blindTasteController.restoreProgress();
          if (restored) {
            // 导航到品鉴页面
            appRouter.goToBlindTaste();
            return;
          }
        } else {
          // 用户选择不恢复，清除保存的进度
          await blindTasteController.clearSavedProgress();
        }
      }
    }

    // 导航到品鉴页面
    appRouter.goToBlindTaste();
  }

  Future<bool> _showRestoreBlindTasteProgressDialog(
    BuildContext context,
    String? description,
  ) async {
    if (!context.mounted) return false;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('恢复品鉴进度'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('检测到未完成的品鉴进度：'),
                const SizedBox(height: 8),
                Text(
                  description ?? '未知进度',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('是否要继续之前的品鉴？'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('重新开始'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('继续品鉴'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature 功能即将上线，敬请期待！'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
