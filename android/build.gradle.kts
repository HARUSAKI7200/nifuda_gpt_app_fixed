// build.gradle.kts (ルート / Project-level) — 完全版

// ===== Kotlin DSL では import はファイル先頭に置く必要があります =====
import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption

// ===== ここから既存の設定 =====

allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // ▼▼▼【 lStar エラー修正 v3 (最終) 】▼▼▼
    // isar_flutter_libs が古い androidx.core と material に依存するのを修正
    configurations.all {
        resolutionStrategy.eachDependency {
            // androidx.core と core-ktx が要求された場合
            if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                // lStar エラーを修正するため、バージョンを強制的に 1.13.1 に指定
                useVersion("1.13.1")
            }
            // com.google.android.material が要求された場合
            if (requested.group == "com.google.android.material" && requested.name == "material") {
                // lStar エラーを修正するため、バージョンを強制的に 1.13.0 に指定
                useVersion("1.13.0")
            }
        }
    }
    // ▲▲▲【 追記はここまで 】▲▲▲
}

// 明示型 Directory は外して型推論に任せる（import不要で安全）
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// --- Fix missing namespace for isar_flutter_libs (AGP 8+) ---
// 依存ライブラリの build.gradle に namespace が無い場合に動的に付与します。
// isar_flutter_libs のみに限定して適用。AGP 7.x などでは安全にスキップされます。
subprojects {
    if (name == "isar_flutter_libs") {
        plugins.withId("com.android.library") {
            // "android" 拡張を取得（反射で get/setNamespace を呼ぶ）
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                val clazz = androidExt.javaClass
                val getNs = clazz.methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
                val setNs = clazz.methods.firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
                if (getNs != null && setNs != null) {
                    val current = (getNs.invoke(androidExt) as? String)?.trim()
                    if (current.isNullOrEmpty()) {
                        // ★ ここを 'dev.isar.isar_flutter_libs' に補正
                        setNs.invoke(androidExt, "dev.isar.isar_flutter_libs")
                        logger.lifecycle("[fix] Set namespace for :$name -> dev.isar.isar_flutter_libs")
                    } else {
                        logger.lifecycle("[info] :$name already has namespace '$current'")
                    }
                } else {
                    logger.lifecycle("[skip] :$name has no get/setNamespace (likely AGP < 8).")
                }
            } else {
                logger.lifecycle("[skip] :$name has no 'android' extension.")
            }
        }
    }
}
// --- /Fix namespace ---

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// --- BEGIN: isar_flutter_libs Manifest パッチ（AGP 8 での package= 禁止対策） ---
// ライブラリ側の AndroidManifest.xml に残っている package="dev.isar.isar_flutter_libs" を毎回ビルド前に除去します。

fun pubCacheDir(): File {
    // 1 PUB_CACHE があれば最優先
    System.getenv("PUB_CACHE")?.let { env ->
        if (env.isNotBlank()) return File(env)
    }
    // 2 Windows 既定: %LOCALAPPDATA%\Pub\Cache
    System.getenv("LOCALAPPDATA")?.let { env ->
        if (env.isNotBlank()) return File(env, "Pub\\Cache")
    }
    // 3 Unix 系: ~/.pub-cache
    return File(System.getProperty("user.home"), ".pub-cache")
}

val isarManifestFile: File by lazy {
    // pub キャッシュ上の isar_flutter_libs-3.1.0+1 の AndroidManifest.xml
    val base = pubCacheDir()
    File(
        File(
            File(
                File(base, "hosted"),
                "pub.dev"
            ),
            "isar_flutter_libs-3.1.0+1" // ← 将来バージョンが上がったらこのディレクトリ名だけ差し替え
        ),
        "android/src/main/AndroidManifest.xml"
    )
}

val patchIsarManifest by tasks.registering {
    doLast {
        if (isarManifestFile.exists()) {
            val original = isarManifestFile.readText(Charsets.UTF_8)
            // <manifest ... package="dev.isar.isar_flutter_libs" ...> の package 属性を削除
            val patched = original.replace(Regex("""\s+package="dev\.isar\.isar_flutter_libs""""), "")
            if (patched != original) {
                // 初回だけバックアップを生成
                val backup = File(isarManifestFile.parentFile, "AndroidManifest.xml.bak")
                if (!backup.exists()) {
                    Files.copy(
                        isarManifestFile.toPath(),
                        backup.toPath(),
                        StandardCopyOption.REPLACE_EXISTING
                    )
                }
                isarManifestFile.writeText(patched, Charsets.UTF_8)
                println("[patchIsarManifest] Removed package= from isar_flutter_libs AndroidManifest.xml")
            } else {
                println("[patchIsarManifest] Already patched (no package= attribute found).")
            }
        } else {
            println("[patchIsarManifest] Manifest not found: ${isarManifestFile.absolutePath}")
        }
    }
}

// すべての Android モジュールの preBuild に、このパッチを依存させる
gradle.projectsEvaluated {
    subprojects {
        // Android モジュールのみ対象
        plugins.withId("com.android.application") {
            tasks.matching { it.name == "preBuild" }.configureEach {
                dependsOn(patchIsarManifest)
            }
        }
        plugins.withId("com.android.library") {
            tasks.matching { it.name == "preBuild" }.configureEach {
                dependsOn(patchIsarManifest)
            }
        }
    }
}

// --- END: isar_flutter_libs Manifest パッチ ---
