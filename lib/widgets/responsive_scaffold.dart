import 'package:flutter/material.dart';
import '../utils/responsive_layout.dart';

/// 响应式Scaffold组件，针对平板横屏优化
class ResponsiveScaffold extends StatelessWidget {
  final Widget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool safeAreaBottom;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        // 对于平板横屏，使用特殊布局
        if (deviceType == DeviceType.tabletLandscape) {
          return _buildTabletLandscapeLayout(context);
        }

        // 其他设备使用标准布局
        return _buildStandardLayout(context);
      },
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return Scaffold(
      appBar: appBar as PreferredSizeWidget?,
      body: SafeArea(
        bottom: safeAreaBottom,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildTabletLandscapeLayout(BuildContext context) {
    return Scaffold(
      appBar: appBar as PreferredSizeWidget?,
      body: SafeArea(
        bottom: safeAreaBottom,
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          maxWidth: 1200, // 限制最大宽度避免内容过宽
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: bottomNavigationBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
    );
  }
}

/// 响应式双列布局
class ResponsiveTwoColumnLayout extends StatelessWidget {
  final Widget leftColumn;
  final Widget rightColumn;
  final double ratio; // 左右列宽度比例
  final double spacing; // 列间距

  const ResponsiveTwoColumnLayout({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
    this.ratio = 0.5, // 默认1:1
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, deviceType) {
        // 只有在平板横屏和桌面设备上使用双列布局
        if (deviceType == DeviceType.tabletLandscape ||
            deviceType == DeviceType.desktop ||
            deviceType == DeviceType.largeDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: (ratio * 100).round(),
                child: leftColumn,
              ),
              SizedBox(width: spacing),
              Expanded(
                flex: ((1 - ratio) * 100).round(),
                child: rightColumn,
              ),
            ],
          );
        }

        // 手机和平板竖屏使用单列布局
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            leftColumn,
            SizedBox(height: spacing),
            rightColumn,
          ],
        );
      },
    );
  }
}

/// 响应式网格布局
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileCrossAxisCount;
  final int? tabletCrossAxisCount;
  final int? tabletLandscapeCrossAxisCount;
  final int? desktopCrossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileCrossAxisCount = 2,
    this.tabletCrossAxisCount,
    this.tabletLandscapeCrossAxisCount,
    this.desktopCrossAxisCount,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = ResponsiveLayout.getCrossAxisCount(
      context,
      mobile: mobileCrossAxisCount,
      tablet: tabletCrossAxisCount,
      tabletLandscape: tabletLandscapeCrossAxisCount,
      desktop: desktopCrossAxisCount,
    );

    final responsivePadding = padding ?? ResponsiveLayout.getPadding(context);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: responsivePadding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}

/// 响应式列表
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double? itemSpacing;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.itemSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveLayout.getPadding(context);
    final spacing = itemSpacing ?? (ResponsiveLayout.isTabletLandscape(context) ? 12 : 8);

    return ListView.separated(
      padding: responsivePadding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: spacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}