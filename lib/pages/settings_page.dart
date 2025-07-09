import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';
import '../services/progress_service.dart';
import '../utils/system_ui_manager.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // 设置设置页面的系统UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemUIManager.setSettingsPageUI();
    });
  }

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
        bottom: false, // 底部不需要安全区域
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 题目数量设置
              const Text(
                '题目数量设置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildSimpleCountCard(
                '判断题',
                settings.booleanCount,
                Colors.green,
                (value) => settingsController.updateBooleanCount(value),
              ),

              const SizedBox(height: 10),

              _buildSimpleCountCard(
                '单选题',
                settings.singleChoiceCount,
                Colors.blue,
                (value) => settingsController.updateSingleChoiceCount(value),
              ),

              const SizedBox(height: 10),

              _buildSimpleCountCard(
                '多选题',
                settings.multipleChoiceCount,
                Colors.orange,
                (value) => settingsController.updateMultipleChoiceCount(value),
              ),

              const SizedBox(height: 16),

              // 总题数显示
              Card(
                child: ListTile(
                  leading: const Icon(Icons.quiz, color: Colors.purple),
                  title: const Text('总题数'),
                  trailing: Text(
                    '${settings.totalQuestions} 题',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 选项乱序设置
              Card(
                child: SwitchListTile(
                  title: const Text('选项乱序'),
                  subtitle: const Text('开启后选项顺序随机打乱'),
                  value: settings.shuffleOptions,
                  onChanged: (value) =>
                      settingsController.updateShuffleOptions(value),
                  secondary: const Icon(Icons.shuffle),
                ),
              ),

              const SizedBox(height: 16),

              // 进度保存设置
              const Text(
                '进度管理',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                child: SwitchListTile(
                  title: const Text('自动保存进度'),
                  subtitle: const Text('练习和品鉴模式下自动保存答题进度'),
                  value: settings.enableProgressSave,
                  onChanged: (value) =>
                      settingsController.updateEnableProgressSave(value),
                  secondary: const Icon(Icons.save),
                ),
              ),

              const SizedBox(height: 10),

              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_sweep, color: Colors.red),
                  title: const Text('清除所有进度'),
                  subtitle: const Text('删除所有已保存的答题和品鉴进度'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showClearProgressDialog(context),
                ),
              ),

              const SizedBox(height: 12),

              // 快速切题设置
              Card(
                child: SwitchListTile(
                  title: const Text('快速切题'),
                  subtitle: const Text('选择答案后自动进入下一题（单选题和判断题）'),
                  value: settings.autoNextQuestion,
                  onChanged: (value) =>
                      settingsController.updateAutoNextQuestion(value),
                  secondary: const Icon(Icons.fast_forward),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCountCard(
    String title,
    int currentValue,
    Color color,
    Function(int) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: currentValue > 0
                  ? () => onChanged(currentValue - 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Container(
              width: 50,
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
              icon: const Icon(Icons.add),
            ),
          ],
        ),
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
