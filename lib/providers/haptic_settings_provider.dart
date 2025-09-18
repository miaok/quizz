import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 触感设置状态
class HapticSettings {
  final bool hapticEnabled;

  const HapticSettings({
    this.hapticEnabled = true,
  });

  HapticSettings copyWith({
    bool? hapticEnabled,
  }) {
    return HapticSettings(
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HapticSettings &&
        other.hapticEnabled == hapticEnabled;
  }

  @override
  int get hashCode => hapticEnabled.hashCode;
}

/// 触感设置控制器
class HapticSettingsNotifier extends StateNotifier<HapticSettings> {
  HapticSettingsNotifier() : super(const HapticSettings()) {
    _loadSettings();
  }

  static const String _hapticEnabledKey = 'haptic_enabled';

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hapticEnabled = prefs.getBool(_hapticEnabledKey) ?? true;

      state = HapticSettings(
        hapticEnabled: hapticEnabled,
      );
    } catch (e) {
      // 如果加载失败，保持默认设置
      state = const HapticSettings();
    }
  }

  /// 设置触感反馈开关
  Future<void> setHapticEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hapticEnabledKey, enabled);

      state = state.copyWith(hapticEnabled: enabled);
    } catch (e) {
      // 处理保存失败的情况
    }
  }

  /// 重置所有设置为默认值
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hapticEnabledKey);

      state = const HapticSettings();
    } catch (e) {
      // 处理重置失败的情况
    }
  }
}

/// 触感设置Provider
final hapticSettingsProvider = StateNotifierProvider<HapticSettingsNotifier, HapticSettings>(
  (ref) => HapticSettingsNotifier(),
);