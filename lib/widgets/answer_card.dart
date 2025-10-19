import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// 是否被用户标记
  bool get isFlagged => false;
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

  /// 长按项目时的回调
  final Function(int index)? onItemLongPressed;

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
    this.onItemLongPressed,
    this.crossAxisCount = 5,
    this.scrollController,
    this.showWrongAnswerColor = true,
  });
}

/// 通用答题卡组件
class AnswerCard extends StatefulWidget {
  final List<AnswerCardItem> items;
  final AnswerCardConfig config;

  const AnswerCard({super.key, required this.items, required this.config});

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  String? _activeFilterLabel;

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

    // 根据当前筛选器过滤项目
    final filteredItems = _filterItems(widget.items);

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
                  widget.config.icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: isLandscape ? 20 : 24,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.config.title,
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
          // 使用Consumer包裹，以便在标记题目后能即时刷新UI
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(dynamicPadding),
              child: Consumer(
                builder: (context, ref, child) {
                  // 这里重新watch一下items，确保它们是最新的
                  return GridView.builder(
                    controller: widget.config.scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: dynamicCrossAxisCount,
                      crossAxisSpacing: dynamicSpacing,
                      mainAxisSpacing: dynamicSpacing,
                      childAspectRatio: 1,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildAnswerCardItem(
                        context,
                        filteredItems[index],
                        index,
                        isLandscape,
                      );
                    },
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
              children: [
                _buildAllFilterButton(isLandscape), // 添加“全部”按钮
                ...widget.config.stats
                    .map((stat) => _buildStatItem(context, stat, isLandscape))
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 过滤项目
  List<AnswerCardItem> _filterItems(List<AnswerCardItem> allItems) {
    if (_activeFilterLabel == null) {
      return allItems;
    }

    switch (_activeFilterLabel) {
      case '当前':
        return allItems.where((item) => item.isCurrent).toList();
      case '已答':
      case '已学':
      case '已完成':
        return allItems.where((item) => item.isCompleted).toList();
      case '未答':
      case '未学':
      case '未完成':
        return allItems.where((item) => !item.isCompleted).toList();
      case '错误':
        return allItems.where((item) => item.isFirstTimeWrong).toList();
      case '标记': // 为未来可能的标记筛选做准备
        return allItems.where((item) => item.isFlagged).toList();
      default:
        return allItems;
    }
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

    if (item.isCurrent && _activeFilterLabel != '当前') {
      backgroundColor = Theme.of(context).colorScheme.secondary;
      textColor = Theme.of(context).colorScheme.onSecondary;
    } else if (item.isFirstTimeWrong && widget.config.showWrongAnswerColor) {
      // 新增：错题显示红色背景（需要开启设置）
      backgroundColor = Colors.red;
      textColor = Colors.white;
    } else if (item.isFlagged) {
      backgroundColor = Colors.amber;
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
      onLongPress: () {
        if (widget.config.onItemLongPressed != null) {
          HapticManager.longPress();
          // 注意：长按标记的是原始列表的索引
          final originalIndex = widget.items.indexOf(item);
          if (originalIndex != -1) {
            widget.config.onItemLongPressed!(originalIndex);
          }
        }
      },
      onTap: () {
        HapticManager.selectQuestion();
        // 注意：点击跳转的是原始列表的索引
        final originalIndex = widget.items.indexOf(item);
        if (originalIndex != -1) {
          widget.config.onItemTapped(originalIndex);
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: item.isCurrent && _activeFilterLabel != '当前'
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
          if (item.isFlagged)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.flag,
                color: Colors.white.withOpacity(0.8),
                size: isLandscape ? 10 : 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    AnswerCardStats stat,
    bool isLandscape,
  ) {
    final iconSize = isLandscape ? 20.0 : 24.0;
    final labelFontSize = isLandscape ? 10.0 : 12.0;
    final isActive = _activeFilterLabel == stat.label;

    return GestureDetector(
      onTap: () {
        HapticManager.selection();
        setState(() {
          if (isActive) {
            _activeFilterLabel = null; // 再次点击取消筛选
          } else {
            _activeFilterLabel = stat.label;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? stat.color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: stat.color, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconSize * 0.6,
                  height: iconSize * 0.6,
                  decoration: BoxDecoration(
                    color: stat.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${stat.count}',
                  style: TextStyle(
                    color: stat.color,
                    fontSize: labelFontSize + 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 2 : 4),
            Text(
              stat.label,
              style: TextStyle(
                fontSize: labelFontSize,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllFilterButton(bool isLandscape) {
    final labelFontSize = isLandscape ? 10.0 : 12.0;
    final isActive = _activeFilterLabel == null;
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: () {
        HapticManager.selection();
        setState(() {
          _activeFilterLabel = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps, size: labelFontSize + 4, color: color),
            SizedBox(height: isLandscape ? 2 : 4),
            Text(
              '全部',
              style: TextStyle(
                fontSize: labelFontSize,
                color: color,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
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
