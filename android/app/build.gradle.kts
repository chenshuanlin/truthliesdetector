plugins {
    id("com.android.application")
    // 將 'kotlin-android' 更新為完整 ID 以確保兼容性
    id("org.jetbrains.kotlin.android") 
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.truthliesdetector"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // 將 Java 版本設置為 1.8，以確保最大兼容性
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8" // 確保 JVM 目標為 1.8
    }

    defaultConfig {
        applicationId = "com.example.truthliesdetector"
        // 🚀 關鍵修改 1: 確保 minSdk 至少為 21 (Lollipop)，這是 MediaProjection API 所需的最低版本。
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 🚀 關鍵修改 2: 新增 dependencies 區塊
dependencies {
    // 確保包含 Kotlin 核心執行時 (Service 運行所必需)
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.0") 
    // 確保 AndroidX Core 庫可用
    implementation("androidx.core:core-ktx:1.12.0") 
}
