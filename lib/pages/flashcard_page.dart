import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flashcard_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../models/flashcard_model.dart';
import '../utils/haptic_manager.dart';
import '../widgets/answer_card.dart';

/// Flashcard页面的答题卡项目实现
class FlashcardAnswerCardItem implements AnswerCardItem {
  final int index;
  final FlashcardState state;

  FlashcardAnswerCardItem(this.index, this.state);

  @override
  String get id => state.items.isNotEmpty && index < state.items.length
      ? state.items[index].id.toString()
      : index.toString();

  @override
  int get displayNumber => index + 1;

  @override
  bool get isCurrent => index == state.currentIndex;

  @override
  bool get isCompleted => state.viewedCardIds.contains(
    state.items.isNotEmpty && index < state.items.length
        ? state.items[index].id
        : -1,
  );

  @override
  bool get hasAnswer => isCompleted;
}

class FlashcardPage extends ConsumerStatefulWidget {
  const FlashcardPage({super.key});

  @override
  ConsumerState<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends ConsumerState<FlashcardPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shuffleController;
  late Animation<double> _shuffleAnimation;
  late ScrollController _flashcardSummaryScrollController;
  late Animation<double> _scaleAnimation;

  // 动画方向：-1表示向左，1表示向右，0表示无方向
  double _animationDirection = 0;

