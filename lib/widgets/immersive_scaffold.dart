import 'package:flutter/material.dart';
import '../utils/system_ui_manager.dart';

/// 沉浸式Scaffold组件
/// 自动处理手势导航区域的安全距离，确保UI组件不被遮挡
class ImmersiveScaffold extends StatefulWidget {
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool automaticallyImplyLeading;
  final bool primary;

  const ImmersiveScaffold({
    super.key,
    this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.automaticallyImplyLeading = true,
    this.primary = true,
  });

  @override
  State<ImmersiveScaffold> createState() => _ImmersiveScaffoldState();
}

class _ImmersiveScaffoldState extends State<ImmersiveScaffold> {
  // 移除WidgetsBindingObserver，避免与main.dart中的重复监听
  // SystemUI管理现在由应用级别统一处理

  @override
  void initState() {
    super.initState();
    // 移除系统UI更新调用，避免频繁调用
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      body: widget.body != null ? _buildSafeBody() : null,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      drawer: widget.drawer,
      endDrawer: widget.endDrawer,
      bottomNavigationBar: widget.bottomNavigationBar,
      bottomSheet: widget.bottomSheet,
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      extendBody: true, // 始终扩展到底部
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      primary: widget.primary,
    );
  }

  Widget _buildSafeBody() {
    return SafeArea(
      top: false, // AppBar已经处理了顶部安全区域
      bottom: true, // 保护底部内容不被手势区域遮挡
      child: widget.body!,
    );
  }
}

/// 沉浸式页面包装器
/// 为页面内容提供合适的内边距，避免被手势区域遮挡
class ImmersivePageWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool avoidBottomGesture;

  const ImmersivePageWrapper({
    super.key,
    required this.child,
    this.padding,
    this.avoidBottomGesture = true,
  });

  @override
  Widget build(BuildContext context) {
    //final mediaQuery = MediaQuery.of(context);
    final gestureHeight = SystemUIManager.getGestureAreaHeight(context);

    EdgeInsets effectivePadding = padding ?? EdgeInsets.zero;

    if (avoidBottomGesture && gestureHeight > 0) {
      // 为手势区域添加额外的底部内边距
      effectivePadding = effectivePadding.copyWith(
        bottom: effectivePadding.bottom + gestureHeight,
      );
    }

    return Padding(padding: effectivePadding, child: child);
  }
}

/// 沉浸式底部按钮栏
/// 自动处理手势导航区域的安全距离
class ImmersiveBottomBar extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const ImmersiveBottomBar({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    //final mediaQuery = MediaQuery.of(context);
    final gestureHeight = SystemUIManager.getGestureAreaHeight(context);

    final defaultPadding = EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: 16 + gestureHeight, // 为手势区域预留空间
    );

    return Container(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      padding: padding ?? defaultPadding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}

/// 沉浸式浮动操作按钮
/// 自动调整位置以避开手势区域
class ImmersiveFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? child;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsets? margin;

  const ImmersiveFloatingActionButton({
    super.key,
    this.onPressed,
    this.child,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final gestureHeight = SystemUIManager.getGestureAreaHeight(context);

    final defaultMargin = EdgeInsets.only(
      bottom: 16 + gestureHeight, // 为手势区域预留空间
    );

    return Container(
      margin: margin ?? defaultMargin,
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        child: child,
      ),
    );
  }
}
