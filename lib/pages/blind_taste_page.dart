import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blind_taste_model.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../utils/haptic_manager.dart';
import '../router/app_router.dart';

class BlindTastePage extends ConsumerStatefulWidget {
  const BlindTastePage({super.key});

  @override
  ConsumerState<BlindTastePage> createState() => _BlindTastePageState();
}

class _BlindTastePageState extends ConsumerState<BlindTastePage> {
  @override
  void initState() {
    super.initState();
    // 初始化品鉴
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBlindTaste();
    });
  }

  // 统一的按钮样式方法
  ButtonStyle _secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      );

  // 跳过按钮样式（统一样式）
  ButtonStyle _skipButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      );

  // 提交按钮样式（统一样式但颜色不同）
  ButtonStyle _submitButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      );

  Future<void> _initializeBlindTaste() async {
    final settings = ref.read(settingsProvider);
    final blindTasteController = ref.read(blindTasteProvider.notifier);
    final currentState = ref.read(blindTasteProvider);

    // 检查当前状态是否已经有数据（可能已经在首页恢复了进度）
    if (currentState.questionPool.isNotEmpty &&
        currentState.currentItem != null) {
      debugPrint(
        'Blind taste state already initialized, skipping re-initialization',
      );
      return;
    }

    // 检查当前状态是否为空（可能已经被重置）
    if (currentState.questionPool.isEmpty && currentState.currentItem == null) {
      debugPrint('Blind taste state is empty, starting new session');
      // 状态为空，直接开始新的品鉴
      await blindTasteController.startNewTasting();
      return;
    }

    // 检查是否有保存的进度 - 使用和理论题库相同的逻辑
    if (settings.enableProgressSave) {
      final hasSavedProgress = await blindTasteController.hasSavedProgress();
      if (hasSavedProgress && mounted) {
        final description = await blindTasteController
            .getSavedProgressDescription();
        if (!mounted) return;

        // 检查是否是已完成的品鉴练习
        final isCompleted = currentState.isRoundCompleted;

        bool shouldRestore;
        bool? dialogResult;
        if (isCompleted) {
          // 已完成所有品鉴，询问是否重新开始
          dialogResult = await _showRestartCompletedBlindTasteDialog(
            context,
            description,
          );
          if (dialogResult == null) {
            return; // 用户点击关闭按钮
          }
          shouldRestore = dialogResult;

          if (shouldRestore) {
            // 用户选择重新开始，清除旧进度
            await blindTasteController.clearSavedProgress();
            shouldRestore = false; // 设置为false以开始新练习
          } else {
            // 用户选择查看结果，恢复到已完成状态
            shouldRestore = true;
          }
        } else {
          // 未完成的品鉴进度
          if (settings.enableProgressSave &&
              settings.enableDefaultContinueProgress) {
            // 启用自动保存且默认继续进度，不显示对话框
            shouldRestore = true;
          } else {
            // 显示确认对话框
            if (!mounted) return;
            dialogResult = await _showRestoreBlindTasteProgressDialog(
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
          final restored = await blindTasteController.restoreProgress();
          if (restored) {
            debugPrint('Progress restored successfully in page');
            // 成功恢复进度，检查是否需要加载下一题
            final state = ref.read(blindTasteProvider);
            if (state.isCompleted && !state.isRoundCompleted) {
              // 如果当前题已完成但轮次未完成，自动进入下一题
              await blindTasteController.nextQuestion();
            }
            return;
          } else {
            // 恢复失败，清除进度并继续重新开始
            debugPrint('Failed to restore progress, starting new session');
            await blindTasteController.clearSavedProgress();
          }
        } else {
          // 用户选择不恢复进度
          if (isCompleted) {
            // 如果是已完成的进度且用户选择查看结果，不应该清除进度
            // 这种情况在上面已经处理，不会走到这里
          } else {
            // 用户明确选择"重新开始"而不是"继续练习"，才清除进度
            await blindTasteController.clearSavedProgress();
          }
        }
      }
    }

    // 开始新的品鉴练习
    // 先重置状态再开始新的品鉴
    blindTasteController.reset();
    await blindTasteController.startNewTasting();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blindTasteProvider);
    final hapticSettings = ref.watch(hapticSettingsProvider);

    // 更新HapticManager的设置
    HapticManager.updateSettings(hapticEnabled: hapticSettings.hapticEnabled);

    return Scaffold(
      appBar: AppBar(
        title: const Text('酒样练习'),
        centerTitle: true,
        // 使用新的MD3主题，移除自定义背景色
        leading: IconButton(
          onPressed: () => _handleExit(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        actions: [
          if (state.questionPool.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  '${state.completedItemIds.length + 1}/${state.totalItemsInPool}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
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
    final settings = ref.watch(settingsProvider);

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

          // 香型选择（根据设置显示）
          if (settings.enableBlindTasteAroma) _buildAromaSection(state),

          if (settings.enableBlindTasteAroma) const SizedBox(height: 8),

          // 总分调整（根据设置显示）
          if (settings.enableBlindTasteScore) _buildTotalScoreSection(state),

          if (settings.enableBlindTasteScore) const SizedBox(height: 8),

          // 酒度选择（根据设置显示，放在总分下方）
          if (settings.enableBlindTasteAlcohol) _buildAlcoholSection(state),

          if (settings.enableBlindTasteAlcohol) const SizedBox(height: 8),

          // 设备选择（根据设置显示）
          if (settings.enableBlindTasteEquipment) _buildEquipmentSection(state),

          if (settings.enableBlindTasteEquipment) const SizedBox(height: 8),

          // 发酵剂选择（根据设置显示）
          if (settings.enableBlindTasteFermentation)
            _buildFermentationAgentSection(state),

          const SizedBox(height: 16),

          // 操作按钮行
          Row(
            children: [
              // 跳过按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticManager.medium();
                    _skipCurrentItem();
                  },
                  style: _skipButtonStyle(context),
                  child: Text(
                    '跳过',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 提交按钮
              Expanded(
                flex: 2, // 提交按钮占更多空间
                child: ElevatedButton(
                  onPressed: _canSubmit(state, settings)
                      ? () {
                          HapticManager.submitAnswer();
                          _submitAnswer();
                        }
                      : null,
                  style: _submitButtonStyle(context),
                  child: Text(
                    '提交答案',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAromaSection(BlindTasteState state) {
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
                  '香型',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (state.userAnswer.selectedAroma != null)
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
                      state.userAnswer.selectedAroma!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: state.userAnswer.selectedAroma,
              decoration: const InputDecoration(
                hintText: '请选择',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              menuMaxHeight: 300,
              items: BlindTasteOptions.aromaTypes.map((aroma) {
                return DropdownMenuItem(
                  value: aroma,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
                    child: Text(
                      aroma,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  HapticManager.medium();
                  ref.read(blindTasteProvider.notifier).selectAroma(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlcoholSection(BlindTasteState state) {
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
                  '酒度',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (state.userAnswer.selectedAlcoholDegree != null)
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
                      '答案: ${state.userAnswer.selectedAlcoholDegree!.toInt()}°',
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
              children: BlindTasteOptions.alcoholDegrees.map((degree) {
                final isSelected =
                    state.userAnswer.selectedAlcoholDegree == degree;
                return FilterChip(
                  label: Text('${degree.toInt()}°'),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    ref
                        .read(blindTasteProvider.notifier)
                        .selectAlcoholDegree(degree);
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
            const SizedBox(height: 2),
            Row(
              children: [
                // 减分按钮
                IconButton(
                  onPressed: state.userAnswer.selectedTotalScore > 84.0
                      ? () {
                          HapticManager.medium();
                          final newScore =
                              (state.userAnswer.selectedTotalScore - 0.2).clamp(
                                84.0,
                                98.0,
                              );
                          ref
                              .read(blindTasteProvider.notifier)
                              .setTotalScore(newScore);
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  state.userAnswer.selectedTotalScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Slider(
                    value: state.userAnswer.selectedTotalScore.clamp(
                      84.0,
                      98.0,
                    ),
                    min: 84.0,
                    max: 98.0,
                    divisions: 70, // (98-84)/0.2 = 70
                    onChanged: (value) {
                      HapticManager.selection();
                      ref
                          .read(blindTasteProvider.notifier)
                          .setTotalScore(value);
                    },
                  ),
                ),
                const SizedBox(width: 2),
                // 加分按钮
                IconButton(
                  onPressed: state.userAnswer.selectedTotalScore < 98.0
                      ? () {
                          HapticManager.medium();
                          final newScore =
                              (state.userAnswer.selectedTotalScore + 0.2).clamp(
                                84.0,
                                98.0,
                              );
                          ref
                              .read(blindTasteProvider.notifier)
                              .setTotalScore(newScore);
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    padding: const EdgeInsets.all(8),
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
                    HapticManager.medium();
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
                    HapticManager.medium();
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
    final settings = ref.watch(settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // 得分卡片 - 更小更紧凑
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    score >= 80
                        ? Icons.emoji_events
                        : score >= 60
                        ? Icons.thumb_up
                        : Icons.sentiment_neutral,
                    size: 32,
                    color: score >= 80
                        ? Theme.of(context).colorScheme.tertiary
                        : score >= 60
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${score.toStringAsFixed(1)}分',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: score >= 80
                                  ? Theme.of(context).colorScheme.tertiary
                                  : score >= 60
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      Text(
                        score >= 80
                            ? '盲评大师！'
                            : score >= 60
                            ? '盲评达人！'
                            : '继续努力！',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          //酒样信息
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.wine_bar,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 答案对比 - 更清晰的布局
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.compare_arrows,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '答案对比',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 根据设置显示对比结果
                  if (settings.enableBlindTasteAroma)
                    _buildComparisonRow(
                      '香型',
                      state.userAnswer.selectedAroma ?? '未选择',
                      item.aroma,
                    ),
                  if (settings.enableBlindTasteAlcohol)
                    _buildComparisonRow(
                      '酒度',
                      state.userAnswer.selectedAlcoholDegree != null
                          ? '${state.userAnswer.selectedAlcoholDegree!.toInt()}°'
                          : '未选择',
                      '${item.alcoholDegree.toInt()}°',
                    ),
                  if (settings.enableBlindTasteScore)
                    _buildComparisonRow(
                      '总分',
                      state.userAnswer.selectedTotalScore.toStringAsFixed(1),
                      item.totalScore.toStringAsFixed(1),
                    ),
                  if (settings.enableBlindTasteEquipment)
                    _buildComparisonRowForList(
                      '设备',
                      state.userAnswer.selectedEquipment,
                      item.equipment,
                    ),
                  if (settings.enableBlindTasteFermentation)
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

          // 操作按钮 - 只保留下一题按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticManager.medium();
                _handleNextQuestion();
              },
              style: _secondaryButtonStyle(context),
              child: Text(
                state.isRoundCompleted ? '开始新一轮' : '下一题',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isCorrect
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCorrect
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 状态图标和标签
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCorrect
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),

          // 用户答案
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCorrect
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4)
                      : Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                userAnswer.isEmpty ? '未选择' : userAnswer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCorrect
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),

          // 正确答案
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                correctAnswer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isCorrect
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCorrect
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 状态图标和标签
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isCorrect
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.close,
              size: 10,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),

          // 用户答案
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isCorrect
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.4)
                      : Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: userAnswer.isEmpty
                  ? Text(
                      '未选择',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Wrap(
                      spacing: 2,
                      runSpacing: 2,
                      children: userAnswer
                          .map(
                            (item) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                item,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isCorrect
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onErrorContainer,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 10,
                                    ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),

          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),

          // 正确答案
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                children: correctAnswer
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit(BlindTasteState state, settings) {
    // 检查启用的品鉴项目是否都已选择
    bool canSubmit = true;

    if (settings.enableBlindTasteAroma) {
      canSubmit = canSubmit && state.userAnswer.selectedAroma != null;
    }

    if (settings.enableBlindTasteAlcohol) {
      canSubmit = canSubmit && state.userAnswer.selectedAlcoholDegree != null;
    }

    // 总分、设备和发酵剂不是必需的，用户可以选择不填写

    return canSubmit;
  }

  void _submitAnswer() {
    ref.read(blindTasteProvider.notifier).submitAnswer();
  }

  void _skipCurrentItem() {
    ref.read(blindTasteProvider.notifier).skipCurrentItem();
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
            // 只保留开始新一轮按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticManager.medium();
                  _handleNextQuestion();
                },
                style: _secondaryButtonStyle(context),
                child: Text(
                  '开始新一轮',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showRestoreBlindTasteProgressDialog(
    BuildContext context,
    String? description, {
    bool isAutoSaveDisabled = false,
  }) async {
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
              if (isAutoSaveDisabled) ...[
                const Text('检测到您已关闭自动保存功能，但仍有之前保存的进度：'),
                const SizedBox(height: 8),
              ] else ...[
                const Text('检测到未完成的酒样练习进度：'),
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

  Future<bool?> _showRestartCompletedBlindTasteDialog(
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
              const Text('酒样练习已完成'),
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
              const Text('您已完成了所有酒样练习：'),
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
