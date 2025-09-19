import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wine_simulation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../utils/haptic_manager.dart';
import '../models/blind_taste_model.dart';
import '../widgets/responsive_scaffold.dart';
import '../utils/responsive_layout.dart';

class WineSimulationPage extends ConsumerStatefulWidget {
  const WineSimulationPage({super.key});

  @override
  ConsumerState<WineSimulationPage> createState() => _WineSimulationPageState();
}

class _WineSimulationPageState extends ConsumerState<WineSimulationPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时开始新的练习
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wineSimulationProvider.notifier).startNewSimulation();
    });
  }

  // 统一的按钮样式方法
  ButtonStyle _primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      );

  ButtonStyle _secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wineSimulationProvider);
    final hapticSettings = ref.watch(hapticSettingsProvider);

    // 更新HapticManager的设置
    HapticManager.updateSettings(hapticEnabled: hapticSettings.hapticEnabled);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('品评模拟'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            HapticManager.medium();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        actions: [
          // 刷新按钮 - 只在模拟视图中显示，结果页面不显示
          if (state.wineGlasses.isNotEmpty && !state.showResults)
            IconButton(
              onPressed: () {
                HapticManager.medium();
                ref.read(wineSimulationProvider.notifier).startNewSimulation();
              },
              icon: const Icon(Icons.refresh),
              tooltip: '重新生成酒样组合',
            ),
        ],
      ),
      body: _buildBody(state),
      safeAreaBottom: false,
    );
  }

  Widget _buildBody(WineSimulationState state) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在准备酒样...'),
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
              onPressed: () {
                HapticManager.medium();
                ref.read(wineSimulationProvider.notifier).startNewSimulation();
              },
              style: _primaryButtonStyle(context),
              child: const Text('再来一次'),
            ),
          ],
        ),
      );
    }

    if (state.wineGlasses.isEmpty) {
      return const Center(child: Text('没有可用的酒样数据'));
    }

    if (state.showResults) {
      return _buildResultsView(state);
    }

    return _buildSimulationView(state);
  }

  Widget _buildSimulationView(WineSimulationState state) {
    final isLandscape =
        ResponsiveLayout.isTabletLandscape(context) ||
        ResponsiveLayout.isDesktop(context);

    if (isLandscape) {
      // 横屏布局：使用两列布局，左侧为酒杯网格，右侧为信息和按钮
      return ResponsiveTwoColumnLayout(
        ratio: 0.75, // 左侧占75%，右侧占25%
        leftColumn: _buildWineGlassGrid(state),
        rightColumn: _buildSidePanel(state),
      );
    } else {
      // 竖屏布局：保持原有布局
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 酒杯网格
            Expanded(child: _buildWineGlassGrid(state)),

            // 提交按钮
            const SizedBox(height: 16),
            _buildSubmitButton(state),
          ],
        ),
      );
    }
  }

  Widget _buildSidePanel(WineSimulationState state) {
    return Padding(
      padding: const EdgeInsets.all(8.0), // 进一步减小侧边面板内边距防止溢出
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 进度卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0), // 减小卡片内边距
              child: Column(
                children: [
                  Icon(
                    Icons.wine_bar,
                    size: 32, // 进一步减小图标尺寸
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '品评进度',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      // 减小字体
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${state.completedCount}/${state.wineGlasses.length}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      // 减小字体
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: state.wineGlasses.isNotEmpty
                        ? state.completedCount / state.wineGlasses.length
                        : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8), // 减小间距

          // 提示信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10.0), // 减小卡片内边距
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 16, // 减小图标尺寸
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '品评提示',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          // 减小字体
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• 点击酒杯进行品评\n• 从香型、酒度等维度评价\n• 完成所有酒样后提交',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11, // 减小字体
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 提交按钮
          _buildSubmitButton(state),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(WineSimulationState state) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state.allCompleted
            ? () {
                HapticManager.submitAnswer();
                ref.read(wineSimulationProvider.notifier).submitAllAnswers();
              }
            : null,
        style: _primaryButtonStyle(context),
        child: Text(
          state.allCompleted
              ? '提交答案'
              : '请完成所有酒杯样品评 (${state.completedCount}/${state.wineGlasses.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWineGlassGrid(WineSimulationState state) {
    final isLandscape =
        ResponsiveLayout.isTabletLandscape(context) ||
        ResponsiveLayout.isDesktop(context);

    // 根据酒杯数量动态调整列数，优化5杯场景
    int getLandscapeColumns() {
      final glassCount = state.wineGlasses.length;
      if (glassCount <= 5) {
        return 5; // 5杯或更少时，使用5列布局
      } else if (glassCount <= 6) {
        return 6; // 6杯时使用6列
      } else {
        return glassCount > 8 ? 8 : glassCount; // 超过8杯最多8列
      }
    }

    return ResponsiveGridView(
      mobileCrossAxisCount: 2,
      tabletCrossAxisCount: 3,
      tabletLandscapeCrossAxisCount: isLandscape ? getLandscapeColumns() : 4, // 动态列数
      desktopCrossAxisCount: isLandscape ? getLandscapeColumns() : 8,
      crossAxisSpacing: ResponsiveLayout.valueWhen(
        context: context,
        mobile: 12.0,
        tablet: 12.0,
        tabletLandscape: 8.0, // 横屏减小间距
        desktop: 12.0,
      ),
      mainAxisSpacing: ResponsiveLayout.valueWhen(
        context: context,
        mobile: 12.0,
        tablet: 12.0,
        tabletLandscape: 6.0, // 横屏减小行间距以节省垂直空间
        desktop: 12.0,
      ),
      childAspectRatio: ResponsiveLayout.valueWhen(
        context: context,
        mobile: 0.85,
        tablet: 0.9,
        tabletLandscape: 0.8, // 横屏进一步减小宽高比，增加垂直空间防止溢出
        desktop: 0.9,
      ),
      children: state.wineGlasses.asMap().entries.map((entry) {
        final index = entry.key;
        final glass = entry.value;
        return _buildWineGlassCard(glass, index);
      }).toList(),
    );
  }

  Widget _buildWineGlassCard(WineGlassState glass, int index) {
    final isCompleted = glass.status == WineGlassStatus.answered;
    final settings = ref.watch(settingsProvider);
    final isLandscape =
        ResponsiveLayout.isTabletLandscape(context) ||
        ResponsiveLayout.isDesktop(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isLandscape ? 16 : 16),
      ),
      child: InkWell(
        onTap: () {
          HapticManager.medium();
          _openWineGlassModal(glass, index);
        },
        borderRadius: BorderRadius.circular(isLandscape ? 16 : 16),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 6.0 : 10.0), // 横屏进一步减小内边距
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 酒样名称
              if (glass.wineItem != null)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 2 : 4,
                    vertical: isLandscape ? 1 : 2,
                  ),
                  child: Text(
                    glass.wineItem!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: isLandscape ? 10 : 12, // 横屏减小字体
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              if (glass.wineItem != null) SizedBox(height: isLandscape ? 2 : 4), // 横屏减小间距

              // 酒杯图标带序号
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.wine_bar,
                    size: isLandscape ? 64 : 72, // 横屏稍微减小酒杯图标以留出更多空间
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  // 在酒杯图标中央显示序号
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: isLandscape ? 20 : 24, // 横屏减小序号圆圈
                      height: isLandscape ? 20 : 24,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: isLandscape ? 8 : 10, // 横屏减小序号字体
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onInverseSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isLandscape ? 3 : 6), // 横屏减小间距

              // 用户答案信息
              if (isCompleted && glass.userAnswer != null)
                _buildAnswerSummary(glass.userAnswer!, settings, isLandscape)
              else
                Text(
                  '待品评',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: isLandscape ? 10 : 14, // 横屏减小字体
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerSummary(
    BlindTasteAnswer answer,
    dynamic settings,
    bool isLandscape,
  ) {
    final List<Widget> allChips = [];

    // 香型
    if (settings.enableBlindTasteAromaForced && answer.selectedAroma != null) {
      allChips.add(
        _buildAnswerChip(answer.selectedAroma!, Colors.purple, isLandscape),
      );
    }

    // 酒度
    if (settings.enableBlindTasteAlcohol &&
        answer.selectedAlcoholDegree != null) {
      allChips.add(
        _buildAnswerChip(
          '${answer.selectedAlcoholDegree!.toInt()}°',
          Colors.orange,
          isLandscape,
        ),
      );
    }

    // 总分
    if (settings.enableBlindTasteScore) {
      allChips.add(
        _buildAnswerChip(
          '${answer.selectedTotalScore.toStringAsFixed(1)}分',
          Colors.green,
          isLandscape,
        ),
      );
    }

    // 设备
    if (settings.enableBlindTasteEquipment &&
        answer.selectedEquipment.isNotEmpty) {
      for (String equipment in answer.selectedEquipment) {
        allChips.add(_buildAnswerChip(equipment, Colors.blue, isLandscape));
      }
    }

    // 发酵剂
    if (settings.enableBlindTasteFermentation &&
        answer.selectedFermentationAgent.isNotEmpty) {
      for (String agent in answer.selectedFermentationAgent) {
        allChips.add(_buildAnswerChip(agent, Colors.teal, isLandscape));
      }
    }

    if (allChips.isEmpty) {
      return Text(
        '已完成',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontSize: isLandscape ? 9 : 11, // 横屏字体更小
        ),
      );
    }

    // 直接显示所有答案芯片
    return Wrap(
      spacing: isLandscape ? 2 : 3, // 横屏减小间距
      runSpacing: isLandscape ? 1 : 3, // 横屏减小行间距
      children: allChips,
    );
  }

  Widget _buildAnswerChip(String text, Color color, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 2 : 2,
        vertical: isLandscape ? 1 : 1.5, // 横屏减小垂直内边距
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isLandscape ? 4 : 6), // 横屏减小圆角
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isLandscape ? 9 : 11, // 横屏减小字体以节省空间
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildResultsView(WineSimulationState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总体统计
          _buildOverallStats(state),

          const SizedBox(height: 14),

          // 重复酒样检测结果
          if (state.duplicateGroups.isNotEmpty)
            _buildDuplicateDetectionResults(state),

          if (state.duplicateGroups.isNotEmpty) const SizedBox(height: 16),

          // 详细结果列表
          Expanded(
            child: ListView.builder(
              itemCount: state.wineGlasses.length,
              itemBuilder: (context, index) {
                final glass = state.wineGlasses[index];
                return _buildDetailedResultCard(glass, index, state);
              },
            ),
          ),

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticManager.medium();
                    ref
                        .read(wineSimulationProvider.notifier)
                        .startNewSimulation();
                  },
                  style: _primaryButtonStyle(context),
                  child: const Text('重新开始'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticManager.medium();
                    Navigator.of(context).pop();
                  },
                  style: _secondaryButtonStyle(context),
                  child: const Text('返回'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats(WineSimulationState state) {
    final totalGlasses = state.wineGlasses.length;
    final correctCount = state.wineGlasses
        .where((glass) => (glass.score ?? 0.0) >= 80.0)
        .length;
    final averageScore = state.wineGlasses.isNotEmpty
        ? state.wineGlasses
                  .map((glass) => glass.score ?? 0.0)
                  .reduce((a, b) => a + b) /
              totalGlasses
        : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('总酒杯数', '$totalGlasses', Icons.wine_bar),
                _buildStatItem('正确识别', '$correctCount', Icons.check_circle),
                _buildStatItem(
                  '平均得分',
                  averageScore.toStringAsFixed(1),
                  Icons.star,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateDetectionResults(WineSimulationState state) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '重复酒样结果',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...state.duplicateGroups.entries.map((entry) {
              final wineName = entry.key;
              final glassIndices = entry.value;
              final userDetectedCorrectly = _checkDuplicateDetection(
                state,
                glassIndices,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      userDetectedCorrectly ? Icons.check_circle : Icons.cancel,
                      color: userDetectedCorrectly ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$wineName (酒杯 ${glassIndices.map((i) => i + 1).join(', ')})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      userDetectedCorrectly ? '识别正确' : '识别错误',
                      style: TextStyle(
                        color: userDetectedCorrectly
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _checkDuplicateDetection(
    WineSimulationState state,
    List<int> glassIndices,
  ) {
    if (glassIndices.length < 2) return true;

    // 检查用户是否正确识别了这些酒杯包含相同的酒样
    final firstGlass = state.wineGlasses[glassIndices.first];
    final firstAnswer = firstGlass.userAnswer;

    if (firstAnswer == null) return false;

    // 比较所有相同酒样的用户答案是否一致
    for (int i = 1; i < glassIndices.length; i++) {
      final glass = state.wineGlasses[glassIndices[i]];
      final answer = glass.userAnswer;

      if (answer == null) return false;

      // 检查关键答案是否一致（香型和酒度）
      if (answer.selectedAroma != firstAnswer.selectedAroma ||
          answer.selectedAlcoholDegree != firstAnswer.selectedAlcoholDegree) {
        return false;
      }
    }

    return true;
  }

  Widget _buildDetailedResultCard(
    WineGlassState glass,
    int index,
    WineSimulationState state,
  ) {
    final score = glass.score ?? 0.0;
    final isCorrect = score >= 80.0;
    final settings = ref.watch(settingsProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wine_bar,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${index + 1} 号杯',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${score.toStringAsFixed(1)}分',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (glass.wineItem != null) ...[
              Text(
                '正确答案: ${glass.wineItem!.name}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // 详细对比
              if (glass.userAnswer != null) ...[
                // if (settings.enableBlindTasteAromaForced)
                //   _buildComparisonRow(
                //     '香型',
                //     glass.userAnswer!.selectedAroma ?? '未选择',
                //     glass.wineItem!.aroma,
                //   ),
                if (settings.enableBlindTasteAlcohol)
                  _buildComparisonRow(
                    '酒度',
                    glass.userAnswer!.selectedAlcoholDegree != null
                        ? '${glass.userAnswer!.selectedAlcoholDegree!.toInt()}°'
                        : '未选择',
                    '${glass.wineItem!.alcoholDegree.toInt()}°',
                  ),
                if (settings.enableBlindTasteScore)
                  _buildComparisonRow(
                    '总分',
                    glass.userAnswer!.selectedTotalScore.toStringAsFixed(1),
                    glass.wineItem!.totalScore.toStringAsFixed(1),
                  ),
              ],
            ],
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              userAnswer,
              style: TextStyle(
                color: isCorrect ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            isCorrect ? Icons.check : Icons.close,
            size: 16,
            color: isCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            correctAnswer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // 获取下一个未完成的酒杯索引
  int? _getNextIncompleteGlassIndex(
    WineSimulationState state,
    int currentIndex,
  ) {
    for (int i = currentIndex + 1; i < state.wineGlasses.length; i++) {
      if (state.wineGlasses[i].status != WineGlassStatus.answered) {
        return i;
      }
    }
    // 如果后面没有未完成的，从头开始找
    for (int i = 0; i < currentIndex; i++) {
      if (state.wineGlasses[i].status != WineGlassStatus.answered) {
        return i;
      }
    }
    return null; // 所有酒杯都已完成
  }

  void _openWineGlassModal(WineGlassState glass, int index) {
    HapticManager.medium();
    final state = ref.read(wineSimulationProvider);
    final nextGlassIndex = _getNextIncompleteGlassIndex(state, index);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WineTastingModal(
        glassIndex: index,
        wineItem: glass.wineItem!,
        initialAnswer: glass.userAnswer,
        hasNextGlass: nextGlassIndex != null,
        onSave: (answer) {
          ref
              .read(wineSimulationProvider.notifier)
              .updateGlassAnswer(index, answer);
          Navigator.of(context).pop();
        },
        onNext: nextGlassIndex != null
            ? (answer) {
                ref
                    .read(wineSimulationProvider.notifier)
                    .updateGlassAnswer(index, answer);
                Navigator.of(context).pop();
                // 打开下一个酒杯
                _openWineGlassModal(
                  state.wineGlasses[nextGlassIndex],
                  nextGlassIndex,
                );
              }
            : null,
      ),
    );
  }
}

// 酒样品评模态弹窗
class WineTastingModal extends ConsumerStatefulWidget {
  final int glassIndex;
  final BlindTasteItemModel wineItem;
  final BlindTasteAnswer? initialAnswer;
  final bool hasNextGlass;
  final Function(BlindTasteAnswer) onSave;
  final Function(BlindTasteAnswer)? onNext;

  const WineTastingModal({
    super.key,
    required this.glassIndex,
    required this.wineItem,
    this.initialAnswer,
    required this.hasNextGlass,
    required this.onSave,
    this.onNext,
  });

  @override
  ConsumerState<WineTastingModal> createState() => _WineTastingModalState();
}

class _WineTastingModalState extends ConsumerState<WineTastingModal> {
  late BlindTasteAnswer _currentAnswer;

  @override
  void initState() {
    super.initState();
    _currentAnswer = widget.initialAnswer ?? BlindTasteAnswer();
  }

  // 统一的按钮样式方法
  ButtonStyle _primaryButtonStyle(BuildContext context) =>
      ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      );

  ButtonStyle _secondaryButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 横屏模式调整尺寸
    final dialogHeight = isLandscape ? 0.85 : 0.88; // 横屏模式稍微减小高度
    final dialogPadding = isLandscape ? 6.0 : 8.0;
    final insetPadding = isLandscape ? 8.0 : 12.0;

    return Dialog(
      insetPadding: EdgeInsets.all(insetPadding),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * dialogHeight,
        padding: EdgeInsets.all(dialogPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 3 : 4,
                vertical: isLandscape ? 1 : 2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.wine_bar,
                    size: isLandscape ? 18 : 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: isLandscape ? 4 : 6),
                  Text(
                    '${widget.glassIndex + 1} 号杯',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isLandscape ? 15 : null,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      HapticManager.medium();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.close, size: isLandscape ? 18 : 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: isLandscape ? 28 : 32,
                      minHeight: isLandscape ? 28 : 32,
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: isLandscape ? 6 : 8),

            // 品评内容
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 酒样信息
                    Card(
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.all(isLandscape ? 6.0 : 8.0),
                        child: Row(
                          children: [
                            SizedBox(width: isLandscape ? 6 : 8),
                            Expanded(
                              child: Text(
                                '【${widget.wineItem.name}】',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isLandscape ? 16 : 18,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isLandscape ? 6 : 8),

                    // 总分选择（移到酒度之前）
                    if (settings.enableBlindTasteScore) _buildScoreSection(),

                    if (settings.enableBlindTasteScore)
                      SizedBox(height: isLandscape ? 4 : 6),

                    // 酒度选择（移到总分之后）
                    if (settings.enableBlindTasteAlcohol)
                      _buildAlcoholSection(),

                    if (settings.enableBlindTasteAlcohol)
                      SizedBox(height: isLandscape ? 4 : 6),

                    // 设备选择
                    if (settings.enableBlindTasteEquipment)
                      _buildEquipmentSection(),

                    if (settings.enableBlindTasteEquipment)
                      SizedBox(height: isLandscape ? 4 : 6),

                    // 发酵剂选择
                    if (settings.enableBlindTasteFermentation)
                      _buildFermentationSection(),
                  ],
                ),
              ),
            ),

            // 底部按钮
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? 3 : 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.hasNextGlass && widget.onNext != null
                          ? () {
                              HapticManager.medium();
                              widget.onNext!(_currentAnswer);
                            }
                          : null,
                      style: _secondaryButtonStyle(context).copyWith(
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: isLandscape ? 12 : 16),
                        ),
                      ),
                      child: Text(
                        widget.hasNextGlass ? '下一杯' : '无下一杯',
                        style: TextStyle(
                          fontSize: isLandscape ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isLandscape ? 8 : 12),
                  Expanded(
                    flex: 2, // 保存按钮占更多空间
                    child: ElevatedButton(
                      onPressed: _canSubmit(settings)
                          ? () {
                              HapticManager.submitAnswer();
                              widget.onSave(_currentAnswer);
                            }
                          : null,
                      style: _primaryButtonStyle(context).copyWith(
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: isLandscape ? 12 : 16),
                        ),
                      ),
                      child: Text(
                        '保存',
                        style: TextStyle(
                          fontSize: isLandscape ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
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

  // Widget _buildAromaSection() {
  //   return Card(
  //     elevation: 1,
  //     margin: EdgeInsets.zero,
  //     child: Padding(
  //       padding: const EdgeInsets.all(6.0),
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
  //               if (_currentAnswer.selectedAroma != null)
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
  //                     _currentAnswer.selectedAroma!,
  //                     style: TextStyle(
  //                       fontSize: 11,
  //                       fontWeight: FontWeight.w500,
  //                       color: Theme.of(context).colorScheme.onPrimaryContainer,
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //           const SizedBox(height: 6),
  //           DropdownButtonFormField<String>(
  //             initialValue: _currentAnswer.selectedAroma,
  //             decoration: InputDecoration(
  //               hintText: '选择香型',
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(6),
  //               ),
  //               contentPadding: const EdgeInsets.symmetric(
  //                 horizontal: 8,
  //                 vertical: 6,
  //               ),
  //             ),
  //             dropdownColor: Theme.of(context).colorScheme.surface,
  //             menuMaxHeight: 300,
  //             items: BlindTasteOptions.aromaTypes.map((aroma) {
  //               return DropdownMenuItem(
  //                 value: aroma,
  //                 child: Padding(
  //                   padding: const EdgeInsets.symmetric(
  //                     vertical: 4,
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
  //                 setState(() {
  //                   _currentAnswer = BlindTasteAnswer(
  //                     selectedAroma: value,
  //                     selectedAlcoholDegree:
  //                         _currentAnswer.selectedAlcoholDegree,
  //                     selectedTotalScore: _currentAnswer.selectedTotalScore,
  //                     selectedEquipment: List.from(
  //                       _currentAnswer.selectedEquipment,
  //                     ),
  //                     selectedFermentationAgent: List.from(
  //                       _currentAnswer.selectedFermentationAgent,
  //                     ),
  //                   );
  //                 });
  //               }
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAlcoholSection() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
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
                if (_currentAnswer.selectedAlcoholDegree != null)
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
                      '答案: ${_currentAnswer.selectedAlcoholDegree!.toInt()}°',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: BlindTasteOptions.alcoholDegrees.map((degree) {
                final isSelected =
                    _currentAnswer.selectedAlcoholDegree == degree;
                return FilterChip(
                  label: Text('${degree.toInt()}°'),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    setState(() {
                      _currentAnswer = BlindTasteAnswer(
                        selectedAroma: _currentAnswer.selectedAroma,
                        selectedAlcoholDegree: degree,
                        selectedTotalScore: _currentAnswer.selectedTotalScore,
                        selectedEquipment: List.from(
                          _currentAnswer.selectedEquipment,
                        ),
                        selectedFermentationAgent: List.from(
                          _currentAnswer.selectedFermentationAgent,
                        ),
                      );
                    });
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

  Widget _buildScoreSection() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '总分',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 减分按钮
                IconButton(
                  onPressed: _currentAnswer.selectedTotalScore > 84.0
                      ? () {
                          HapticManager.medium();
                          final newScore =
                              (_currentAnswer.selectedTotalScore - 0.2).clamp(
                                84.0,
                                98.0,
                              );
                          setState(() {
                            _currentAnswer = BlindTasteAnswer(
                              selectedAroma: _currentAnswer.selectedAroma,
                              selectedAlcoholDegree:
                                  _currentAnswer.selectedAlcoholDegree,
                              selectedTotalScore: newScore,
                              selectedEquipment: List.from(
                                _currentAnswer.selectedEquipment,
                              ),
                              selectedFermentationAgent: List.from(
                                _currentAnswer.selectedFermentationAgent,
                              ),
                            );
                          });
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
                  _currentAnswer.selectedTotalScore.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Slider(
                    value: _currentAnswer.selectedTotalScore.clamp(84.0, 98.0),
                    min: 84.0,
                    max: 98.0,
                    divisions: 70, // (98-84)/0.2 = 70
                    onChanged: (value) {
                      HapticManager.selection();
                      setState(() {
                        _currentAnswer = BlindTasteAnswer(
                          selectedAroma: _currentAnswer.selectedAroma,
                          selectedAlcoholDegree:
                              _currentAnswer.selectedAlcoholDegree,
                          selectedTotalScore: value,
                          selectedEquipment: List.from(
                            _currentAnswer.selectedEquipment,
                          ),
                          selectedFermentationAgent: List.from(
                            _currentAnswer.selectedFermentationAgent,
                          ),
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 2),
                // 加分按钮
                IconButton(
                  onPressed: _currentAnswer.selectedTotalScore < 98.0
                      ? () {
                          HapticManager.medium();
                          final newScore =
                              (_currentAnswer.selectedTotalScore + 0.2).clamp(
                                84.0,
                                98.0,
                              );
                          setState(() {
                            _currentAnswer = BlindTasteAnswer(
                              selectedAroma: _currentAnswer.selectedAroma,
                              selectedAlcoholDegree:
                                  _currentAnswer.selectedAlcoholDegree,
                              selectedTotalScore: newScore,
                              selectedEquipment: List.from(
                                _currentAnswer.selectedEquipment,
                              ),
                              selectedFermentationAgent: List.from(
                                _currentAnswer.selectedFermentationAgent,
                              ),
                            );
                          });
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

  Widget _buildEquipmentSection() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设备',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 18,
              runSpacing: 2,
              children: BlindTasteOptions.equipmentTypes.map((equipment) {
                final isSelected = _currentAnswer.selectedEquipment.contains(
                  equipment,
                );
                return FilterChip(
                  label: Text(equipment),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    setState(() {
                      final newEquipment = List<String>.from(
                        _currentAnswer.selectedEquipment,
                      );
                      if (isSelected) {
                        newEquipment.remove(equipment);
                      } else {
                        newEquipment.add(equipment);
                      }
                      _currentAnswer = BlindTasteAnswer(
                        selectedAroma: _currentAnswer.selectedAroma,
                        selectedAlcoholDegree:
                            _currentAnswer.selectedAlcoholDegree,
                        selectedTotalScore: _currentAnswer.selectedTotalScore,
                        selectedEquipment: newEquipment,
                        selectedFermentationAgent: List.from(
                          _currentAnswer.selectedFermentationAgent,
                        ),
                      );
                    });
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

  Widget _buildFermentationSection() {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '发酵剂',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 17,
              runSpacing: 4,
              children: BlindTasteOptions.fermentationAgents.map((agent) {
                final isSelected = _currentAnswer.selectedFermentationAgent
                    .contains(agent);
                return FilterChip(
                  label: Text(agent),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticManager.medium();
                    setState(() {
                      final newAgents = List<String>.from(
                        _currentAnswer.selectedFermentationAgent,
                      );
                      if (isSelected) {
                        newAgents.remove(agent);
                      } else {
                        newAgents.add(agent);
                      }
                      _currentAnswer = BlindTasteAnswer(
                        selectedAroma: _currentAnswer.selectedAroma,
                        selectedAlcoholDegree:
                            _currentAnswer.selectedAlcoholDegree,
                        selectedTotalScore: _currentAnswer.selectedTotalScore,
                        selectedEquipment: List.from(
                          _currentAnswer.selectedEquipment,
                        ),
                        selectedFermentationAgent: newAgents,
                      );
                    });
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

  bool _canSubmit(dynamic settings) {
    bool canSubmit = true;

    if (settings.enableBlindTasteAromaForced) {
      canSubmit = canSubmit && _currentAnswer.selectedAroma != null;
    }

    if (settings.enableBlindTasteAlcohol) {
      canSubmit = canSubmit && _currentAnswer.selectedAlcoholDegree != null;
    }

    return canSubmit;
  }
}
