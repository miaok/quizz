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

# 更激进的代码压缩
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# 移除未使用的代码
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# 压缩资源名称
-adaptresourcefilenames **.properties,**.gif,**.jpg,**.png
-adaptresourcefilecontents **.properties,META-INF/MANIFEST.MF
