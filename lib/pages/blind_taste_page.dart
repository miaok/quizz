import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blind_taste_model.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../utils/haptic_manager.dart';
import '../router/app_router.dart';
import '../widgets/answer_card.dart';

/// BlindTaste页面的答题卡项目实现
class BlindTasteAnswerCardItem implements AnswerCardItem {
  final int index;
  final BlindTasteState state;

  BlindTasteAnswerCardItem(this.index, this.state);

  @override
  String get id =>
      state.questionPool.isNotEmpty && index < state.questionPool.length
      ? state.questionPool[index].id.toString()
      : index.toString();

  @override
  int get displayNumber => index + 1;

  @override
  bool get isCurrent => index == state.currentIndex;

  @override
  bool get isCompleted => state.completedItemIds.contains(
    state.questionPool.isNotEmpty && index < state.questionPool.length
        ? state.questionPool[index].id
        : -1,
  );

  @override
  bool get hasAnswer {
    if (state.questionPool.isEmpty || index >= state.questionPool.length)
      return false;
    final itemId = state.questionPool[index].id;
    final answer = state.savedAnswers[itemId];
    if (answer == null) return false;

    final defaultAnswer = BlindTasteAnswer();
    return answer.selectedAroma != defaultAnswer.selectedAroma ||
        answer.selectedAlcoholDegree != defaultAnswer.selectedAlcoholDegree ||
        answer.selectedTotalScore != defaultAnswer.selectedTotalScore ||
        answer.selectedEquipment.isNotEmpty ||
        answer.selectedFermentationAgent.isNotEmpty;
  }
}

class BlindTastePage extends ConsumerStatefulWidget {
  const BlindTastePage({super.key});

  @override
  ConsumerState<BlindTastePage> createState() => _BlindTastePageState();
}

class _BlindTastePageState extends ConsumerState<BlindTastePage> {
  late ScrollController _blindTasteSummaryScrollController;

  // 答案检查状态
  bool _isChecked = false;
  bool _isCorrect = false;

  // 各个组件的检查结果（保持到下次检查）
  bool? _lastAlcoholResult;
  bool? _lastTotalScoreResult;
  bool? _lastEquipmentResult;
  bool? _lastFermentationResult;

