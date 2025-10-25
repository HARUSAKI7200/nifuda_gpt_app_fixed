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
    compileSdk = 35

    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

defaultConfig {
        applicationId = "com.example.shogo_app" // アプリの最終的なID
        minSdk = 21
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

flutter {
    source = "../.."
}

dependencies {}