  // 防止重复初始化的标志
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );

    // 洗牌动画控制器 - 快速切卡效果
    _shuffleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _shuffleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shuffleController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _shuffleController, curve: Curves.easeInOut),
    );

    // 初始化闪卡答题卡滚动控制器
    _flashcardSummaryScrollController = ScrollController();

    // 初始化闪卡数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFlashcards();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _flipController.dispose();
    _slideController.dispose();
    _shuffleController.dispose();
    _flashcardSummaryScrollController.dispose();
    _isInitialized = false; // 重置初始化标志
    _isInitializing = false;
    super.dispose();
  }

  Future<void> _initializeFlashcards() async {
    // 防止重复初始化
    if (_isInitialized || _isInitializing) {
      debugPrint('Flashcard initialization already in progress or completed');
      return;
    }

    _isInitializing = true;

    try {
      final flashcardController = ref.read(flashcardProvider.notifier);
      final currentState = ref.read(flashcardProvider);

      // 检查当前状态是否已经有数据（可能已经在首页恢复了进度）
      if (currentState.items.isNotEmpty && !currentState.isRoundCompleted) {
        debugPrint(
          'Flashcard state already initialized, skipping re-initialization',
        );
        _isInitialized = true;
        return;
      }

      // 检查当前状态是否为空（需要加载新数据）
      if (currentState.items.isEmpty) {
        debugPrint('Flashcard state is empty, loading new flashcards');
        // 状态为空，加载新的闪卡
        await flashcardController.loadFlashcards();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing flashcards: $e');
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flashcardState = ref.watch(flashcardProvider);
    final flashcardController = ref.read(flashcardProvider.notifier);

    // 监听触感设置变化并更新HapticManager
    ref.listen<HapticSettings>(hapticSettingsProvider, (previous, current) {
      HapticManager.updateSettings(hapticEnabled: current.hapticEnabled);
    });

    // 初始化时也要更新设置
    final hapticSettings = ref.read(hapticSettingsProvider);
    HapticManager.updateSettings(hapticEnabled: hapticSettings.hapticEnabled);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // 自动保存进度，无需确认对话框
        if (didPop) {
          _handleBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('酒样闪卡'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (flashcardState.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    HapticManager.openQuestionCard();
                    // 显示答题卡组件
                    _showFlashcardSummary(context, flashcardState);
                  },
                  child: Center(
                    child: Text(
                      flashcardState.progressDescription,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(child: _buildBody(flashcardState, flashcardController)),
      ),
    );
  }

  Widget _buildBody(FlashcardState state, FlashcardController controller) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载闪卡中...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.error!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.loadFlashcards(),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flip_to_front_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('暂无闪卡数据', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '请先导入品鉴数据',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.loadFlashcards(),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    // 轮次完成状态
    if (state.isRoundCompleted) {
      return _buildRoundCompletedView(state, controller);
    }

    return Column(
      children: [
        // 进度指示器
        if (state.totalCards > 1) _buildProgressIndicator(state),

        // 闪卡区域
        Expanded(child: _buildFlashcardArea(state, controller)),

        // 控制按钮
        _buildControlButtons(state, controller),
      ],
    );
  }

  Widget _buildProgressIndicator(FlashcardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: state.progress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcardArea(
    FlashcardState state,
    FlashcardController controller,
  ) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 350, maxHeight: 500),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: GestureDetector(
          onTap: () {
            // 检查组件是否仍然挂载
            if (!mounted) return;

            // 触发闪卡翻转震动反馈
            HapticManager.flipCard();

            controller.flipCard();
            if (state.currentCard?.currentSide == FlashcardSide.front) {
              _flipController.forward();
            } else {
              _flipController.reverse();
            }
          },
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              // 向右滑动 - 上一张
              _previousCard(controller);
            } else if (details.primaryVelocity! < 0) {
              // 向左滑动 - 下一张
              _nextCard(controller);
            }
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _flipAnimation,
              _fadeAnimation,
              _shuffleAnimation,
            ]),
            builder: (context, child) {
              final isShowingFront = _flipAnimation.value < 0.5;

              // 洗牌动画效果 - 根据方向决定偏移
              final shuffleOffset =
                  _shuffleAnimation.value * 20 * _animationDirection; // 方向性水平偏移
              final scale = _scaleAnimation.value;
              final rotation =
                  _shuffleAnimation.value *
                  0.1 *
                  _animationDirection; // 方向性轻微旋转

              return Transform.translate(
                offset: Offset(shuffleOffset, 0.0),
                child: Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_flipAnimation.value * 3.14159),
                        child: isShowingFront
                            ? _buildCardFront(state.currentCard!)
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(3.14159),
                                child: _buildCardBack(state.currentCard!),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront(FlashcardModel card) {
    return Card(
      elevation: 12,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wine_bar,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '这杯酒是',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                card.item.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '点击查看答案',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildCardBack(FlashcardModel card) {
    return Card(
      elevation: 12,
      shadowColor: Theme.of(
        context,
      ).colorScheme.secondary.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.secondaryContainer,
              Theme.of(
                context,
              ).colorScheme.secondaryContainer.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 酒样名称
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Text(
                card.item.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // 详细信息标签
            _buildCompactInfoTags(card),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swipe,
                    size: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '滑动切换卡片',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
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

  Widget _buildCompactInfoTags(FlashcardModel card) {
    return Column(
      children: [
        _buildInfoTag(
          '酒度',
          '${card.item.alcoholDegree.round()}°',
          Icons.thermostat,
        ),
        const SizedBox(height: 12),
        _buildInfoTag('总分', '${card.item.totalScore}分', Icons.star),
        if (card.item.equipment.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoTag('设备', card.item.equipment.join('、'), Icons.build),
        ],
        if (card.item.fermentationAgent.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoTag(
            '发酵剂',
            card.item.fermentationAgent.join('、'),
            Icons.science,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoTag(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons(
    FlashcardState state,
    FlashcardController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 上一张按钮
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.hasPrevious
                  ? () {
                      HapticManager.medium();
                      _previousCard(controller);
                    }
                  : null,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('上一张'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 翻转按钮
          ElevatedButton(
            onPressed: () {
              // 触发闪卡翻转震动反馈
              HapticManager.flipCard();

              controller.flipCard();
              if (state.currentCard?.currentSide == FlashcardSide.front) {
                _flipController.forward();
              } else {
                _flipController.reverse();
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              shape: const CircleBorder(),
            ),
            child: const Icon(Icons.flip_to_front),
          ),

          const SizedBox(width: 16),

          // 下一张按钮
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.hasNext
                  ? () {
                      HapticManager.medium();
                      _nextCard(controller);
                    }
                  : null,
              icon: const Text('下一张'),
              label: const Icon(Icons.arrow_forward_ios, size: 16),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousCard(FlashcardController controller) async {
    // 检查组件是否仍然挂载
    if (!mounted) return;

    // 触发闪卡切换震动反馈
    HapticManager.switchQuestion();

    // 设置向左动画方向
    _animationDirection = -1;

    // 快速洗牌动画
    await _shuffleController.forward();

    // 再次检查组件是否仍然挂载
    if (!mounted) return;

    controller.previousCard();
    _flipController.reset();

    await _shuffleController.reverse();

    // 重置动画方向
    if (mounted) {
      _animationDirection = 0;
    }
  }

  void _nextCard(FlashcardController controller) async {
    // 检查组件是否仍然挂载
    if (!mounted) return;

    // 触发闪卡切换震动反馈
    HapticManager.switchQuestion();

    // 设置向右动画方向
    _animationDirection = 1;

    // 快速洗牌动画
    await _shuffleController.forward();

    // 再次检查组件是否仍然挂载
    if (!mounted) return;

    controller.nextCard();
    _flipController.reset();

    await _shuffleController.reverse();

    // 重置动画方向
    if (mounted) {
      _animationDirection = 0;
    }
  }

  void _handleBackPressed() {
    // 自动保存进度，无需确认对话框
    // 进度保存由Provider的_autoSaveProgress方法自动处理
    // 直接退出即可
  }

  /// 构建轮次完成视图
  Widget _buildRoundCompletedView(
    FlashcardState state,
    FlashcardController controller,
  ) {
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
              '恭喜完成一轮学习！',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '您已学完 ${state.totalCards} 张闪卡',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticManager.medium();
                  await controller.startNewRound();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('开始新一轮'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticManager.medium();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.home),
                label: const Text('返回首页'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlashcardSummary(BuildContext context, FlashcardState state) {
    final items = List.generate(
      state.items.length,
      (index) => FlashcardAnswerCardItem(index, state),
    );

    final config = AnswerCardConfig(
      title: '闪卡答题卡',
      icon: Icons.card_membership,
      progressTextBuilder: (completedCount, totalCount) =>
          '${state.viewedCardIds.length}/$totalCount',
      stats: [
        AnswerCardStats(
          label: '当前',
          count: state.currentIndex + 1,
          color: Theme.of(context).colorScheme.secondary,
        ),
        AnswerCardStats(
          label: '已学',
          count: state.viewedCardIds.length,
          color: Theme.of(context).colorScheme.primary,
        ),
        AnswerCardStats(
          label: '未学',
          count: state.items.length - state.viewedCardIds.length,
          color: Theme.of(context).colorScheme.outline,
        ),
      ],
      onItemTapped: (index) {
        final controller = ref.read(flashcardProvider.notifier);
        controller.goToCard(index);
      },
      scrollController: _flashcardSummaryScrollController,
    );

    AnswerCardHelper.showAnswerCard(context, items, config);

    // 答题卡展开时，延迟滚动到当前题目位置
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        AnswerCardHelper.scrollToCurrentItem(
          _flashcardSummaryScrollController,
          state.currentIndex,
          context: this.context,
        );
      }
    });
  }
}
