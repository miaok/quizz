import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../utils/haptic_manager.dart';
import '../models/settings_model.dart';
import '../services/progress_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsController = ref.read(settingsProvider.notifier);
    final hapticSettings = ref.watch(hapticSettingsProvider);

    // 更新HapticManager的设置
    HapticManager.updateSettings(hapticEnabled: hapticSettings.hapticEnabled);

    return Scaffold(
      appBar: AppBar(
        title: const Text('应用设置'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticManager.medium();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticManager.medium();
              _showResetDialog(context, settingsController);
            },
            child: Text(
              '重置',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.quiz), text: '理论设置'),
            Tab(icon: Icon(Icons.wine_bar), text: '品评设置'),
            Tab(icon: Icon(Icons.settings), text: '系统设置'),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            // 理论设置页面
            _buildTheorySettingsTab(settings, settingsController),
            // 品评设置页面
            _buildTastingSettingsTab(settings, settingsController),
            // 系统设置页面
            _buildSystemSettingsTab(settings, settingsController),
          ],
        ),
      ),
    );
  }

  // 理论设置标签页
  Widget _buildTheorySettingsTab(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          title: '题目数量',
          icon: Icons.format_list_numbered,
          child: _buildQuestionCountsSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '考试时间',
          icon: Icons.timer,
          child: _buildExamTimeSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '答题选项',
          icon: Icons.tune,
          child: _buildQuizOptionsSection(settings, controller),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 品评设置标签页
  Widget _buildTastingSettingsTab(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          title: '基础品评项目',
          icon: Icons.wine_bar,
          child: _buildBasicTastingSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '品评模拟设置',
          icon: Icons.science_outlined,
          child: _buildWineSimulationSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '同酒样系列模式',
          icon: Icons.numbers,
          child: _buildSameWineSeriesSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '乱序设置',
          icon: Icons.memory,
          child: _buildFlashcardSection(settings, controller),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 系统设置标签页
  Widget _buildSystemSettingsTab(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          title: '触感管理',
          icon: Icons.vibration,
          child: _buildHapticSection(),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '进度管理',
          icon: Icons.save,
          child: _buildProgressSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '系统操作',
          icon: Icons.build,
          child: _buildSystemActionsSection(context),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 设置区域卡片构建器
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // 题目数量设置区域
  Widget _buildQuestionCountsSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildCountCard(
          '判断题',
          settings.booleanCount,
          Colors.green,
          (value) => controller.updateBooleanCount(value),
        ),
        const SizedBox(height: 8),
        _buildCountCard(
          '单选题',
          settings.singleChoiceCount,
          Colors.blue,
          (value) => controller.updateSingleChoiceCount(value),
        ),
        const SizedBox(height: 8),
        _buildCountCard(
          '多选题',
          settings.multipleChoiceCount,
          Colors.orange,
          (value) => controller.updateMultipleChoiceCount(value),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.quiz,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '总题数',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${settings.totalQuestions} 题',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 数量调节卡片
  Widget _buildCountCard(
    String title,
    int currentValue,
    Color color,
    Function(int) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: currentValue > 0
                ? () {
                    HapticManager.medium();
                    onChanged(currentValue - 1);
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 20,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$currentValue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          IconButton(
            onPressed: currentValue < 100
                ? () {
                    HapticManager.medium();
                    onChanged(currentValue + 1);
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // 品评模拟酒样数量调节卡片（限制范围2-6）
  Widget _buildWineSimulationCountCard(
    int currentValue,
    Function(int) onChanged, {
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '品评模拟样品数设置',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '酒样模拟的基础数量范围为2-6杯',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '同酒样系列模式开启，杯数固定为5杯',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: !isLocked && currentValue > 2
                ? () {
                    HapticManager.medium();
                    onChanged(currentValue - 1);
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 20,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentValue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                if (isLocked)
                  const Icon(Icons.lock, size: 14, color: Colors.amber),
              ],
            ),
          ),
          IconButton(
            onPressed: !isLocked && currentValue < 6
                ? () {
                    HapticManager.medium();
                    onChanged(currentValue + 1);
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // 品鉴模式重复概率卡片
  Widget _buildWineSimulationProbabilityCard(
    double currentValue,
    Function(double) onChanged, {
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '品评模拟重复酒样概率',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isLocked ? '同酒样系列模式下，重复概率固定为0%' : '设置一轮模拟中出现重复酒样的概率',
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocked
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${(currentValue * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.lock, size: 16, color: Colors.amber),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: currentValue,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: isLocked
                ? null
                : (value) {
                    HapticManager.selection();
                    onChanged(value);
                  },
            activeColor: isLocked
                ? Colors.amber.withValues(alpha: 0.5)
                : Colors.amber,
          ),
        ],
      ),
    );
  }

  // 品评模拟最大重复组数设置卡片
  Widget _buildWineSimulationMaxGroupsCard(
    int currentValue,
    Function(int) onChanged, {
    bool isLocked = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '品评模拟最大重复组数',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  isLocked ? '同酒样系列模式下，重复组数固定为0组' : '设置一轮模拟中最多允许的重复酒样组数（1-3组）',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLocked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: !isLocked && currentValue > 1
                ? () {
                    HapticManager.medium();
                    onChanged(currentValue - 1);
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 20,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentValue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                if (isLocked)
                  const Icon(Icons.lock, size: 14, color: Colors.amber),
              ],
            ),
          ),
          IconButton(
            onPressed: !isLocked && currentValue < 3
                ? () {
                    HapticManager.medium();
                    onChanged(currentValue + 1);
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // 多选题切题延迟时间设置卡片
  Widget _buildMultipleChoiceDelayCard(
    QuizSettings settings,
    SettingsController controller,
  ) {
    // 确保字段不为空，如果为空则使用默认值
    final delayMs = settings.multipleChoiceAutoSwitchDelay;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '多选题切题延迟',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '设置多选题自动切换到下一题的延迟时间，给予充分时间选择多个选项',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(delayMs / 1000).toStringAsFixed(1)}秒',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: delayMs.toDouble(),
            min: 1000.0,
            max: 5000.0,
            divisions: 20,
            onChanged: (value) {
              HapticManager.selection();
              controller.updateMultipleChoiceAutoSwitchDelay(value.round());
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1.0秒',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '5.0秒',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 考试时间设置区域
  Widget _buildExamTimeSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '考试时间',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: settings.examTimeMinutes > 1
                ? () {
                    HapticManager.medium();
                    controller.updateExamTimeMinutes(
                      settings.examTimeMinutes - 1,
                    );
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 20,
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text(
              '${settings.examTimeMinutes} 分钟',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: settings.examTimeMinutes < 60
                ? () {
                    HapticManager.medium();
                    controller.updateExamTimeMinutes(
                      settings.examTimeMinutes + 1,
                    );
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  // 答题选项设置区域
  Widget _buildQuizOptionsSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '选项乱序',
          subtitle: '开启后所有理论题目选项顺序随机打乱,建议保持开启',
          icon: Icons.shuffle,
          value: settings.shuffleOptions,
          onChanged: controller.updateShuffleOptions,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '快速切题',
          subtitle: '选择答案后自动进入下一题,多选题尽快选择所有答案',
          icon: Icons.fast_forward,
          value: settings.autoNextQuestion,
          onChanged: controller.updateAutoNextQuestion,
        ),
        const SizedBox(height: 8),
        _buildMultipleChoiceDelayCard(settings, controller),
        const SizedBox(height: 8),
        _buildPracticeShuffleModeSelector(settings, controller),
      ],
    );
  }

  // 基础品评项目设置区域
  Widget _buildBasicTastingSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '酒度品评',
          subtitle: '学习酒度',
          icon: Icons.thermostat,
          value: settings.enableBlindTasteAlcohol,
          onChanged: controller.updateEnableBlindTasteAlcohol,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '总分品评',
          subtitle: '学习打分',
          icon: Icons.star,
          value: settings.enableBlindTasteScore,
          onChanged: controller.updateEnableBlindTasteScore,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '设备品评',
          subtitle: '学习设备',
          icon: Icons.build,
          value: settings.enableBlindTasteEquipment,
          onChanged: controller.updateEnableBlindTasteEquipment,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '发酵剂品评',
          subtitle: '学习发酵剂',
          icon: Icons.science,
          value: settings.enableBlindTasteFermentation,
          onChanged: controller.updateEnableBlindTasteFermentation,
        ),
      ],
    );
  }

  // 品评模拟设置区域
  Widget _buildWineSimulationSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildWineSimulationCountCard(
          settings.enableWineSimulationSameWineSeries
              ? 5
              : settings.wineSimulationSampleCount,
          controller.updateWineSimulationSampleCount,
          isLocked: settings.enableWineSimulationSameWineSeries,
        ),
        const SizedBox(height: 8),
        _buildWineSimulationProbabilityCard(
          settings.enableWineSimulationSameWineSeries
              ? 0.0 // 同酒样系列模式下重复概率为0
              : settings.wineSimulationDuplicateProbability,
          controller.updateWineSimulationDuplicateProbability,
          isLocked: settings.enableWineSimulationSameWineSeries,
        ),
        const SizedBox(height: 8),
        _buildWineSimulationMaxGroupsCard(
          settings.enableWineSimulationSameWineSeries
              ? 0 // 同酒样系列模式下最大重复组数为0
              : settings.wineSimulationMaxDuplicateGroups,
          controller.updateWineSimulationMaxDuplicateGroups,
          isLocked: settings.enableWineSimulationSameWineSeries,
        ),
      ],
    );
  }

  // 同酒样系列模式设置区域
  Widget _buildSameWineSeriesSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '启用质量差模式',
          subtitle: '开启后固定同一厂家，以1-5#编号排列',
          icon: Icons.numbers,
          value: settings.enableWineSimulationSameWineSeries,
          onChanged: (value) =>
              controller.updateEnableWineSimulationSameWineSeries(value),
        ),
        // if (settings.enableWineSimulationSameWineSeries) ...[
        //   const SizedBox(height: 8),
        // Container(
        //   padding: const EdgeInsets.all(12),
        //   decoration: BoxDecoration(
        //     color: Theme.of(
        //       context,
        //     ).colorScheme.primaryContainer.withValues(alpha: 0.5),
        //     borderRadius: BorderRadius.circular(8),
        //     border: Border.all(
        //       color: Theme.of(
        //         context,
        //       ).colorScheme.primary.withValues(alpha: 0.3),
        //     ),
        //   ),
        // child: Row(
        //   children: [
        //     Icon(
        //       Icons.info_outline,
        //       color: Theme.of(context).colorScheme.primary,
        //       size: 20,
        //     ),
        //     const SizedBox(width: 8),
        // Expanded(
        //   child: Text(
        //     '同酒样系列模式说明：\n• 每轮固定5杯酒样\n以1-5#编号\n• 用于练习同厂家质量差',
        //     style: TextStyle(
        //       fontSize: 12,
        //       color: Theme.of(context).colorScheme.onPrimaryContainer,
        //       height: 1.3,
        //     ),
        //   ),
        // ),
        //   ],
        // ),
        // ),
        // ],
      ],
    );
  }

  // 品评设置区域（原函数，已重构为独立组件）
  // @Deprecated('已重构为 _buildBasicTastingSection, _buildWineSimulationSection, _buildSameWineSeriesSection')
  // Widget _buildBlindTasteSection(
  //   QuizSettings settings,
  //   SettingsController controller,
  // ) {
  //   return Column(
  //     children: [
  //       _buildSwitchTile(
  //         title: '香型品评',
  //         subtitle: '暂不品评',
  //         icon: Icons.local_florist,
  //         value: false,
  //         onChanged: null, // 禁用开关，不允许用户切换
  //       ),
  //       const SizedBox(height: 8),
  //       _buildSwitchTile(
  //         title: '酒度品评',
  //         subtitle: '学习酒度',
  //         icon: Icons.thermostat,
  //         value: settings.enableBlindTasteAlcohol,
  //         onChanged: controller.updateEnableBlindTasteAlcohol,
  //       ),
  //       const SizedBox(height: 8),
  //       _buildSwitchTile(
  //         title: '总分品评',
  //         subtitle: '学习打分',
  //         icon: Icons.star,
  //         value: settings.enableBlindTasteScore,
  //         onChanged: controller.updateEnableBlindTasteScore,
  //       ),
  //       const SizedBox(height: 8),
  //       _buildSwitchTile(
  //         title: '设备品评',
  //         subtitle: '学习设备',
  //         icon: Icons.build,
  //         value: settings.enableBlindTasteEquipment,
  //         onChanged: controller.updateEnableBlindTasteEquipment,
  //       ),
  //       const SizedBox(height: 8),
  //       _buildSwitchTile(
  //         title: '发酵剂品评',
  //         subtitle: '学习发酵剂',
  //         icon: Icons.science,
  //         value: settings.enableBlindTasteFermentation,
  //         onChanged: controller.updateEnableBlindTasteFermentation,
  //       ),
  //       const SizedBox(height: 8),
  //       _buildSwitchTile(
  //         title: '同酒样系列模式',
  //         subtitle: '固定5杯，同一酒样以1-5#编号',
  //         icon: Icons.numbers,
  //         value: settings.enableWineSimulationSameWineSeries,
  //         onChanged: (value) =>
  //             controller.updateEnableWineSimulationSameWineSeries(value),
  //       ),
  //       const SizedBox(height: 8),
  //       _buildWineSimulationCountCard(
  //         settings.enableWineSimulationSameWineSeries
  //             ? 5
  //             : settings.wineSimulationSampleCount,
  //         controller.updateWineSimulationSampleCount,
  //         isLocked: settings.enableWineSimulationSameWineSeries,
  //       ),
  //       const SizedBox(height: 8),
  //       _buildWineSimulationProbabilityCard(
  //         settings.wineSimulationDuplicateProbability,
  //         controller.updateWineSimulationDuplicateProbability,
  //       ),
  //       const SizedBox(height: 8),
  //       _buildWineSimulationMaxGroupsCard(
  //         settings.wineSimulationMaxDuplicateGroups,
  //         controller.updateWineSimulationMaxDuplicateGroups,
  //       ),
  //     ],
  //   );
  // }

  // 闪卡记忆设置区域
  Widget _buildFlashcardSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '酒样闪卡随机顺序',
          subtitle: '酒样闪卡时随机打乱酒样出现顺序',
          icon: Icons.shuffle,
          value: settings.enableFlashcardRandomOrder,
          onChanged: (value) =>
              _handleFlashcardRandomOrderChange(value, controller),
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '酒样练习随机顺序',
          subtitle: '酒样练习时随机打乱酒样出现顺序',
          icon: Icons.shuffle,
          value: settings.enableBlindTasteRandomOrder,
          onChanged: (value) =>
              _handleBlindTasteRandomOrderChange(value, controller),
        ),
      ],
    );
  }

  // 触感设置区域
  Widget _buildHapticSection() {
    final hapticSettings = ref.watch(hapticSettingsProvider);
    final hapticController = ref.read(hapticSettingsProvider.notifier);

    return _buildSwitchTile(
      title: '震动反馈',
      subtitle: '开启后在答题、切题、长按查看答案等操作时提供震动反馈',
      icon: Icons.vibration,
      value: hapticSettings.hapticEnabled,
      onChanged: hapticController.setHapticEnabled,
    );
  }

  // 进度管理区域
  Widget _buildProgressSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '自动保存进度',
          subtitle: '练习和品评模式下自动保存答题进度',
          icon: Icons.save,
          value: settings.enableProgressSave,
          onChanged: controller.updateEnableProgressSave,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '默认继续进度',
          subtitle: '有保存进度时自动继续，不显示确认对话框',
          icon: Icons.play_arrow,
          value: settings.enableDefaultContinueProgress,
          onChanged: controller.updateEnableDefaultContinueProgress,
        ),
      ],
    );
  }

  // 系统操作区域
  Widget _buildSystemActionsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          HapticManager.medium();
          _showClearProgressDialog(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                Icons.delete_sweep,
                color: Theme.of(context).colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '清除所有进度',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '删除所有已保存的答题和品评进度',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // 紧凑型开关组件
  // Widget _buildCompactSwitchTile({
  //   required String title,
  //   required IconData icon,
  //   required bool value,
  //   required Function(bool)? onChanged,
  //   bool isDisabled = false,
  // }) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //     decoration: BoxDecoration(
  //       color: isDisabled
  //           ? Theme.of(
  //               context,
  //             ).colorScheme.surfaceContainer.withValues(alpha: 0.5)
  //           : Theme.of(context).colorScheme.surfaceContainer,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Row(
  //       children: [
  //         Icon(
  //           icon,
  //           color: isDisabled
  //               ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
  //               : Theme.of(context).colorScheme.primary,
  //           size: 18,
  //         ),
  //         const SizedBox(width: 8),
  //         Expanded(
  //           child: Text(
  //             title,
  //             style: TextStyle(
  //               fontSize: 13,
  //               fontWeight: FontWeight.w500,
  //               color: isDisabled
  //                   ? Theme.of(
  //                       context,
  //                     ).colorScheme.onSurface.withValues(alpha: 0.5)
  //                   : null,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 4),
  //         Transform.scale(
  //           scale: 0.8,
  //           child: Switch(
  //             value: value,
  //             onChanged: onChanged != null && !isDisabled
  //                 ? (newValue) {
  //                     HapticManager.medium();
  //                     onChanged(newValue);
  //                   }
  //                 : null,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // 通用开关组件
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool)? onChanged, // 允许为null
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged != null
                ? (newValue) {
                    HapticManager.medium();
                    onChanged(newValue);
                  }
                : null, // 如果onChanged为null，则禁用开关
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () {
              HapticManager.medium();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              HapticManager.medium();
              controller.resetSettings();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('设置已重置')));
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _handleBlindTasteRandomOrderChange(
    bool value,
    SettingsController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value ? '开启品评随机顺序' : '关闭品评随机顺序'),
        content: Text(
          value ? '开启品评随机顺序将清空当前的品评进度，确定要继续吗？' : '关闭品评随机顺序将清空当前的品评进度，确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticManager.medium();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              HapticManager.medium();
              Navigator.of(context).pop();
              try {
                // 清空品评进度
                final progressService = ProgressService();
                await progressService.clearBlindTasteProgress();

                // 清除提供者状态
                ref.read(blindTasteProvider.notifier).reset();

                // 更新设置
                await controller.updateEnableBlindTasteRandomOrder(value);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? '已开启品评随机顺序并清空相关进度' : '已关闭品评随机顺序并清空相关进度',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _handleFlashcardRandomOrderChange(
    bool value,
    SettingsController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(value ? '开启闪卡随机顺序' : '关闭闪卡随机顺序'),
        content: Text(
          value
              ? '开启闪卡随机顺序将清空当前的闪卡记忆进度，确定要继续吗？'
              : '关闭闪卡随机顺序将清空当前的闪卡记忆进度，确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticManager.medium();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              HapticManager.medium();
              Navigator.of(context).pop();
              try {
                // 清空闪卡记忆进度
                final progressService = ProgressService();
                await progressService.clearFlashcardProgress();

                // 清除提供者状态
                ref.read(flashcardProvider.notifier).reset();

                // 更新设置
                await controller.updateEnableFlashcardRandomOrder(value);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? '已开启闪卡随机顺序并清空相关进度' : '已关闭闪卡随机顺序并清空相关进度',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除进度'),
        content: const Text('确定要清除所有已保存的答题和品评进度吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () {
              HapticManager.medium();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              HapticManager.medium();
              Navigator.of(context).pop();
              try {
                final progressService = ProgressService();
                await progressService.initialize(); // 确保初始化

                // 清除所有进度
                await progressService.clearAllProgress();

                // 同时清除提供者中的状态
                ref.read(blindTasteProvider.notifier).reset();
                ref.read(flashcardProvider.notifier).reset();

                // 验证清除是否成功
                final hasQuizProgress = await progressService.hasQuizProgress();
                final hasBlindTasteProgress = await progressService
                    .hasBlindTasteProgress();
                final hasFlashcardProgress = await progressService
                    .hasFlashcardProgress();

                if (context.mounted) {
                  if (!hasQuizProgress &&
                      !hasBlindTasteProgress &&
                      !hasFlashcardProgress) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('所有进度已清除')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('部分进度清除失败，请重试')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('清除进度失败: $e')));
                }
              }
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 练习模式乱序模式选择器
  Widget _buildPracticeShuffleModeSelector(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shuffle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '练习模式题目乱序',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '选择练习模式的题目出现顺序',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...PracticeShuffleMode.values.map((mode) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: InkWell(
                onTap: () {
                  HapticManager.medium();
                  _handlePracticeShuffleModeChange(mode, controller);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: settings.practiceShuffleMode == mode
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: settings.practiceShuffleMode == mode
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        settings.practiceShuffleMode == mode
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: settings.practiceShuffleMode == mode
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPracticeShuffleModeDisplayName(mode),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: settings.practiceShuffleMode == mode
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                            Text(
                              _getPracticeShuffleModeDescription(mode),
                              style: TextStyle(
                                fontSize: 11,
                                color: settings.practiceShuffleMode == mode
                                    ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.7)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 获取练习模式乱序模式的显示名称
  String _getPracticeShuffleModeDisplayName(PracticeShuffleMode mode) {
    switch (mode) {
      case PracticeShuffleMode.ordered:
        return '默认顺序';
      case PracticeShuffleMode.typeOrderedQuestionRandom:
        return '题型顺序，题目乱序';
      case PracticeShuffleMode.fullRandom:
        return '完全乱序';
    }
  }

  // 获取练习模式乱序模式的描述
  String _getPracticeShuffleModeDescription(PracticeShuffleMode mode) {
    switch (mode) {
      case PracticeShuffleMode.ordered:
        return '默认题库顺序';
      case PracticeShuffleMode.typeOrderedQuestionRandom:
        return '题型顺序判断、单选、多选，题型内部题目乱序';
      case PracticeShuffleMode.fullRandom:
        return '题库完全乱序';
    }
  }

  // 处理练习模式乱序模式变化
  void _handlePracticeShuffleModeChange(
    PracticeShuffleMode mode,
    SettingsController controller,
  ) {
    if (mode == ref.read(settingsProvider).practiceShuffleMode) {
      return; // 如果选择的是当前模式，不做任何操作
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更改练习题目顺序'),
        content: Text(
          '切换到"${_getPracticeShuffleModeDisplayName(mode)}"模式将清空当前练习进度。是否继续？\n\n'
          '新模式说明：${_getPracticeShuffleModeDescription(mode)}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticManager.medium();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              HapticManager.medium();
              Navigator.of(context).pop();
              try {
                // 清空练习进度
                final progressService = ProgressService();
                await progressService.clearQuizProgress();

                // 清除提供者状态
                ref.read(quizControllerProvider.notifier).reset();

                // 更新设置
                await controller.updatePracticeShuffleMode(mode);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '已切换到"${_getPracticeShuffleModeDisplayName(mode)}"模式并清空相关进度',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 兼容性方法：处理练习模式随机顺序变化
  // void _handlePracticeRandomOrderChange(
  //   bool value,
  //   SettingsController controller,
  // ) {
  //   final mode = value
  //       ? PracticeShuffleMode.fullRandom
  //       : PracticeShuffleMode.ordered;
  //   _handlePracticeShuffleModeChange(mode, controller);
  // }
}
