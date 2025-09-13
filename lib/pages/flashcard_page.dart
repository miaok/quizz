import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/flashcard_provider.dart';
import '../providers/settings_provider.dart';
import '../models/flashcard_model.dart';

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
  late Animation<double> _scaleAnimation;

  // 动画方向：-1表示向左，1表示向右，0表示无方向
  double _animationDirection = 0;

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
    super.dispose();
  }

  Future<void> _initializeFlashcards() async {
    final settings = ref.read(settingsProvider);
    final flashcardController = ref.read(flashcardProvider.notifier);

    // 检查是否有保存的进度
    if (settings.enableProgressSave) {
      final hasSavedProgress = await flashcardController.hasSavedProgress();
      if (hasSavedProgress && mounted) {
        final description = await flashcardController
            .getSavedProgressDescription();
        if (!mounted) return;

        bool shouldRestore;
        if (settings.enableDefaultContinueProgress) {
          // 默认继续进度，不显示对话框
          shouldRestore = true;
        } else {
          // 显示确认对话框
          shouldRestore = await _showRestoreProgressDialog(description);
        }

        if (shouldRestore) {
          final restored = await flashcardController.restoreProgress(
            randomOrder: settings.enableFlashcardRandomOrder,
          );
          if (!restored && mounted) {
            // 清除旧进度并重新开始
            await flashcardController.clearProgress();
            await flashcardController.loadFlashcards(
              randomOrder: settings.enableFlashcardRandomOrder,
            );
          }
        } else {
          // 用户选择不恢复，清除保存的进度并重新开始
          await flashcardController.clearProgress();
          await flashcardController.loadFlashcards(
            randomOrder: settings.enableFlashcardRandomOrder,
          );
        }
      } else {
        // 没有保存的进度，直接开始
        await flashcardController.loadFlashcards(
          randomOrder: settings.enableFlashcardRandomOrder,
        );
      }
    } else {
      // 未启用进度保存，直接开始
      await flashcardController.loadFlashcards(
        randomOrder: settings.enableFlashcardRandomOrder,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final flashcardState = ref.watch(flashcardProvider);
    final flashcardController = ref.read(flashcardProvider.notifier);

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
          title: const Text('酒样记忆'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (flashcardState.items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    flashcardState.progressDescription,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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

              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(shuffleOffset, 0.0, 0.0)
                  ..scale(scale)
                  ..rotateZ(rotation),
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
        _buildInfoTag('香型', card.item.aroma, Icons.local_florist),
        const SizedBox(height: 12),
        _buildInfoTag('酒度', '${card.item.alcoholDegree}°', Icons.thermostat),
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
                  ? () => _previousCard(controller)
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
              onPressed: state.hasNext ? () => _nextCard(controller) : null,
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

  Future<bool> _showRestoreProgressDialog(String description) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复进度'),
        content: Text('发现保存的进度：\n$description\n\n是否继续上次的学习？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('重新开始'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('继续学习'),
          ),
        ],
      ),
    );
    return result ?? false;
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
                onPressed: () => Navigator.of(context).pop(),
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
}
