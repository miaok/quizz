import 'package:flutter/material.dart';

/// 响应式布局工具类
class ResponsiveLayout {
  /// 断点定义
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  static const double largeDesktopBreakpoint = 1440;

  /// 获取设备类型
  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;

    if (screenWidth < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (screenWidth < tabletBreakpoint) {
      return orientation == Orientation.landscape
          ? DeviceType.tabletLandscape
          : DeviceType.mobile;
    } else if (screenWidth < desktopBreakpoint) {
      return orientation == Orientation.landscape
          ? DeviceType.tabletLandscape
          : DeviceType.tablet;
    } else if (screenWidth < largeDesktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// 检查是否为手机
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// 检查是否为平板
  static bool isTablet(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.tablet || deviceType == DeviceType.tabletLandscape;
  }

  /// 检查是否为平板横屏
  static bool isTabletLandscape(BuildContext context) {
    return getDeviceType(context) == DeviceType.tabletLandscape;
  }

  /// 检查是否为桌面
  static bool isDesktop(BuildContext context) {
    final deviceType = getDeviceType(context);
    return deviceType == DeviceType.desktop || deviceType == DeviceType.largeDesktop;
  }

  /// 根据设备类型返回值
  static T valueWhen<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? tabletLandscape,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.tabletLandscape:
        return tabletLandscape ?? tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tabletLandscape ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tabletLandscape ?? tablet ?? mobile;
    }
  }

  /// 获取列数
  static int getColumns(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? tabletLandscape,
    int? desktop,
    int? largeDesktop,
  }) {
    return valueWhen<int>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      tabletLandscape: tabletLandscape,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// 获取内边距
  static EdgeInsets getPadding(BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(16),
    EdgeInsets? tablet,
    EdgeInsets? tabletLandscape,
    EdgeInsets? desktop,
    EdgeInsets? largeDesktop,
  }) {
    return valueWhen<EdgeInsets>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      tabletLandscape: tabletLandscape,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// 获取最大宽度
  static double? getMaxWidth(BuildContext context, {
    double? mobile,
    double? tablet,
    double? tabletLandscape,
    double? desktop,
    double? largeDesktop,
  }) {
    return valueWhen<double?>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      tabletLandscape: tabletLandscape,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// 获取网格交叉轴数量
  static int getCrossAxisCount(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? tabletLandscape,
    int? desktop,
    int? largeDesktop,
  }) {
    return getColumns(
      context,
      mobile: mobile,
      tablet: tablet,
      tabletLandscape: tabletLandscape,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// 获取字体大小缩放
  static double getFontScale(BuildContext context) {
    return valueWhen<double>(
      context: context,
      mobile: 1.0,
      tablet: 1.1,
      tabletLandscape: 1.2,
      desktop: 1.3,
      largeDesktop: 1.4,
    );
  }

  /// 检查是否应该使用双列布局
  static bool shouldUseTwoColumns(BuildContext context) {
    return isTabletLandscape(context) || isDesktop(context);
  }

  /// 检查是否应该显示侧边栏
  static bool shouldShowSidebar(BuildContext context) {
    return isDesktop(context);
  }

  /// 获取AppBar高度
  static double getAppBarHeight(BuildContext context) {
    return valueWhen<double>(
      context: context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8,
      tabletLandscape: kToolbarHeight + 8,
      desktop: kToolbarHeight + 12,
      largeDesktop: kToolbarHeight + 16,
    );
  }
}

/// 设备类型枚举
enum DeviceType {
  mobile,
  tablet,
  tabletLandscape,
  desktop,
  largeDesktop,
}

/// 响应式构建器
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveLayout.getDeviceType(context);
    return builder(context, deviceType);
  }
}

/// 响应式容器
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final responsivePadding = padding ?? ResponsiveLayout.getPadding(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(24),
      tabletLandscape: const EdgeInsets.all(32),
      desktop: const EdgeInsets.all(40),
    );

    final responsiveMaxWidth = maxWidth ?? ResponsiveLayout.getMaxWidth(
      context,
      mobile: null,
      tablet: 800,
      tabletLandscape: 1000,
      desktop: 1200,
      largeDesktop: 1400,
    );

    Widget content = Padding(
      padding: responsivePadding,
      child: child,
    );

    if (responsiveMaxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsiveMaxWidth),
          child: content,
        ),
      );
    }

    return content;
  }
}