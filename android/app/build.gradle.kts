plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.quiz.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // 应用包名
        applicationId = "com.quiz.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 33  // Android 13
        targetSdk = 35  // Android 15
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 只构建 ARM64 架构
        ndk {
            abiFilters += listOf("arm64-v8a")
        }

        // 启用资源压缩
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            // Signing with the debug keys for now
            signingConfig = signingConfigs.getByName("debug")

            // 启用代码压缩和混淆来减小APK体积
            isMinifyEnabled = true
            isShrinkResources = true

            // 使用默认的ProGuard规则
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // 额外的优化选项
            isDebuggable = false
            isJniDebuggable = false
            isRenderscriptDebuggable = false
            isPseudoLocalesEnabled = false
            isZipAlignEnabled = true
        }
    }
}

dependencies {
    // 如果需要启用代码压缩，取消注释下面的依赖
    // implementation("com.google.android.play:core:1.10.3")
    // implementation("com.google.android.play:core-ktx:1.8.1")
}

flutter {
    source = "../.."
}
