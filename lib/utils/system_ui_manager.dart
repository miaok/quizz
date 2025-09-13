import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 系统UI管理工具类
/// 用于控制Android系统导航栏和状态栏的显示状态
class SystemUIManager {
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // 记录当前的UI模式，用于应用恢复时重新应用
  static SystemUiMode? _currentMode;
  static List<SystemUiOverlay>? _currentOverlays;
  static SystemUiOverlayStyle? _currentStyle;

  // 标准的系统UI样式 - 支持手势导航沉浸式
  static const SystemUiOverlayStyle _standardStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    // 启用手势导航沉浸式
    systemNavigationBarContrastEnforced: false,
  );

  // 深色主题的系统UI样式
  static const SystemUiOverlayStyle _darkStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );

  /// 获取当前主题对应的系统UI样式
  static SystemUiOverlayStyle _getThemeStyle({bool isDark = false}) {
    return isDark ? _darkStyle : _standardStyle;
  }

  /// 统一的系统UI设置方法，避免重复设置
  static Future<void> _setSystemUI(
    SystemUiMode mode,
    List<SystemUiOverlay> overlays, {
    SystemUiOverlayStyle? style,
    bool force = false,
    bool isDark = false,
  }) async {
    final targetStyle = style ?? _getThemeStyle(isDark: isDark);

    // 如果设置相同且不强制更新，则跳过
    if (!force &&
        _currentMode == mode &&
        _currentOverlays != null &&
        _listEquals(_currentOverlays!, overlays) &&
        _currentStyle == targetStyle) {
      return;
    }

    _currentMode = mode;
    _currentOverlays = overlays;
    _currentStyle = targetStyle;

    await SystemChrome.setEnabledSystemUIMode(mode, overlays: overlays);
    SystemChrome.setSystemUIOverlayStyle(targetStyle);
  }

  /// 比较两个列表是否相等
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// 设置沉浸式系统UI（支持手势导航小白条）
  /// 状态栏透明，底部手势区域透明，实现真正的沉浸式体验
  static Future<void> setImmersiveUI({bool isDark = false}) async {
    await _setSystemUI(SystemUiMode.edgeToEdge, [
      SystemUiOverlay.top,
    ], isDark: isDark);
  }

  /// 隐藏系统导航栏，实现全屏沉浸式体验（用于特殊场景）
  static Future<void> hideSystemUI({bool isDark = false}) async {
    await _setSystemUI(SystemUiMode.immersiveSticky, [
      SystemUiOverlay.top,
    ], isDark: isDark);
  }

  /// 显示系统导航栏（用于特殊情况，如需要用户进行系统级操作）
  static Future<void> showSystemUI({bool isDark = false}) async {
    await _setSystemUI(
      SystemUiMode.manual,
      SystemUiOverlay.values,
      isDark: isDark,
    );
  }

  /// 为答题页面优化的系统UI设置
  /// 显示状态栏，底部手势区域透明，避免误触
  static Future<void> setQuizPageUI({bool isDark = false}) async {
    await setImmersiveUI(isDark: isDark);
  }

  /// 为结果页面优化的系统UI设置
  /// 允许用户更容易地进行导航操作
  static Future<void> setResultPageUI({bool isDark = false}) async {
    await setImmersiveUI(isDark: isDark);
  }

  /// 为设置页面优化的系统UI设置
  static Future<void> setSettingsPageUI({bool isDark = false}) async {
    await setImmersiveUI(isDark: isDark);
  }

  /// 恢复默认的系统UI设置
  static Future<void> restoreDefaultUI({bool isDark = false}) async {
    await setImmersiveUI(isDark: isDark);
  }

  /// 处理系统UI变化的监听器
  /// 当用户从屏幕边缘滑动时，系统UI可能会重新出现
  static void handleSystemUIChange({bool isDark = false}) {
    // 延迟重新设置沉浸式UI，给用户一些操作时间
    Future.delayed(_animationDuration, () {
      setImmersiveUI(isDark: isDark);
    });
  }

  /// 应用恢复时重新应用当前的系统UI设置
  /// 用于修复从后台恢复时状态栏可能不显示的问题
  static Future<void> reapplyCurrentUI() async {
    if (_currentMode != null &&
        _currentOverlays != null &&
        _currentStyle != null) {
      // 先强制显示所有系统UI，然后再应用当前设置
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // 短暂延迟后重新应用当前设置
      await Future.delayed(const Duration(milliseconds: 50));

      await _setSystemUI(
        _currentMode!,
        _currentOverlays!,
        style: _currentStyle,
        force: true, // 强制重新应用
      );
    } else {
      // 如果没有记录的状态，恢复默认UI
      await restoreDefaultUI();
    }
  }

  /// 强制刷新系统UI状态
  /// 用于解决某些情况下系统UI状态不一致的问题
  static Future<void> forceRefreshUI() async {
    // 先完全隐藏所有系统UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // 短暂延迟
    await Future.delayed(const Duration(milliseconds: 100));

    // 重新应用当前设置
    await reapplyCurrentUI();
  }

  /// 初始化系统UI管理器
  /// 在应用启动时调用，设置全局的系统UI状态
  static Future<void> initialize({bool isDark = false}) async {
    await setImmersiveUI(isDark: isDark);
  }

  /// 检查当前系统UI状态是否正确
  /// 用于在页面切换时确保状态栏始终显示
  static Future<void> ensureStatusBarVisible({bool isDark = false}) async {
    // 只有在当前设置不包含状态栏时才重新设置
    if (_currentOverlays == null ||
        !_currentOverlays!.contains(SystemUiOverlay.top)) {
      await setImmersiveUI(isDark: isDark);
    }
  }

  /// 为不同页面设置合适的安全区域内边距
  /// 支持手势导航的沉浸式体验
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      // 底部保留手势区域的安全距离，但允许内容延伸到手势区域
      bottom: 0,
    );
  }

  /// 获取屏幕可用高度（排除状态栏，包含手势区域）
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top;
  }

  /// 获取底部手势区域高度
  static double getGestureAreaHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.bottom;
  }

  /// 获取完整屏幕高度（包含状态栏和手势区域）
  static double getFullScreenHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height;
  }

  /// 检查是否使用手势导航
  static bool isGestureNavigation(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // 如果底部安全区域大于0，通常表示使用手势导航
    return mediaQuery.padding.bottom > 0;
  }
}
