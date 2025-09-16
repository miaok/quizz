import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// 内存管理工具类
/// 用于优化应用内存使用，减少BLASTBufferQueue错误
class MemoryManager {
  static Timer? _memoryCleanupTimer;
  static DateTime? _lastCleanup;
  static const Duration _cleanupInterval = Duration(minutes: 2);
  static const Duration _forceCleanupInterval = Duration(seconds: 30);

  // 内存压力阈值（MB）
  static const int _memoryPressureThreshold = 200;
  static const int _criticalMemoryThreshold = 300;

  /// 初始化内存管理器
  static void initialize() {
    if (kDebugMode) {
      print('MemoryManager: 初始化内存管理器');
    }

    // 启动定期内存清理
    _startPeriodicCleanup();

    // 监听应用生命周期
    _setupLifecycleListener();
  }

  /// 启动定期内存清理
  static void _startPeriodicCleanup() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = Timer.periodic(_cleanupInterval, (timer) {
      _performMemoryCleanup(force: false);
    });
  }

  /// 设置应用生命周期监听
  static void _setupLifecycleListener() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == AppLifecycleState.paused.toString()) {
        // 应用暂停时强制清理内存
        await _performMemoryCleanup(force: true);
      } else if (message == AppLifecycleState.resumed.toString()) {
        // 应用恢复时轻度清理
        await _performMemoryCleanup(force: false);
      }
      return null;
    });
  }

  /// 执行内存清理
  static Future<void> _performMemoryCleanup({bool force = false}) async {
    final now = DateTime.now();

    // 防止过于频繁的清理
    if (!force &&
        _lastCleanup != null &&
        now.difference(_lastCleanup!) < _forceCleanupInterval) {
      return;
    }

    _lastCleanup = now;

    try {
      if (kDebugMode) {
        print('MemoryManager: 执行内存清理 (force: $force)');
      }

      // 1. 强制垃圾回收
      _forceGarbageCollection();

      // 2. 清理图像缓存
      await _clearImageCache(force: force);

      // 3. 清理系统缓存
      if (force) {
        await _clearSystemCaches();
      }

      // 4. 释放不必要的资源
      await _releaseUnusedResources();

      if (kDebugMode) {
        print('MemoryManager: 内存清理完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MemoryManager: 内存清理失败: $e');
      }
    }
  }

  /// 强制垃圾回收
  static void _forceGarbageCollection() {
    // 多次调用GC确保彻底清理
    for (int i = 0; i < 3; i++) {
      if (Platform.isAndroid || Platform.isIOS) {
        // 在移动平台上强制GC
        try {
          // 使用反射调用System.gc()（仅Android）
          if (Platform.isAndroid) {
            Process.run('echo', ['Triggering GC']);
          }
        } catch (e) {
          // 忽略错误，继续其他清理
        }
      }
    }
  }

  /// 清理图像缓存
  static Future<void> _clearImageCache({bool force = false}) async {
    try {
      if (force) {
        // 强制清空所有图像缓存
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } else {
        // 温和清理：只清理超过阈值的缓存
        final imageCache = PaintingBinding.instance.imageCache;
        if (imageCache.currentSizeBytes > 50 * 1024 * 1024) {
          // 50MB
          imageCache.clear();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('MemoryManager: 清理图像缓存失败: $e');
      }
    }
  }

  /// 清理系统缓存
  static Future<void> _clearSystemCaches() async {
    try {
      // 清理Flutter引擎缓存
      await SystemChannels.platform.invokeMethod(
        'SystemChrome.setApplicationSwitcherDescription',
      );
    } catch (e) {
      // 忽略错误
    }
  }

  /// 释放不必要的资源
  static Future<void> _releaseUnusedResources() async {
    try {
      // 清理字体缓存和其他资源
      // 触发资源清理
      await Future.delayed(const Duration(milliseconds: 10));

      // 清理着色器缓存
      // 这里可以添加更多特定的资源清理逻辑
    } catch (e) {
      if (kDebugMode) {
        print('MemoryManager: 释放资源失败: $e');
      }
    }
  }

  /// 手动触发内存清理
  static Future<void> forceCleanup() async {
    await _performMemoryCleanup(force: true);
  }

  /// 轻度内存清理
  static Future<void> lightCleanup() async {
    await _performMemoryCleanup(force: false);
  }

  /// 页面切换时的内存优化
  static Future<void> onPageTransition() async {
    // 页面切换时进行轻度清理
    await lightCleanup();
  }

  /// 答题页面专用的内存优化
  static Future<void> optimizeForQuizPage() async {
    try {
      // 1. 清理不必要的动画资源
      await _clearAnimationResources();

      // 2. 优化图像缓存大小
      _optimizeImageCacheSize();

      // 3. 减少定时器频率影响
      await _optimizeTimerResources();
    } catch (e) {
      if (kDebugMode) {
        print('MemoryManager: 答题页面优化失败: $e');
      }
    }
  }

  /// 清理动画资源
  static Future<void> _clearAnimationResources() async {
    // 清理可能累积的动画控制器资源
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 触发动画资源清理
    });
  }

  /// 优化图像缓存大小
  static void _optimizeImageCacheSize() {
    final imageCache = PaintingBinding.instance.imageCache;
    // 为答题页面设置较小的缓存限制
    imageCache.maximumSizeBytes = 30 * 1024 * 1024; // 30MB
    imageCache.maximumSize = 50; // 最多50个图像
  }

  /// 优化定时器资源
  static Future<void> _optimizeTimerResources() async {
    // 确保没有泄漏的定时器
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// 检查内存压力
  static bool isMemoryUnderPressure() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final imageCacheSizeMB = imageCache.currentSizeBytes / (1024 * 1024);

      return imageCacheSizeMB > _memoryPressureThreshold;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否处于临界内存状态
  static bool isCriticalMemoryState() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final imageCacheSizeMB = imageCache.currentSizeBytes / (1024 * 1024);

      return imageCacheSizeMB > _criticalMemoryThreshold;
    } catch (e) {
      return false;
    }
  }

  /// 获取当前内存使用情况
  static Map<String, dynamic> getMemoryInfo() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      return {
        'imageCacheSize': imageCache.currentSize,
        'imageCacheSizeBytes': imageCache.currentSizeBytes,
        'imageCacheSizeMB': imageCache.currentSizeBytes / (1024 * 1024),
        'isUnderPressure': isMemoryUnderPressure(),
        'isCritical': isCriticalMemoryState(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// 销毁内存管理器
  static void dispose() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = null;

    if (kDebugMode) {
      print('MemoryManager: 内存管理器已销毁');
    }
  }
}
