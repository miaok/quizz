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

  // 标准的系统UI样式
  static const SystemUiOverlayStyle _standardStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  /// 统一的系统UI设置方法，避免重复设置
  static Future<void> _setSystemUI(
    SystemUiMode mode,
    List<SystemUiOverlay> overlays, {
    SystemUiOverlayStyle? style,
    bool force = false,
  }) async {
    final targetStyle = style ?? _standardStyle;

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

  /// 隐藏系统导航栏，实现全屏沉浸式体验
  static Future<void> hideSystemUI() async {
    await _setSystemUI(SystemUiMode.immersiveSticky, [SystemUiOverlay.top]);
  }

  /// 显示系统导航栏（用于特殊情况，如需要用户进行系统级操作）
  static Future<void> showSystemUI() async {
    await _setSystemUI(SystemUiMode.manual, SystemUiOverlay.values);
  }

  /// 为答题页面优化的系统UI设置
  /// 显示状态栏，隐藏导航栏，避免误触
  static Future<void> setQuizPageUI() async {
    await _setSystemUI(SystemUiMode.edgeToEdge, [SystemUiOverlay.top]);
  }

  /// 为结果页面优化的系统UI设置
  /// 允许用户更容易地进行导航操作
  static Future<void> setResultPageUI() async {
    await _setSystemUI(SystemUiMode.edgeToEdge, [SystemUiOverlay.top]);
  }

  /// 为设置页面优化的系统UI设置
  static Future<void> setSettingsPageUI() async {
    await _setSystemUI(SystemUiMode.edgeToEdge, [SystemUiOverlay.top]);
  }

  /// 恢复默认的系统UI设置
  static Future<void> restoreDefaultUI() async {
    await _setSystemUI(SystemUiMode.edgeToEdge, [SystemUiOverlay.top]);
  }

  /// 处理系统UI变化的监听器
  /// 当用户从屏幕边缘滑动时，系统UI可能会重新出现
  static void handleSystemUIChange() {
    // 延迟重新隐藏系统UI，给用户一些操作时间
    Future.delayed(_animationDuration, () {
      hideSystemUI();
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
  static Future<void> initialize() async {
    await _setSystemUI(SystemUiMode.edgeToEdge, [SystemUiOverlay.top]);
  }

  /// 检查当前系统UI状态是否正确
  /// 用于在页面切换时确保状态栏始终显示
  static Future<void> ensureStatusBarVisible() async {
    // 只有在当前设置不包含状态栏时才重新设置
    if (_currentOverlays == null ||
        !_currentOverlays!.contains(SystemUiOverlay.top)) {
      await _setSystemUI(SystemUiMode.edgeToEdge, [
        SystemUiOverlay.top,
      ], force: true);
    }
  }

  /// 为不同页面设置合适的安全区域内边距
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: 0, // 底部不需要内边距，因为我们隐藏了导航栏
    );
  }

  /// 获取屏幕可用高度（排除状态栏）
  static double getAvailableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top;
  }
}
