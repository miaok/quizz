import 'package:flutter/material.dart';
import '../utils/haptic_manager.dart';

/// 答题卡项目数据接口
abstract class AnswerCardItem {
  /// 获取项目唯一标识
  String get id;

  /// 获取项目显示序号（从1开始）
  int get displayNumber;

  /// 是否为当前项目
  bool get isCurrent;

  /// 是否已完成/已答题/已学习
  bool get isCompleted;

  /// 是否已有答案（可选，用于区分完成状态和答题状态）
  bool get hasAnswer => isCompleted;

  /// 是否是第一次答错的题目（仅在理论练习模式下）
  bool get isFirstTimeWrong => false;
}

/// 答题卡统计数据
class AnswerCardStats {
  final String label;
  final int count;
  final Color color;

  const AnswerCardStats({
    required this.label,
    required this.count,
    required this.color,
  });
}

/// 答题卡配置
class AnswerCardConfig {
  /// 答题卡标题
  final String title;

  /// 答题卡图标
  final IconData icon;

  /// 总进度文本格式 (例如: "${completedCount}/${totalCount}")
  //final String Function(int completedCount, int totalCount) progressTextBuilder;

  /// 底部统计项目列表
  final List<AnswerCardStats> stats;

  /// 网格列数
  final int crossAxisCount;

  /// 点击项目时的回调
  final Function(int index) onItemTapped;

  /// 滚动控制器
  final ScrollController? scrollController;

  /// 是否显示错题颜色（仅在理论练习模式下生效）
  final bool showWrongAnswerColor;

  const AnswerCardConfig({
    required this.title,
    required this.icon,
    //required this.progressTextBuilder,
    required this.stats,
    required this.onItemTapped,
    this.crossAxisCount = 5,
    this.scrollController,
    this.showWrongAnswerColor = true,
  });
}

/// 通用答题卡组件
class AnswerCard extends StatelessWidget {
  final List<AnswerCardItem> items;
  final AnswerCardConfig config;

  const AnswerCard({super.key, required this.items, required this.config});

