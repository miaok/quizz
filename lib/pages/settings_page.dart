import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../models/settings_model.dart';
import '../services/progress_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsController = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('答题设置'),
        // 使用新的MD3主题，移除自定义背景色
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => _showResetDialog(context, settingsController),
            child: Text(
              '重置',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 答题设置分组
            _buildSettingsGroup(
              title: '答题设置',
              icon: Icons.quiz,
              children: [
                _buildQuestionCountsSection(settings, settingsController),
                const SizedBox(height: 12),
                _buildExamTimeSection(settings, settingsController),
                const SizedBox(height: 12),
                _buildQuizOptionsSection(settings, settingsController),
              ],
            ),

            const SizedBox(height: 20),

            // 品鉴设置分组
            _buildSettingsGroup(
              title: '品鉴设置',
              icon: Icons.wine_bar,
              children: [_buildBlindTasteSection(settings, settingsController)],
            ),

            const SizedBox(height: 20),

            // 系统设置分组
            _buildSettingsGroup(
              title: '系统设置',
              icon: Icons.settings,
              children: [
                _buildProgressSection(settings, settingsController),
                const SizedBox(height: 12),
                _buildSystemActionsSection(context),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 设置分组构建器
  Widget _buildSettingsGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
            ...children,
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
                ? () => onChanged(currentValue - 1)
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
                ? () => onChanged(currentValue + 1)
                : null,
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '考试时间',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: settings.examTimeMinutes > 1
                ? () => controller.updateExamTimeMinutes(
                    settings.examTimeMinutes - 1,
                  )
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
                ? () => controller.updateExamTimeMinutes(
                    settings.examTimeMinutes + 1,
                  )
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
          subtitle: '开启后选项顺序随机打乱',
          icon: Icons.shuffle,
          value: settings.shuffleOptions,
          onChanged: controller.updateShuffleOptions,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '快速切题',
          subtitle: '选择答案后自动进入下一题',
          icon: Icons.fast_forward,
          value: settings.autoNextQuestion,
          onChanged: controller.updateAutoNextQuestion,
        ),
      ],
    );
  }

  // 品鉴设置区域
  Widget _buildBlindTasteSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return Column(
      children: [
        _buildSwitchTile(
          title: '香型品鉴',
          subtitle: '包含香型判断',
          icon: Icons.local_florist,
          value: settings.enableBlindTasteAroma,
          onChanged: controller.updateEnableBlindTasteAroma,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '酒度品鉴',
          subtitle: '包含酒度判断',
          icon: Icons.thermostat,
          value: settings.enableBlindTasteAlcohol,
          onChanged: controller.updateEnableBlindTasteAlcohol,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '总分品鉴',
          subtitle: '包含总分评估',
          icon: Icons.star,
          value: settings.enableBlindTasteScore,
          onChanged: controller.updateEnableBlindTasteScore,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '设备品鉴',
          subtitle: '包含设备判断',
          icon: Icons.build,
          value: settings.enableBlindTasteEquipment,
          onChanged: controller.updateEnableBlindTasteEquipment,
        ),
        const SizedBox(height: 8),
        _buildSwitchTile(
          title: '发酵剂品鉴',
          subtitle: '包含发酵剂判断',
          icon: Icons.science,
          value: settings.enableBlindTasteFermentation,
          onChanged: controller.updateEnableBlindTasteFermentation,
        ),
      ],
    );
  }

  // 进度管理区域
  Widget _buildProgressSection(
    QuizSettings settings,
    SettingsController controller,
  ) {
    return _buildSwitchTile(
      title: '自动保存进度',
      subtitle: '练习和品鉴模式下自动保存答题进度',
      icon: Icons.save,
      value: settings.enableProgressSave,
      onChanged: controller.updateEnableProgressSave,
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
        onTap: () => _showClearProgressDialog(context),
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
                      '删除所有已保存的答题和品鉴进度',
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

  // 通用开关组件
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
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
          Switch(value: value, onChanged: onChanged),
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
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

  void _showClearProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除进度'),
        content: const Text('确定要清除所有已保存的答题和品鉴进度吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final progressService = ProgressService();
                await progressService.clearAllProgress();
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('所有进度已清除')));
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
}
