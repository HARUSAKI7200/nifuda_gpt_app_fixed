// harusaki7200/nifuda_gpt_app_fixed/nifuda_gpt_app_fixed-1cd7e649a3c8ce313da9e203cf977ff070f2ae20/build.gradle.kts (アプリレベル)

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

fun localProperties(): Properties {
    val localPropertiesFile = rootProject.file("local.properties")
    val properties = Properties()
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
    }
    return properties
}

// ▼▼▼ 修正点：この2行を以下に置き換えてください ▼▼▼
val flutterVersionCode = localProperties().getProperty("flutter.versionCode")
val flutterVersionName = localProperties().getProperty("flutter.versionName")

android {
    namespace = "com.example.nifuda_gpt_app_fixed" // ソースコードのパッケージ名と一致
    compileSdk = 36

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

defaultConfig {
        applicationId = "com.example.shogo_app" // アプリの最終的なID
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutterVersionCode?.toInt() ?: 1
        versionName = flutterVersionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

// JVM Toolchain（AGP 8.2以降対応）
kotlin {
    jvmToolchain(17)
}

flutter {
    source = "../.."
}

dependencies {
    // ▼▼▼ 以下の1行を追加してください ▼▼▼
    // Material 3 関連のリソースを提供するために必要
    implementation("com.google.android.material:material:1.13.0") 
}

// ▼▼▼ 以下のブロックをファイルの末尾に追記してください ▼▼▼
// プロジェクト全体（isar_flutter_libs を含む）の依存関係を強制的に上書き
configurations.all {
    resolutionStrategy.eachDependency {
        // material ライブラリが要求された場合
        if (requested.group == "com.google.android.material" && requested.name == "material") {
            // lStar エラーを修正するため、バージョンを強制的に 1.13.0 に指定
            useVersion("1.13.0")
        }
    }
}