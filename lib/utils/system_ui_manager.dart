import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 系统UI管理工具类
/// 用于控制Android系统导航栏和状态栏的显示状态
class SystemUIManager {
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // 记录当前的UI模式，用于应用恢复时重新应用
  static SystemUiMode? _currentMode;
  static List<SystemUiOverlay>? _currentOverlays;

  /// 隐藏系统导航栏，实现全屏沉浸式体验
  static Future<void> hideSystemUI() async {
    _currentMode = SystemUiMode.immersiveSticky;
    _currentOverlays = [SystemUiOverlay.top];

    await SystemChrome.setEnabledSystemUIMode(
      _currentMode!,
      overlays: _currentOverlays!, // 只保留顶部状态栏
    );

    // 设置透明的系统UI样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 显示系统导航栏（用于特殊情况，如需要用户进行系统级操作）
  static Future<void> showSystemUI() async {
    _currentMode = SystemUiMode.manual;
    _currentOverlays = SystemUiOverlay.values;

    await SystemChrome.setEnabledSystemUIMode(
      _currentMode!,
      overlays: _currentOverlays!, // 显示所有系统UI
    );
  }

  /// 为答题页面优化的系统UI设置
  /// 显示状态栏，隐藏导航栏，避免误触
  static Future<void> setQuizPageUI() async {
    _currentMode = SystemUiMode.edgeToEdge;
    _currentOverlays = [SystemUiOverlay.top];

    await SystemChrome.setEnabledSystemUIMode(
      _currentMode!,
      overlays: _currentOverlays!,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 为结果页面优化的系统UI设置
  /// 允许用户更容易地进行导航操作
  static Future<void> setResultPageUI() async {
    _currentMode = SystemUiMode.edgeToEdge;
    _currentOverlays = [SystemUiOverlay.top];

    await SystemChrome.setEnabledSystemUIMode(
      _currentMode!,
      overlays: _currentOverlays!,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 为设置页面优化的系统UI设置
  static Future<void> setSettingsPageUI() async {
    _currentMode = SystemUiMode.edgeToEdge;
    _currentOverlays = [SystemUiOverlay.top];

    await SystemChrome.setEnabledSystemUIMode(
      _currentMode!,
      overlays: _currentOverlays!,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// 恢复默认的系统UI设置
  static Future<void> restoreDefaultUI() async {
    _currentMode = SystemUiMode.edgeToEdge;
    _currentOverlays = [SystemUiOverlay.top];

    await SystemChrome.setEnabledSystemUIMode(
      _currentMode!,
      overlays: _currentOverlays!,
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
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
    if (_currentMode != null && _currentOverlays != null) {
      // 先强制显示所有系统UI，然后再应用当前设置
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // 短暂延迟后重新应用当前设置
      await Future.delayed(const Duration(milliseconds: 50));

      await SystemChrome.setEnabledSystemUIMode(
        _currentMode!,
        overlays: _currentOverlays!,
      );

      // 重新应用系统UI样式
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
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