  @override
  Widget build(BuildContext context) {
    //final completedCount = items.where((item) => item.isCompleted).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 根据屏幕方向和尺寸动态调整列数
    final dynamicCrossAxisCount = _getDynamicCrossAxisCount(
      screenWidth,
      isLandscape,
    );
    final dynamicSpacing = isLandscape ? 8.0 : 10.0;
    final dynamicPadding = isLandscape ? 12.0 : 16.0;

    return Container(
      height: MediaQuery.of(context).size.height * (isLandscape ? 0.8 : 0.7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // 顶部拖拽指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 标题栏
          Padding(
            padding: EdgeInsets.all(dynamicPadding),
            child: Row(
              children: [
                Icon(
                  config.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: isLandscape ? 20 : 24,
                ),
                const SizedBox(width: 6),
                Text(
                  config.title,
                  style: TextStyle(
                    fontSize: isLandscape ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Text(
                //   config.progressTextBuilder(completedCount, items.length),
                //   style: TextStyle(
                //     fontSize: isLandscape ? 14 : 16,
                //     color: Colors.grey[600],
                //     fontWeight: FontWeight.w500,
                //   ),
                // ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 题目网格
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(dynamicPadding),
              child: GridView.builder(
                controller: config.scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: dynamicCrossAxisCount,
                  crossAxisSpacing: dynamicSpacing,
                  mainAxisSpacing: dynamicSpacing,
                  childAspectRatio: 1,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _buildAnswerCardItem(
                    context,
                    items[index],
                    index,
                    isLandscape,
                  );
                },
              ),
            ),
          ),

          // 底部统计信息
          Container(
            padding: EdgeInsets.all(dynamicPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : Colors.grey[50],
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2)
                      : Colors.grey[200]!,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: config.stats
                  .map((stat) => _buildStatItem(context, stat, isLandscape))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 根据屏幕宽度和方向动态计算列数
  int _getDynamicCrossAxisCount(double screenWidth, bool isLandscape) {
    if (isLandscape) {
      // 横屏模式：根据屏幕宽度调整
      if (screenWidth > 1200) {
        return 12; // 大屏设备
      } else if (screenWidth > 900) {
        return 10; // 平板横屏
      } else if (screenWidth > 600) {
        return 8; // 小平板横屏
      } else {
        return 7; // 手机横屏
      }
    } else {
      // 竖屏模式：保持原有逻辑
      if (screenWidth > 400) {
        return 6; // 大屏手机
      } else {
        return 5; // 标准手机
      }
    }
  }

  Widget _buildAnswerCardItem(
    BuildContext context,
    AnswerCardItem item,
    int index,
    bool isLandscape,
  ) {
    Color backgroundColor;
    Color textColor;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (item.isCurrent) {
      backgroundColor = Theme.of(context).colorScheme.secondary;
      textColor = Theme.of(context).colorScheme.onSecondary;
    } else if (item.isFirstTimeWrong && config.showWrongAnswerColor) {
      // 新增：错题显示红色背景（需要开启设置）
      backgroundColor = Colors.red;
      textColor = Colors.white;
    } else if (item.isCompleted) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      textColor = Theme.of(context).colorScheme.onPrimary;
    } else {
      // 未完成的项目在深色模式下使用更明显的对比色
      backgroundColor = isDarkMode
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : Theme.of(context).colorScheme.surfaceContainer;
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    // 根据屏幕方向调整按钮大小和字体
    final buttonSize = isLandscape ? 32.0 : 40.0;
    final fontSize = isLandscape ? 12.0 : 14.0;
    final borderRadius = isLandscape ? 6.0 : 8.0;

    return GestureDetector(
      onTap: () {
        HapticManager.selectQuestion();
        config.onItemTapped(index);
        Navigator.of(context).pop(); // 关闭答题卡
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: item.isCurrent
              ? Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: isLandscape ? 1.5 : 2,
                )
              : null,
        ),
        child: Center(
          child: Text(
            '${item.displayNumber}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    AnswerCardStats stat,
    bool isLandscape,
  ) {
    final iconSize = isLandscape ? 20.0 : 24.0;
    final fontSize = isLandscape ? 10.0 : 12.0;
    final labelFontSize = isLandscape ? 10.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(color: stat.color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${stat.count}',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: isLandscape ? 2 : 4),
        Text(
          stat.label,
          style: TextStyle(
            fontSize: labelFontSize,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// 答题卡显示辅助函数
class AnswerCardHelper {
  /// 显示答题卡模态弹窗
  static void showAnswerCard(
    BuildContext context,
    List<AnswerCardItem> items,
    AnswerCardConfig config,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnswerCard(items: items, config: config),
    );
  }

  /// 自动滚动到当前项目（用于答题卡展开后的延迟滚动）
  static void scrollToCurrentItem(
    ScrollController controller,
    int currentIndex, {
    int? crossAxisCount,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double childAspectRatio = 1.0,
    double? padding,
    required BuildContext context,
  }) {
    if (!controller.hasClients) return;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // 使用动态参数，如果没有提供则计算默认值
    final dynamicCrossAxisCount =
        crossAxisCount ??
        _getDynamicCrossAxisCountStatic(screenWidth, isLandscape);
    final dynamicSpacing = crossAxisSpacing ?? (isLandscape ? 8.0 : 10.0);
    final dynamicMainSpacing = mainAxisSpacing ?? (isLandscape ? 8.0 : 10.0);
    final dynamicPadding = padding ?? (isLandscape ? 12.0 : 16.0);

    // 计算当前项目所在的行
    final int row = currentIndex ~/ dynamicCrossAxisCount;

    // 获取GridView的可用宽度
    final double availableWidth = screenWidth - (dynamicPadding * 2);

    // 计算每个item的实际尺寸
    final double itemWidth =
        (availableWidth - (dynamicSpacing * (dynamicCrossAxisCount - 1))) /
        dynamicCrossAxisCount;
    final double itemHeight = itemWidth / childAspectRatio;

    // 计算目标滚动位置，让当前项目所在行居中显示
    final double targetOffset =
        (row * (itemHeight + dynamicMainSpacing)) -
        (itemHeight + dynamicMainSpacing);

    // 确保滚动位置在有效范围内
    final double maxScrollExtent = controller.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScrollExtent);

    // 执行滚动动画
    controller.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  // 静态版本的动态列数计算方法
  static int _getDynamicCrossAxisCountStatic(
    double screenWidth,
    bool isLandscape,
  ) {
    if (isLandscape) {
      // 横屏模式：根据屏幕宽度调整
      if (screenWidth > 1200) {
        return 12; // 大屏设备
      } else if (screenWidth > 900) {
        return 10; // 平板横屏
      } else if (screenWidth > 600) {
        return 8; // 小平板横屏
      } else {
        return 7; // 手机横屏
      }
    } else {
      // 竖屏模式：保持原有逻辑
      if (screenWidth > 400) {
        return 6; // 大屏手机
      } else {
        return 5; // 标准手机
      }
    }
  }
}
