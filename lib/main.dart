import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'services/blind_taste_service.dart';
import 'utils/system_ui_manager.dart';
import 'utils/memory_manager.dart';
import 'utils/device_orientation_manager.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化系统UI管理器
  await SystemUIManager.initialize();

  // 初始化内存管理器
  MemoryManager.initialize();

  // 初始化屏幕方向（将在第一个页面构建后根据设备类型调整）
  await DeviceOrientationManager.initializeOrientations();

  // 初始化服务
  await DatabaseService().initialize();
  await SettingsService().initialize();
  await BlindTasteService().initialize();

  // 启动应用
  runApp(const ProviderScope(child: MyQuizApp()));
}

class MyQuizApp extends StatefulWidget {
  const MyQuizApp({super.key});

  @override
  State<MyQuizApp> createState() => _MyQuizAppState();
}

class _MyQuizAppState extends State<MyQuizApp> with WidgetsBindingObserver {
  bool _hasInitializedUI = false;
  bool _hasInitializedOrientation = false;
  Brightness? _lastBrightness;

  @override
  void initState() {
    super.initState();
    // 添加应用生命周期监听器
    WidgetsBinding.instance.addObserver(this);
    _lastBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  @override
  void dispose() {
    // 移除应用生命周期监听器
    WidgetsBinding.instance.removeObserver(this);
    // 销毁内存管理器
    MemoryManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用恢复时，确保系统UI状态正确
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _updateSystemUI(force: true);
      });
      // 应用恢复时进行内存优化
      MemoryManager.lightCleanup();
    } else if (state == AppLifecycleState.paused) {
      // 应用暂停时强制清理内存
      MemoryManager.forceCleanup();
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final currentBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    // 只有当亮度真正改变时才更新
    if (_lastBrightness != currentBrightness) {
      _lastBrightness = currentBrightness;
      _updateSystemUI();
    }
  }

  void _updateSystemUI({bool force = false}) {
    // 避免重复调用
    if (!force && _hasInitializedUI) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final brightness = _lastBrightness ?? Brightness.light;
        final isDark = brightness == Brightness.dark;
        SystemUIManager.setImmersiveUI(isDark: isDark);
        _hasInitializedUI = true;
      }
    });
  }

  void _initializeOrientation({bool force = false}) {
    if (!force && _hasInitializedOrientation) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await DeviceOrientationManager.initializeOrientations(context);
        _hasInitializedOrientation = true;
      }
    });
  }

  // 品牌主色 - #63A002 绿色
  static const Color _brandGreen = Color(0xFF63A002);

  // 构建浅色主题
  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandGreen,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: null, // 使用系统默认字体

      // 文本主题 - 确保所有文本都使用系统默认字体
      textTheme: const TextTheme().apply(
        fontFamily: null, // 强制所有文本使用系统默认字体
      ),

      // AppBar主题
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: null, // 确保使用系统默认字体
        ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Chip主题
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSurface, fontFamily: null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 构建深色主题
  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandGreen,
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: null, // 使用系统默认字体

      // 文本主题 - 确保所有文本都使用系统默认字体
      textTheme: const TextTheme().apply(
        fontFamily: null, // 强制所有文本使用系统默认字体
      ),

      // AppBar主题
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: null, // 确保使用系统默认字体
        ),
      ),

      // 卡片主题
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 按钮主题
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // 输入框主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Chip主题
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(color: colorScheme.onSurface, fontFamily: null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 只在首次构建时更新系统UI和初始化方向
    if (!_hasInitializedUI) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSystemUI();
      });
    }

    if (!_hasInitializedOrientation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeOrientation();
      });
    }

    return MaterialApp.router(
      title: 'QUIZ',
      debugShowCheckedModeBanner: false,

      // 路由配置
      routerConfig: appRouter,

      // 主题模式 - 自动跟随系统
      themeMode: ThemeMode.system,

      // 浅色主题
      theme: _buildLightTheme(),

      // 深色主题
      darkTheme: _buildDarkTheme(),

      // 构建器，用于处理系统UI更新
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
