import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math';

/// 设备方向管理器
class DeviceOrientationManager {
  /// 检查是否为平板设备
  static bool _isTablet(BuildContext? context) {
    if (context == null) return false;

    final data = MediaQuery.of(context);
    final screenWidth = data.size.width;
    final screenHeight = data.size.height;
    final devicePixelRatio = data.devicePixelRatio;

    // 计算物理尺寸（英寸）
    final physicalWidth = screenWidth * devicePixelRatio;
    final physicalHeight = screenHeight * devicePixelRatio;
    final diagonalInches = sqrt(physicalWidth * physicalWidth + physicalHeight * physicalHeight) / 160;

    // 大于7英寸认为是平板
    return diagonalInches > 7.0;
  }

  /// 检查是否为大屏设备（基于dp）
  static bool _isLargeScreen(BuildContext? context) {
    if (context == null) return false;

    final data = MediaQuery.of(context);
    final screenWidth = data.size.width;
    final screenHeight = data.size.height;
    final shortestSide = screenWidth < screenHeight ? screenWidth : screenHeight;

    // 短边大于600dp认为是大屏设备
    return shortestSide >= 600;
  }

  /// 检查是否应该支持横屏
  static bool shouldSupportLandscape(BuildContext? context) {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true; // 桌面平台默认支持
    }

    // Android和iOS设备：只有平板或大屏设备支持横屏
    return _isTablet(context) || _isLargeScreen(context);
  }

  /// 初始化屏幕方向设置
  static Future<void> initializeOrientations([BuildContext? context]) async {
    if (shouldSupportLandscape(context)) {
      // 平板设备：支持所有方向
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // 手机设备：只支持竖屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// 强制设置为竖屏（用于特定页面）
  static Future<void> forcePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// 恢复设备支持的方向
  static Future<void> restoreOrientations(BuildContext? context) async {
    await initializeOrientations(context);
  }

  /// 获取当前方向
  static Orientation getCurrentOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// 检查是否为横屏
  static bool isLandscape(BuildContext context) {
    return getCurrentOrientation(context) == Orientation.landscape;
  }

  /// 检查是否为竖屏
  static bool isPortrait(BuildContext context) {
    return getCurrentOrientation(context) == Orientation.portrait;
  }

  /// 获取设备类型描述
  static String getDeviceTypeDescription(BuildContext? context) {
    if (context == null) return 'Unknown';

    if (_isTablet(context)) {
      return 'Tablet';
    } else if (_isLargeScreen(context)) {
      return 'Large Phone';
    } else {
      return 'Phone';
    }
  }
}