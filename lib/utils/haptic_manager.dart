import 'package:flutter/services.dart';

/// 触感反馈管理器
/// 统一管理应用中的所有触感反馈效果
class HapticManager {
  static bool _hapticEnabled = true;

  /// 获取触感反馈是否启用
  static bool get isHapticEnabled => _hapticEnabled;

  /// 设置触感反馈开关
  static void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  /// 更新设置
  static void updateSettings({
    required bool hapticEnabled,
  }) {
    _hapticEnabled = hapticEnabled;
  }

  /// 轻量级触感反馈 - 用于轻微的交互确认
  /// 场景：答对题目、成功操作等
  static void light() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// 中等强度触感反馈 - 用于一般的交互反馈
  /// 场景：点击按钮、切换选项、展开菜单等
  static void medium() {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// 重量级触感反馈 - 用于重要的交互反馈
  /// 场景：答错题目、错误操作、重要提醒等
  static void heavy() {
    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// 选择反馈 - 用于滚动选择器等场景
  /// 场景：滚动题目、调整设置等
  static void selection() {
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// 震动反馈 - 用于系统级别的通知
  /// 场景：时间到、完成答题等重要事件
  static void vibrate() {
    if (_hapticEnabled) {
      HapticFeedback.vibrate();
    }
  }

  // 专门针对答题场景的触感反馈方法

  /// 答题正确的触感反馈
  static void correctAnswer() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// 答题错误的触感反馈
  static void wrongAnswer() {
    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// 点击展开答题卡的触感反馈
  static void openQuestionCard() {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// 点击题目序号的触感反馈
  static void selectQuestion() {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// 切换题目的触感反馈
  static void switchQuestion() {
    if (_hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  /// 提交答案的触感反馈
  static void submitAnswer() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// 完成答题的触感反馈
  static void completeQuiz() {
    if (_hapticEnabled) {
      HapticFeedback.vibrate();
    }
  }

  /// 时间警告的触感反馈
  static void timeWarning() {
    if (_hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
  }

  /// 时间到的触感反馈
  static void timeUp() {
    if (_hapticEnabled) {
      HapticFeedback.vibrate();
    }
  }

  /// 长按查看答案的触感反馈
  static void showHint() {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  /// 闪卡翻转的触感反馈
  static void flipCard() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }
}