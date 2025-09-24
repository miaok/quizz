import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wine_simulation_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../utils/haptic_manager.dart';
import '../models/blind_taste_model.dart';
import '../widgets/responsive_scaffold.dart';
import '../utils/responsive_layout.dart';
import '../widgets/wine_tasting_components.dart';

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
            //const SizedBox(height: 16),
            //_buildSubmitButton(state),
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
          //_buildSubmitButton(state),
        ],
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
      tabletLandscapeCrossAxisCount: isLandscape
          ? getLandscapeColumns()
          : 4, // 动态列数
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
        mobile: 0.75, // 减小宽高比以增加高度
        tablet: 0.8, // 减小宽高比以增加高度
        tabletLandscape: 0.6, // 横屏进一步减小宽高比，以容纳更多标签
        desktop: 0.7, // 减小宽高比以增加高度
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
          _openWineGlassModal(glass, index);
        },
        borderRadius: BorderRadius.circular(isLandscape ? 16 : 16),
        child: Padding(
          padding: EdgeInsets.all(isLandscape ? 8.0 : 10.0), // 横屏稍微增加内边距给标签更多空间
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

              if (glass.wineItem != null)
                SizedBox(height: isLandscape ? 2 : 4), // 横屏减小间距
              // 酒杯图标带序号
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.wine_bar,
                    size: isLandscape ? 64 : 72,
                    color: isCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  // 在酒杯图标中央偏上位置显示序号，扁平化设计
                  Positioned(
                    top: isLandscape ? 18 : 20, // 文字上移
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: isLandscape ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 57, 54, 54) // 深色模式下使用黑色
                            : const Color.fromARGB(
                                255,
                                251,
                                244,
                                244,
                              ), // 浅色模式下使用白色
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
      runSpacing: isLandscape ? 2 : 3, // 横屏保持合适的行间距
      children: allChips,
    );
  }

  Widget _buildAnswerChip(String text, Color color, bool isLandscape) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLandscape ? 3 : 2, // 横屏稍微增加水平内边距以提高可读性
        vertical: isLandscape ? 1.5 : 1.5, // 保持合适的垂直内边距
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(isLandscape ? 5 : 6), // 横屏稍微增大圆角
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isLandscape ? 10 : 11, // 横屏保持可读的字体大小
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }

  Widget _buildResultsView(WineSimulationState state) {
    final settings = ref.watch(settingsProvider);
    final bool isQualityMode = settings.enableWineSimulationSameWineSeries;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 重复酒样检测结果 - 只在非质量差模式下显示
          if (!isQualityMode && state.duplicateGroups.isNotEmpty)
            _buildDuplicateDetectionResults(state),

          if (!isQualityMode && state.duplicateGroups.isNotEmpty)
            const SizedBox(height: 16),

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
                  child: const Text('再次模拟'),
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
                  child: const Text('返回首页'),
                ),
              ),
            ],
          ),
        ],
      ),
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

    final settings = ref.watch(settingsProvider);
    final bool isQualityMode = settings.enableWineSimulationSameWineSeries;

    // 在质量差模式下，由于每个酒样都是不同的，不需要重复检测
    if (isQualityMode) {
      return true;
    }

    // 非质量差模式的重复检测逻辑
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
    // 简化的对错判断逻辑：100分表示正确，0分表示错误
    final score = glass.score ?? 0.0;
    final isCorrect = score >= 100.0;
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
                    isCorrect ? '正确' : '错误',
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
                '酒样: ${_getDisplayWineName(glass.wineItem!.name)}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // 详细对比 - 网格布局
              if (glass.userAnswer != null) ...[
                _buildCompactComparisonGrid(glass, settings),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactComparisonGrid(WineGlassState glass, dynamic settings) {
    final answer = glass.userAnswer!;
    final wineItem = glass.wineItem!;

    List<Widget> comparisonItems = [];

    // 香型对比
    if (settings.enableBlindTasteAromaForced && answer.selectedAroma != null) {
      comparisonItems.add(
        _buildCompactComparisonItem(
          '香型',
          answer.selectedAroma!,
          wineItem.aroma,
        ),
      );
    }

    // 酒度对比
    if (settings.enableBlindTasteAlcohol &&
        answer.selectedAlcoholDegree != null) {
      comparisonItems.add(
        _buildCompactComparisonItem(
          '酒度',
          '${answer.selectedAlcoholDegree!.toInt()}°',
          '${wineItem.alcoholDegree.toInt()}°',
        ),
      );
    }

    // 总分对比
    if (settings.enableBlindTasteScore) {
      comparisonItems.add(
        _buildCompactComparisonItem(
          '总分',
          '${answer.selectedTotalScore.toStringAsFixed(1)}分',
          '${wineItem.totalScore.toStringAsFixed(1)}分',
        ),
      );
    }

    // 设备对比
    if (settings.enableBlindTasteEquipment &&
        answer.selectedEquipment.isNotEmpty) {
      comparisonItems.add(
        _buildCompactComparisonItem(
          '设备',
          answer.selectedEquipment.join('、'),
          wineItem.equipment.join('、'),
          userAnswerList: answer.selectedEquipment,
          correctAnswerList: wineItem.equipment,
        ),
      );
    }

    // 发酵剂对比
    if (settings.enableBlindTasteFermentation &&
        answer.selectedFermentationAgent.isNotEmpty) {
      comparisonItems.add(
        _buildCompactComparisonItem(
          '发酵剂',
          answer.selectedFermentationAgent.join('、'),
          wineItem.fermentationAgent.join('、'),
          userAnswerList: answer.selectedFermentationAgent,
          correctAnswerList: wineItem.fermentationAgent,
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, // 2列布局
      childAspectRatio: 2.2, // 增加宽高比，让卡片更宽一些，减少高度
      crossAxisSpacing: 8,
      mainAxisSpacing: 4, // 减小主轴间距
      children: comparisonItems,
    );
  }

  Widget _buildCompactComparisonItem(
    String label,
    String userAnswer,
    String correctAnswer, {
    List<String>? userAnswerList,
    List<String>? correctAnswerList,
  }) {
    bool isCorrect;

    // 如果提供了列表参数，则使用集合比较
    if (userAnswerList != null && correctAnswerList != null) {
      Set<String> userSet = userAnswerList.toSet();
      Set<String> correctSet = correctAnswerList.toSet();
      isCorrect =
          userSet.length == correctSet.length &&
          userSet.containsAll(correctSet);
    } else {
      // 否则使用字符串比较
      isCorrect = userAnswer == correctAnswer;
    }

    return Container(
      padding: const EdgeInsets.all(4), // 减小内边距
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.red.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题和状态
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12, // 稍微增加字体大小以提高可读性
                  ),
                ),
              ),
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                size: 12, // 稍微减小图标大小
                color: isCorrect ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 2),

          // 用户答案
          Text(
            '您: $userAnswer',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 11, // 稍微增加字体大小
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),

          // 正确答案
          Text(
            '答: $correctAnswer',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 11, // 稍微增加字体大小
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 获取酒样显示名称
  /// 所有模式都保留完整的酒样名称（包括序号）
  String _getDisplayWineName(String wineName) {
    // 保留完整的酒样名称，不移除序号后缀
    return wineName;
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

  // ButtonStyle _secondaryButtonStyle(BuildContext context) =>
  //     OutlinedButton.styleFrom(
  //       padding: const EdgeInsets.symmetric(vertical: 16),
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //       side: BorderSide(color: Theme.of(context).colorScheme.outline),
  //     );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    // 获取屏幕信息进行响应式处理
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 横屏模式调整尺寸
    final dialogHeight = isLandscape ? 0.80 : 0.85; // 进一步减小对话框高度
    final dialogPadding = isLandscape ? 4.0 : 6.0; // 减小内边距
    final insetPadding = isLandscape ? 6.0 : 10.0; // 减小外边距

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
                      // 关闭弹窗时保存用户答案
                      ref
                          .read(wineSimulationProvider.notifier)
                          .updateGlassAnswer(widget.glassIndex, _currentAnswer);
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
                                      fontSize: isLandscape ? 18 : 20,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: isLandscape ? 4 : 6), // 减小间距
                    // 总分选择（移到酒度之前）
                    if (settings.enableBlindTasteScore)
                      TotalScoreSectionWidget(
                        selectedTotalScore: _currentAnswer.selectedTotalScore,
                        onScoreChanged: (score) {
                          setState(() {
                            _currentAnswer = BlindTasteAnswer(
                              selectedAroma: _currentAnswer.selectedAroma,
                              selectedAlcoholDegree:
                                  _currentAnswer.selectedAlcoholDegree,
                              selectedTotalScore: score,
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

                    if (settings.enableBlindTasteScore)
                      SizedBox(height: isLandscape ? 3 : 4), // 减小间距
                    // 酒度选择（移到总分之后）
                    if (settings.enableBlindTasteAlcohol)
                      AlcoholSectionWidget(
                        selectedAlcoholDegree:
                            _currentAnswer.selectedAlcoholDegree,
                        onAlcoholChanged: (degree) {
                          setState(() {
                            _currentAnswer = BlindTasteAnswer(
                              selectedAroma: _currentAnswer.selectedAroma,
                              selectedAlcoholDegree: degree,
                              selectedTotalScore:
                                  _currentAnswer.selectedTotalScore,
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

                    if (settings.enableBlindTasteAlcohol)
                      SizedBox(height: isLandscape ? 3 : 4), // 减小间距
                    // 设备选择
                    if (settings.enableBlindTasteEquipment)
                      EquipmentSectionWidget(
                        selectedEquipment: _currentAnswer.selectedEquipment,
                        onEquipmentToggled: (equipment) {
                          setState(() {
                            final newEquipment = List<String>.from(
                              _currentAnswer.selectedEquipment,
                            );
                            if (newEquipment.contains(equipment)) {
                              newEquipment.remove(equipment);
                            } else {
                              newEquipment.add(equipment);
                            }
                            _currentAnswer = BlindTasteAnswer(
                              selectedAroma: _currentAnswer.selectedAroma,
                              selectedAlcoholDegree:
                                  _currentAnswer.selectedAlcoholDegree,
                              selectedTotalScore:
                                  _currentAnswer.selectedTotalScore,
                              selectedEquipment: newEquipment,
                              selectedFermentationAgent: List.from(
                                _currentAnswer.selectedFermentationAgent,
                              ),
                            );
                          });
                        },
                      ),

                    if (settings.enableBlindTasteEquipment)
                      SizedBox(height: isLandscape ? 3 : 4), // 减小间距
                    // 发酵剂选择
                    if (settings.enableBlindTasteFermentation)
                      FermentationAgentSectionWidget(
                        selectedFermentationAgent:
                            _currentAnswer.selectedFermentationAgent,
                        onFermentationAgentToggled: (agent) {
                          setState(() {
                            final newAgents = List<String>.from(
                              _currentAnswer.selectedFermentationAgent,
                            );
                            if (newAgents.contains(agent)) {
                              newAgents.remove(agent);
                            } else {
                              newAgents.add(agent);
                            }
                            _currentAnswer = BlindTasteAnswer(
                              selectedAroma: _currentAnswer.selectedAroma,
                              selectedAlcoholDegree:
                                  _currentAnswer.selectedAlcoholDegree,
                              selectedTotalScore:
                                  _currentAnswer.selectedTotalScore,
                              selectedEquipment: List.from(
                                _currentAnswer.selectedEquipment,
                              ),
                              selectedFermentationAgent: newAgents,
                            );
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),

            // 底部按钮 - 只保留下一杯/提交答案按钮
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isLandscape ? 3 : 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.hasNextGlass && widget.onNext != null
                      ? () {
                          widget.onNext!(_currentAnswer);
                        }
                      : () {
                          // 当没有下一杯时，执行提交答案功能
                          HapticManager.submitAnswer();
                          // 直接保存答案
                          ref
                              .read(wineSimulationProvider.notifier)
                              .updateGlassAnswer(
                                widget.glassIndex,
                                _currentAnswer,
                              );
                          Navigator.of(context).pop();
                          // 提交所有答案，显示结果页面
                          ref
                              .read(wineSimulationProvider.notifier)
                              .submitAllAnswers();
                        },
                  style: _primaryButtonStyle(context).copyWith(
                    padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: isLandscape ? 8 : 12),
                    ),
                  ),
                  child: Text(
                    widget.hasNextGlass ? '下一杯' : '提交答案',
                    style: TextStyle(
                      fontSize: isLandscape ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
