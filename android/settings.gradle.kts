// ───────────────────────────────────────────────────────────────
// 1 pluginManagement は最上位で最初に書く必要がある
// ───────────────────────────────────────────────────────────────
pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// ───────────────────────────────────────────────────────────────
// 2 plugins ブロックは「pluginManagement」の後に1つだけ置く
//    ※ Foojay（JDK 自動解決）もここに統合
// ───────────────────────────────────────────────────────────────
plugins {
    // ★JDK 17 を自動取得するための Resolver（ネット接続必須）
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"

    // Flutter/AGP/Kotlin のプラグイン宣言（apply false のままでOK）
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.21" apply false
}

// ───────────────────────────────────────────────────────────────
// 3 モジュール include
// ───────────────────────────────────────────────────────────────
include(":app")
