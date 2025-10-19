import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../providers/blind_taste_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/haptic_settings_provider.dart';
import '../utils/haptic_manager.dart';
import '../models/settings_model.dart';
import '../models/progress_model.dart';
import '../services/progress_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

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
        title: Text('应用设置', style: Theme.of(context).textTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticManager.medium();
            Navigator.of(context).pop();
          },
        ),
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
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '练习模式出题顺序',
          icon: Icons.sort,
          child: _buildPracticeShuffleModeSelector(settings, controller),
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
          title: '质量差模式',
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
          title: '主题模式',
          icon: Icons.brightness_6,
          child: _buildThemeModeSection(settings, controller),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: '震动管理',
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

  // 主题模式设置区域
  Widget _buildThemeModeSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        segments: const <ButtonSegment<ThemeMode>>[
          ButtonSegment<ThemeMode>(
            value: ThemeMode.system,
            label: Text('跟随系统'),
            icon: Icon(Icons.brightness_auto),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.light,
            label: Text('浅色模式'),
            icon: Icon(Icons.light_mode),
          ),
          ButtonSegment<ThemeMode>(
            value: ThemeMode.dark,
            label: Text('深色模式'),
            icon: Icon(Icons.dark_mode),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (Set<ThemeMode> newSelection) {
          if (newSelection.isNotEmpty) {
            HapticManager.medium();
            controller.updateThemeMode(newSelection.first);
          }
        },
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Microsoft YaHei', // 确保按钮文本使用微软雅黑
          ),
          selectedBackgroundColor: Theme.of(
            context,
          ).colorScheme.primaryContainer,
          selectedForegroundColor: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // 题目数量设置区域
  Widget _buildQuestionCountsSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 第一行：题型标题和图标
          Row(
            children: [
              _buildTypeHeader('判断题', icon: Icons.flaky_outlined),
              _buildTypeHeader(
                '单选题',
                icon: Icons.radio_button_checked_outlined,
              ),
              _buildTypeHeader('多选题', icon: Icons.check_box_outlined),
            ],
          ),
          const SizedBox(height: 8),
          // 第二行：数量调节器
          Row(
            children: [
              _buildCountControl(
                settings.booleanCount,
                (value) => controller.updateBooleanCount(value),
              ),
              const SizedBox(width: 8),
              _buildCountControl(
                settings.singleChoiceCount,
                (value) => controller.updateSingleChoiceCount(value),
              ),
              const SizedBox(width: 8),
              _buildCountControl(
                settings.multipleChoiceCount,
                (value) => controller.updateMultipleChoiceCount(value),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.quiz, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '总题数',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${settings.totalQuestions} 题',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 构建题型标题和图标
  Widget _buildTypeHeader(String title, {required IconData icon}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // 构建数量调节器
  Widget _buildCountControl(int currentValue, Function(int) onChanged) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // 数值显示
            Container(
              height: 32,
              alignment: Alignment.center,
              child: Text(
                '$currentValue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            // 按钮行
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: currentValue > 0
                      ? () {
                          HapticManager.medium();
                          onChanged(currentValue - 1);
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                  iconSize: 16,
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: currentValue < 100
                      ? () {
                          HapticManager.medium();
                          onChanged(currentValue + 1);
                        }
                      : null,
                  icon: const Icon(Icons.add),
                  iconSize: 16,
                ),
              ],
            ),
          ],
        ),
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
            child: Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '酒样数设置',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
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
            icon: const Icon(Icons.remove),
            iconSize: 20,
            color: currentValue > 0
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentValue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
            icon: const Icon(Icons.add),
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
                child: Row(
                  children: [
                    Icon(
                      Icons.percent,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '酒样重复概率',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${(currentValue * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.lock,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
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
            activeColor: Theme.of(context).colorScheme.primary,
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
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '最大重复组数',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
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
            icon: const Icon(Icons.remove),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isLocked)
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
            icon: const Icon(Icons.add),
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
                    Text(
                      '多选题切题延迟',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '设置多选题自动切题的延迟时间',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(delayMs / 1000).toStringAsFixed(1)}秒',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: delayMs.toDouble(),
            min: 500.0,
            max: 2000.0,
            divisions: 15,
            onChanged: (value) {
              HapticManager.selection();
              controller.updateMultipleChoiceAutoSwitchDelay(value.round());
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       '0.5秒',
          //       style: Theme.of(context).textTheme.labelSmall?.copyWith(
          //         color: Theme.of(context).colorScheme.onSurfaceVariant,
          //       ),
          //     ),
          //     Text(
          //       '2.0秒',
          //       style: Theme.of(context).textTheme.labelSmall?.copyWith(
          //         color: Theme.of(context).colorScheme.onSurfaceVariant,
          //       ),
          //     ),
          //   ],
          // ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_full,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '考试时间',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
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
            icon: const Icon(Icons.remove),
            iconSize: 20,
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: Text(
              '${settings.examTimeMinutes} 分钟',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
            icon: const Icon(Icons.add),
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
          subtitle: '理论选项乱序显示',
          icon: Icons.shuffle,
          value: settings.shuffleOptions,
          onChanged: controller.updateShuffleOptions,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '自动切题',
          subtitle: '选择答案后自动切题',
          icon: Icons.fast_forward,
          value: settings.autoNextQuestion,
          onChanged: controller.updateAutoNextQuestion,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '二次乱序',
          subtitle: '练习模式答错后，选项再次乱序',
          icon: Icons.shuffle_on_outlined,
          value: settings.enableSecondShuffle,
          onChanged: controller.updateEnableSecondShuffle,
        ),
        const SizedBox(height: 8),
        _buildMultipleChoiceDelayCard(settings, controller),
      ],
    );
  }

  // 基础品评项目设置区域
  Widget _buildBasicTastingSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _buildTastingTag(
          label: '酒度',
          icon: Icons.thermostat,
          isSelected: settings.enableBlindTasteAlcohol,
          onTap: () => controller.updateEnableBlindTasteAlcohol(
            !settings.enableBlindTasteAlcohol,
          ),
        ),
        _buildTastingTag(
          label: '总分',
          icon: Icons.star,
          isSelected: settings.enableBlindTasteScore,
          onTap: () => controller.updateEnableBlindTasteScore(
            !settings.enableBlindTasteScore,
          ),
        ),
        _buildTastingTag(
          label: '设备',
          icon: Icons.build,
          isSelected: settings.enableBlindTasteEquipment,
          onTap: () => controller.updateEnableBlindTasteEquipment(
            !settings.enableBlindTasteEquipment,
          ),
        ),
        _buildTastingTag(
          label: '发酵剂',
          icon: Icons.science,
          isSelected: settings.enableBlindTasteFermentation,
          onTap: () => controller.updateEnableBlindTasteFermentation(
            !settings.enableBlindTasteFermentation,
          ),
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
          title: '质量差模式',
          subtitle: '1-5#排列同一厂家',
          icon: Icons.numbers,
          value: settings.enableWineSimulationSameWineSeries,
          onChanged: (value) =>
              controller.updateEnableWineSimulationSameWineSeries(value),
        ),
      ],
    );
  }

  // 闪卡记忆设置区域
  Widget _buildFlashcardSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '酒样闪卡随机顺序',
          subtitle: '酒样闪卡乱序',
          icon: Icons.shuffle,
          value: settings.enableFlashcardRandomOrder,
          onChanged: (value) =>
              _handleFlashcardRandomOrderChange(value, controller),
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '品评练习随机顺序',
          subtitle: '品评练习乱序',
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
      subtitle: '开启后提供震动反馈',
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
    return Column(
      children: [
        // 单项进度清除
        _buildProgressClearItem(
          context,
          title: '清除理论练习进度',
          subtitle: '删除所有理论练习的答题进度',
          icon: Icons.quiz_outlined,
          onTap: () =>
              _showClearSpecificProgressDialog(context, ProgressType.quiz),
        ),
        const SizedBox(height: 8),
        _buildProgressClearItem(
          context,
          title: '清除酒样闪卡进度',
          subtitle: '删除所有闪卡学习进度',
          icon: Icons.style_outlined,
          onTap: () =>
              _showClearSpecificProgressDialog(context, ProgressType.flashcard),
        ),
        const SizedBox(height: 8),
        _buildProgressClearItem(
          context,
          title: '清除品评练习进度',
          subtitle: '删除所有品评练习进度',
          icon: Icons.wine_bar_outlined,
          onTap: () => _showClearSpecificProgressDialog(
            context,
            ProgressType.blindTaste,
          ),
        ),
        const SizedBox(height: 16),
        // 清除所有进度
        _buildProgressClearItem(
          context,
          title: '清除所有进度',
          subtitle: '删除所有已保存的答题和品评进度',
          icon: Icons.delete_sweep,
          isDestructive: true,
          onTap: () => _showClearProgressDialog(context),
        ),
        const SizedBox(height: 8),
        // 恢复默认设置
        _buildProgressClearItem(
          context,
          title: '恢复默认设置',
          subtitle: '将所有设置恢复为默认值',
          icon: Icons.settings_backup_restore,
          onTap: () =>
              _showResetDialog(context, ref.read(settingsProvider.notifier)),
        ),
        const SizedBox(height: 16),
        // 重新加载数据
        _buildProgressClearItem(
          context,
          title: '重新加载数据',
          subtitle: '恢复应用到初始状态，重新加载数据库',
          icon: Icons.refresh,
          isDestructive: true,
          onTap: () => _showReloadDataDialog(context),
        ),
      ],
    );
  }

  // 构建进度清除项目
  Widget _buildProgressClearItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          HapticManager.medium();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  }

  // 构建品评项目标签
  Widget _buildTastingTag({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainer;
    final contentColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () {
        HapticManager.medium();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.5)
                : colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: contentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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

  void _showClearSpecificProgressDialog(
    BuildContext context,
    ProgressType type,
  ) {
    String title;
    String content;
    String action;

    switch (type) {
      case ProgressType.quiz:
        title = '清除理论练习进度';
        content = '确定要清除所有理论练习的答题进度吗？此操作不可恢复。';
        action = '理论练习进度已清除';
        break;
      case ProgressType.flashcard:
        title = '清除酒样闪卡进度';
        content = '确定要清除所有闪卡学习进度吗？此操作不可恢复。';
        action = '闪卡学习进度已清除';
        break;
      case ProgressType.blindTaste:
        title = '清除品评练习进度';
        content = '确定要清除所有品评练习进度吗？此操作不可恢复。';
        action = '品评练习进度已清除';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
                await progressService.initialize();

                switch (type) {
                  case ProgressType.quiz:
                    await progressService.clearQuizProgress();
                    ref.read(quizControllerProvider.notifier).reset();
                    break;
                  case ProgressType.flashcard:
                    await progressService.clearFlashcardProgress();
                    ref.read(flashcardProvider.notifier).reset();
                    break;
                  case ProgressType.blindTaste:
                    await progressService.clearBlindTasteProgress();
                    ref.read(blindTasteProvider.notifier).reset();
                    break;
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(action)));
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

  void _showReloadDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新加载数据'),
        content: const Text(
          '此操作将：\n'
          '• 彻底清除所有已保存的进度数据\n'
          '• 删除所有本地设置和缓存\n'
          '• 删除并重新创建数据库文件\n'
          '• 重新初始化应用到第一次启动状态\n'
          '• 重新加载所有题库和品评数据\n\n'
          '确定要继续吗？此操作不可恢复。',
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

              // 显示加载对话框
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(child: Text('正在彻底重置应用数据，请稍候...')),
                    ],
                  ),
                ),
              );

              try {
                // 第一步：清除所有provider状态
                ref.read(blindTasteProvider.notifier).reset();
                ref.read(flashcardProvider.notifier).reset();
                ref.read(quizControllerProvider.notifier).reset();

                // 第二步：彻底清除所有SharedPreferences数据
                final progressService = ProgressService();
                await progressService.completeReset();

                // 第三步：彻底重置设置数据
                final settingsService = SettingsService();
                await settingsService.completeReset();

                // 第四步：彻底重置数据库（删除文件并重新创建）
                final databaseService = DatabaseService();
                await databaseService.completeReset();

                // 第五步：重新初始化设置提供者
                await ref.read(settingsProvider.notifier).loadSettings();

                // 关闭加载对话框
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('应用数据已彻底重置，已恢复到初始状态'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                // 关闭加载对话框
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('重置失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PracticeShuffleMode>(
        segments: <ButtonSegment<PracticeShuffleMode>>[
          ButtonSegment<PracticeShuffleMode>(
            value: PracticeShuffleMode.ordered,
            label: Text(
              _getPracticeShuffleModeDisplayName(PracticeShuffleMode.ordered),
            ),
            icon: const Icon(Icons.sort),
          ),
          ButtonSegment<PracticeShuffleMode>(
            value: PracticeShuffleMode.typeOrderedQuestionRandom,
            label: Text(
              _getPracticeShuffleModeDisplayName(
                PracticeShuffleMode.typeOrderedQuestionRandom,
              ),
            ),
            icon: const Icon(Icons.shuffle),
          ),
          ButtonSegment<PracticeShuffleMode>(
            value: PracticeShuffleMode.fullRandom,
            label: Text(
              _getPracticeShuffleModeDisplayName(
                PracticeShuffleMode.fullRandom,
              ),
            ),
            icon: const Icon(Icons.casino),
          ),
        ],
        selected: {settings.practiceShuffleMode},
        onSelectionChanged: (Set<PracticeShuffleMode> newSelection) {
          if (newSelection.isNotEmpty) {
            _handlePracticeShuffleModeChange(newSelection.first, controller);
          }
        },
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'Microsoft YaHei',
          ),
          selectedBackgroundColor: Theme.of(
            context,
          ).colorScheme.primaryContainer,
          selectedForegroundColor: Theme.of(
            context,
          ).colorScheme.onPrimaryContainer,
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // 获取练习模式乱序模式的显示名称
  String _getPracticeShuffleModeDisplayName(PracticeShuffleMode mode) {
    switch (mode) {
      case PracticeShuffleMode.ordered:
        return '默认顺序';
      case PracticeShuffleMode.typeOrderedQuestionRandom:
        return '内部乱序';
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
        return '默认题型顺序，题型内部乱序';
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
}
