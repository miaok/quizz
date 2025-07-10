import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blind_taste_model.dart';
import '../providers/blind_taste_provider.dart';
import '../router/app_router.dart';
import '../utils/system_ui_manager.dart';

class BlindTastePage extends ConsumerStatefulWidget {
  const BlindTastePage({super.key});

  @override
  ConsumerState<BlindTastePage> createState() => _BlindTastePageState();
}

class _BlindTastePageState extends ConsumerState<BlindTastePage> {
  @override
  void initState() {
    super.initState();
    // 设置系统UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemUIManager.setQuizPageUI();
      // 只有在没有当前品鉴项目时才开始新的品鉴
      final currentState = ref.read(blindTasteProvider);
      if (currentState.currentItem == null) {
        ref.read(blindTasteProvider.notifier).startNewTasting();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blindTasteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('盲评大师'),
            if (state.questionPool.isNotEmpty)
              Text(
                '进度: ${state.completedItemIds.length}/${state.totalItemsInPool}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        centerTitle: true,
        // 使用新的MD3主题，移除自定义背景色
        leading: IconButton(
          onPressed: () => _handleExit(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
      ),
      body: SafeArea(bottom: false, child: _buildBody(state)),
    );
  }

  Widget _buildBody(BlindTasteState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载品鉴数据...'),
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(blindTasteProvider.notifier).startNewTasting(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.isRoundCompleted) {
      return _buildRoundCompletedView(state);
    }

    if (state.currentItem == null) {
      return const Center(child: Text('没有可用的品鉴数据'));
    }

    if (state.isCompleted) {
      return _buildResultView(state);
    }

    return _buildTastingView(state);
  }

  Widget _buildTastingView(BlindTasteState state) {
    final item = state.currentItem!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 题目标题
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.wine_bar,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '这一杯是【${item.name}】',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 香型和酒度选择（一行显示）
          _buildAromaAndAlcoholSection(state),

          const SizedBox(height: 8),

          // 总分调整
          _buildTotalScoreSection(state),

          const SizedBox(height: 8),

          // 设备选择
          _buildEquipmentSection(state),

          const SizedBox(height: 8),

          // 发酵剂选择
          _buildFermentationAgentSection(state),

          const SizedBox(height: 16),

          // 提交按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit(state) ? () => _submitAnswer() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                '提交答案',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAromaAndAlcoholSection(BlindTasteState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // 香型选择
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '香型',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (state.userAnswer.selectedAroma != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            state.userAnswer.selectedAroma!,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: state.userAnswer.selectedAroma,
                    decoration: const InputDecoration(
                      hintText: '请选择',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ), // 增加输入框内边距
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 16, // 设置选中项的字体大小
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    dropdownColor: Theme.of(
                      context,
                    ).colorScheme.surface, // 设置下拉菜单背景色
                    menuMaxHeight: 300, // 限制下拉菜单最大高度
                    items: BlindTasteOptions.aromaTypes.map((aroma) {
                      return DropdownMenuItem(
                        value: aroma,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ), // 自定义上下间距
                          child: Text(
                            aroma,
                            style: TextStyle(
                              fontSize: 14, // 自定义字体大小
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(blindTasteProvider.notifier)
                            .selectAroma(value);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 酒度选择
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '酒度',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (state.userAnswer.selectedAlcoholDegree != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${state.userAnswer.selectedAlcoholDegree}°',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<double>(
                    value: state.userAnswer.selectedAlcoholDegree,
                    decoration: const InputDecoration(
                      hintText: '请选择',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ), // 增加输入框内边距
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 14, // 设置选中项的字体大小
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    dropdownColor: Theme.of(
                      context,
                    ).colorScheme.surface, // 设置下拉菜单背景色
                    menuMaxHeight: 300, // 限制下拉菜单最大高度
                    items: BlindTasteOptions.alcoholDegrees.map((degree) {
                      return DropdownMenuItem(
                        value: degree,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 4,
                          ), // 自定义上下间距
                          child: Text(
                            '$degree°',
                            style: TextStyle(
                              fontSize: 14, // 自定义字体大小
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(blindTasteProvider.notifier)
                            .selectAlcoholDegree(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalScoreSection(BlindTasteState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '总分',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '答案: ${state.userAnswer.selectedTotalScore.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () => ref
                      .read(blindTasteProvider.notifier)
                      .adjustTotalScore(-1),
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer,
                    minimumSize: const Size(36, 36),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(blindTasteProvider.notifier)
                      .adjustTotalScore(-0.2),
                  icon: const Icon(Icons.remove, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.5),
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.userAnswer.selectedTotalScore.toStringAsFixed(1),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(blindTasteProvider.notifier)
                      .adjustTotalScore(0.2),
                  icon: const Icon(Icons.add, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    minimumSize: const Size(32, 32),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(blindTasteProvider.notifier).adjustTotalScore(1),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    minimumSize: const Size(36, 36),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentSection(BlindTasteState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '设备',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (state.userAnswer.selectedEquipment.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '答案: ${state.userAnswer.selectedEquipment.join(', ')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: BlindTasteOptions.equipmentTypes.map((equipment) {
                final isSelected = state.userAnswer.selectedEquipment.contains(
                  equipment,
                );
                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (_) {
                    ref
                        .read(blindTasteProvider.notifier)
                        .toggleEquipment(equipment);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  showCheckmark: false, // 隐藏对勾
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFermentationAgentSection(BlindTasteState state) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '发酵剂',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (state.userAnswer.selectedFermentationAgent.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '答案: ${state.userAnswer.selectedFermentationAgent.join(', ')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: BlindTasteOptions.fermentationAgents.map((agent) {
                final isSelected = state.userAnswer.selectedFermentationAgent
                    .contains(agent);
                return FilterChip(
                  label: Text(agent),
                  selected: isSelected,
                  onSelected: (_) {
                    ref
                        .read(blindTasteProvider.notifier)
                        .toggleFermentationAgent(agent);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(BlindTasteState state) {
    final item = state.currentItem!;
    final score = state.finalScore!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // 得分卡片
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Icon(
                    score >= 80
                        ? Icons.emoji_events
                        : score >= 60
                        ? Icons.thumb_up
                        : Icons.sentiment_neutral,
                    size: 48,
                    color: score >= 80
                        ? Theme.of(context).colorScheme.tertiary
                        : score >= 60
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),

                  const SizedBox(height: 6),
                  Text(
                    '${score.toStringAsFixed(1)}分',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: score >= 80
                          ? Theme.of(context).colorScheme.tertiary
                          : score >= 60
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    score >= 80
                        ? '盲评大师！'
                        : score >= 60
                        ? '盲评达人！'
                        : '你太菜了！',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 答案对比
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '答案对比',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonRow(
                    '香型',
                    state.userAnswer.selectedAroma ?? '未选择',
                    item.aroma,
                  ),
                  _buildComparisonRow(
                    '酒度',
                    state.userAnswer.selectedAlcoholDegree != null
                        ? '${state.userAnswer.selectedAlcoholDegree}°'
                        : '未选择',
                    '${item.alcoholDegree}°',
                  ),
                  _buildComparisonRow(
                    '总分',
                    state.userAnswer.selectedTotalScore.toStringAsFixed(1),
                    item.totalScore.toStringAsFixed(1),
                  ),
                  _buildComparisonRowForList(
                    '设备',
                    state.userAnswer.selectedEquipment,
                    item.equipment,
                  ),
                  _buildComparisonRowForList(
                    '发酵剂',
                    state.userAnswer.selectedFermentationAgent,
                    item.fermentationAgent,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleNextQuestion(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(state.isRoundCompleted ? '开始新一轮' : '下一题'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => appRouter.goToHome(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('返回首页'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String userAnswer,
    String correctAnswer,
  ) {
    final isCorrect = userAnswer == correctAnswer;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isCorrect
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '你的答案: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Text(
                        userAnswer.isEmpty ? '未选择' : userAnswer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isCorrect
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '正确答案: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Text(
                        correctAnswer,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRowForList(
    String label,
    List<String> userAnswer,
    List<String> correctAnswer,
  ) {
    // 使用Set比较，忽略顺序
    final userSet = userAnswer.toSet();
    final correctSet = correctAnswer.toSet();
    final isCorrect =
        userSet.length == correctSet.length && userSet.containsAll(correctSet);

    final userAnswerText = userAnswer.isEmpty ? '未选择' : userAnswer.join(', ');
    final correctAnswerText = correctAnswer.join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isCorrect
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '你的答案: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Text(
                        userAnswerText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isCorrect
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '正确答案: ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Text(
                        correctAnswerText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit(BlindTasteState state) {
    return state.userAnswer.selectedAroma != null &&
        state.userAnswer.selectedAlcoholDegree != null;
  }

  void _submitAnswer() {
    ref.read(blindTasteProvider.notifier).submitAnswer();
  }

  void _handleNextQuestion() {
    final state = ref.read(blindTasteProvider);
    if (state.isRoundCompleted) {
      // 开始新一轮
      ref.read(blindTasteProvider.notifier).startNewRound();
    } else {
      // 下一题
      ref.read(blindTasteProvider.notifier).nextQuestion();
    }
  }

  void _handleExit(BuildContext context) {
    // 品鉴模式：自动保存进度并退出
    // 进度会在BlindTasteNotifier中自动保存
    ref.read(blindTasteProvider.notifier).reset();
    appRouter.goToHome();
  }

  Widget _buildRoundCompletedView(BlindTasteState state) {
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
              '恭喜完成一轮品鉴！',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '您已完成 ${state.totalItemsInPool} 道品鉴题目',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => appRouter.goToHome(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('返回首页'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleNextQuestion(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('开始新一轮'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