  @override
  void initState() {
    super.initState();
    _blindTasteSummaryScrollController = ScrollController();
    // 初始化品鉴
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBlindTaste();
    });
  }

  @override
  void dispose() {
    _blindTasteSummaryScrollController.dispose();
    super.dispose();
  }

  // 统一的按钮样式方法
  ButtonStyle _secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      );

  // 重置按钮样式（统一样式）
  ButtonStyle _resetButtonStyle(BuildContext context) =>
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
              child: GestureDetector(
                onTap: () {
                  HapticManager.medium();
                  _showBlindTasteSummary(context, state);
                },
                child: Center(
                  child: Text(
                    '${state.currentIndex + 1}/${state.totalItemsInPool}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
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
          // if (settings.enableBlindTasteAromaForced) _buildAromaSection(state),

          // if (settings.enableBlindTasteAromaForced) const SizedBox(height: 8),

          // 总分调整（根据设置显示）
          if (settings.enableBlindTasteScore) _buildTotalScoreSection(state),

          if (settings.enableBlindTasteScore) const SizedBox(height: 6),

          // 酒度选择（根据设置显示，放在总分下方）
          if (settings.enableBlindTasteAlcohol) _buildAlcoholSection(state),

          if (settings.enableBlindTasteAlcohol) const SizedBox(height: 6),

          // 设备选择（根据设置显示）
          if (settings.enableBlindTasteEquipment) _buildEquipmentSection(state),

          if (settings.enableBlindTasteEquipment) const SizedBox(height: 6),

          // 发酵剂选择（根据设置显示）
          if (settings.enableBlindTasteFermentation)
            _buildFermentationAgentSection(state),

          const SizedBox(height: 12),

          // 操作按钮行
          Row(
            children: [
              // 重置按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticManager.medium();
                    _resetCurrentAnswer();
                  },
                  style: _resetButtonStyle(context),
                  child: Text(
                    '重置',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 检查答案按钮
              Expanded(
                flex: 2, // 检查按钮占更多空间
                child: ElevatedButton(
                  onPressed: _canSubmit(state, settings)
                      ? () {
                          HapticManager.submitAnswer();
                          _checkAnswer();
                        }
                      : null,
                  style: _submitButtonStyle(context),
                  child: Text(
                    _isChecked && _isCorrect ? '下一题' : '检查答案',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Widget _buildAromaSection(BlindTasteState state) {
  //   return Card(
  //     elevation: 1,
  //     child: Padding(
  //       padding: const EdgeInsets.all(10.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Text(
  //                 '香型',
  //                 style: Theme.of(
  //                   context,
  //                 ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
  //               ),
  //               const Spacer(),
  //               if (state.userAnswer.selectedAroma != null)
  //                 Container(
  //                   padding: const EdgeInsets.symmetric(
  //                     horizontal: 6,
  //                     vertical: 2,
  //                   ),
  //                   decoration: BoxDecoration(
  //                     color: Theme.of(context).colorScheme.primaryContainer,
  //                     borderRadius: BorderRadius.circular(6),
  //                   ),
  //                   child: Text(
  //                     state.userAnswer.selectedAroma!,
  //                     style: TextStyle(
  //                       color: Theme.of(context).colorScheme.onPrimaryContainer,
  //                       fontSize: 10,
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //           const SizedBox(height: 4),
  //           DropdownButtonFormField<String>(
  //             initialValue: state.userAnswer.selectedAroma,
  //             decoration: const InputDecoration(
  //               hintText: '请选择',
  //               border: OutlineInputBorder(),
  //               contentPadding: EdgeInsets.symmetric(
  //                 horizontal: 8,
  //                 vertical: 8,
  //               ),
  //               isDense: true,
  //             ),
  //             style: TextStyle(
  //               fontSize: 16,
  //               color: Theme.of(context).colorScheme.onSurface,
  //             ),
  //             dropdownColor: Theme.of(context).colorScheme.surface,
  //             menuMaxHeight: 300,
  //             items: BlindTasteOptions.aromaTypes.map((aroma) {
  //               return DropdownMenuItem(
  //                 value: aroma,
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                     vertical: 2,
  //                     horizontal: 4,
  //                   ),
  //                   child: Text(
  //                     aroma,
  //                     style: TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                       color: Theme.of(context).colorScheme.onSurface,
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             }).toList(),
  //             onChanged: (value) {
  //               if (value != null) {
  //                 HapticManager.medium();
  //                 ref.read(blindTasteProvider.notifier).selectAroma(value);
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
                if (_lastAlcoholResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _lastAlcoholResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _lastAlcoholResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Wrap(
              spacing: 6,
              runSpacing: -6, // 减小行间距
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
                if (_lastTotalScoreResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _lastTotalScoreResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _lastTotalScoreResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
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
                if (_lastEquipmentResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _lastEquipmentResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _lastEquipmentResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Wrap(
              spacing: 6,
              runSpacing: -6, // 减小行间距
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
                if (_lastFermentationResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _lastFermentationResult!
                          ? Colors.green.withValues(alpha: 0.8)
                          : Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _lastFermentationResult! ? '正确' : '错误',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 0),
            Wrap(
              spacing: 8,
              runSpacing: 4, // 减小行间距
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

  bool _canSubmit(BlindTasteState state, settings) {
    // 检查启用的品鉴项目是否都已选择
    bool canSubmit = true;

    if (settings.enableBlindTasteAromaForced) {
      canSubmit = canSubmit && state.userAnswer.selectedAroma != null;
    }

    if (settings.enableBlindTasteAlcohol) {
      canSubmit = canSubmit && state.userAnswer.selectedAlcoholDegree != null;
    }

    // 总分、设备和发酵剂不是必需的，用户可以选择不填写

    return canSubmit;
  }

  void _checkAnswer() {
    if (!_isChecked) {
      // 第一次检查或重新检查，计算正确性
      _performAnswerCheck();
    } else {
      // 已检查过
      if (_isCorrect) {
        // 答对了，进入下一题
        _nextQuestion();
      } else {
        // 答错了，重新检查当前答案
        _performAnswerCheck();
      }
    }
  }

  void _performAnswerCheck() {
    final state = ref.read(blindTasteProvider);
    final settings = ref.read(settingsProvider);

    if (state.currentItem == null) return;

    bool isCorrect = true;

    // 检查酒度
    if (settings.enableBlindTasteAlcohol) {
      isCorrect = isCorrect && _isCorrectAlcohol(state);
    }

    // 检查总分
    if (settings.enableBlindTasteScore) {
      isCorrect = isCorrect && _isCorrectTotalScore(state);
    }

    // 检查设备
    if (settings.enableBlindTasteEquipment &&
        state.userAnswer.selectedEquipment.isNotEmpty) {
      isCorrect = isCorrect && _isCorrectEquipment(state);
    }

    // 检查发酵剂
    if (settings.enableBlindTasteFermentation &&
        state.userAnswer.selectedFermentationAgent.isNotEmpty) {
      isCorrect = isCorrect && _isCorrectFermentation(state);
    }

    // 保存各个组件的检查结果
    if (settings.enableBlindTasteAlcohol) {
      _lastAlcoholResult = _isCorrectAlcohol(state);
    }
    if (settings.enableBlindTasteScore) {
      _lastTotalScoreResult = _isCorrectTotalScore(state);
    }
    if (settings.enableBlindTasteEquipment &&
        state.userAnswer.selectedEquipment.isNotEmpty) {
      _lastEquipmentResult = _isCorrectEquipment(state);
    }
    if (settings.enableBlindTasteFermentation &&
        state.userAnswer.selectedFermentationAgent.isNotEmpty) {
      _lastFermentationResult = _isCorrectFermentation(state);
    }

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrect;
    });
  }

  bool _isCorrectAlcohol(BlindTasteState state) {
    if (state.currentItem == null ||
        state.userAnswer.selectedAlcoholDegree == null) {
      return false;
    }
    return (state.userAnswer.selectedAlcoholDegree! -
                state.currentItem!.alcoholDegree)
            .abs() <=
        1.0;
  }

  bool _isCorrectTotalScore(BlindTasteState state) {
    if (state.currentItem == null) {
      return false;
    }
    return state.userAnswer.selectedTotalScore == state.currentItem!.totalScore;
  }

  bool _isCorrectEquipment(BlindTasteState state) {
    if (state.currentItem == null) {
      return false;
    }
    final userSet = state.userAnswer.selectedEquipment.toSet();
    final correctSet = state.currentItem!.equipment.toSet();
    return userSet.length == correctSet.length &&
        userSet.containsAll(correctSet);
  }

  bool _isCorrectFermentation(BlindTasteState state) {
    if (state.currentItem == null) {
      return false;
    }
    final userSet = state.userAnswer.selectedFermentationAgent.toSet();
    final correctSet = state.currentItem!.fermentationAgent.toSet();
    return userSet.length == correctSet.length &&
        userSet.containsAll(correctSet);
  }

  void _nextQuestion() {
    setState(() {
      _isChecked = false;
      _isCorrect = false;
      // 重置所有检查结果
      _lastAlcoholResult = null;
      _lastTotalScoreResult = null;
      _lastEquipmentResult = null;
      _lastFermentationResult = null;
    });

    ref.read(blindTasteProvider.notifier).skipCurrentItem();
    ref.read(blindTasteProvider.notifier).nextQuestion();
  }

  void _resetCurrentAnswer() {
    setState(() {
      _isChecked = false;
      _isCorrect = false;
      // 重置所有检查结果
      _lastAlcoholResult = null;
      _lastTotalScoreResult = null;
      _lastEquipmentResult = null;
      _lastFermentationResult = null;
    });
    // 重置用户答案到默认状态
    ref.read(blindTasteProvider.notifier).resetCurrentAnswer();
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

  // 显示酒样练习答题卡
  void _showBlindTasteSummary(BuildContext context, BlindTasteState state) {
    final items = List.generate(
      state.totalItemsInPool,
      (index) => BlindTasteAnswerCardItem(index, state),
    );

    final answeredCount = state.savedAnswers.values
        .where((answer) => _hasNonDefaultAnswer(answer))
        .length;

    final config = AnswerCardConfig(
      title: '酒样练习答题卡',
      icon: Icons.wine_bar,
      progressTextBuilder: (completedCount, totalCount) =>
          '${state.completedItemIds.length}/$totalCount',
      stats: [
        AnswerCardStats(
          label: '当前',
          count: state.currentIndex + 1,
          color: Theme.of(context).colorScheme.secondary,
        ),
        AnswerCardStats(
          label: '已完成',
          count: state.completedItemIds.length,
          color: Theme.of(context).colorScheme.primary,
        ),
        AnswerCardStats(
          label: '已作答',
          count: answeredCount,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        AnswerCardStats(
          label: '总题数',
          count: state.totalItemsInPool,
          color: Theme.of(context).colorScheme.outline,
        ),
      ],
      onItemTapped: (index) {
        final controller = ref.read(blindTasteProvider.notifier);
        controller.goToQuestion(index);
      },
      scrollController: _blindTasteSummaryScrollController,
    );

    AnswerCardHelper.showAnswerCard(context, items, config);

    // 答题卡展开时，延迟滚动到当前题目位置
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        AnswerCardHelper.scrollToCurrentItem(
          _blindTasteSummaryScrollController,
          state.currentIndex,
          context: this.context,
        );
      }
    });
  }

  // 检查答案是否不是默认状态（即用户有过选择）
  bool _hasNonDefaultAnswer(BlindTasteAnswer answer) {
    final defaultAnswer = BlindTasteAnswer();

    return answer.selectedAroma != defaultAnswer.selectedAroma ||
        answer.selectedAlcoholDegree != defaultAnswer.selectedAlcoholDegree ||
        answer.selectedTotalScore != defaultAnswer.selectedTotalScore ||
        answer.selectedEquipment.isNotEmpty ||
        answer.selectedFermentationAgent.isNotEmpty;
  }
}
