// build.gradle.kts (ルート)

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
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
            // "android" 拡張を取得（型に依存せず反射で get/setNamespace を呼ぶ）
            val androidExt = extensions.findByName("android")
            if (androidExt != null) {
                val clazz = androidExt.javaClass
                val getNs = clazz.methods.firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
                val setNs = clazz.methods.firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
                if (getNs != null && setNs != null) {
                    val current = (getNs.invoke(androidExt) as? String)?.trim()
                    if (current.isNullOrEmpty()) {
                        setNs.invoke(androidExt, "dev.isar.flutter_libs")
                        logger.lifecycle("[fix] Set namespace for :$name -> dev.isar.flutter_libs")
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
