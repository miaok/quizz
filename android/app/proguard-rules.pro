# Flutter 相关混淆规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift 数据库相关
-keep class drift.** { *; }
-keep class com.simolus.drift_sqflite.** { *; }

# Riverpod 状态管理
-keep class riverpod.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences.** { *; }

# 保留所有注解
-keepattributes *Annotation*

# 保留行号信息，方便调试
-keepattributes SourceFile,LineNumberTable

# 保留泛型信息
-keepattributes Signature

# 保留异常信息
-keepattributes Exceptions

# Google Play Core 相关
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store Split 相关
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
