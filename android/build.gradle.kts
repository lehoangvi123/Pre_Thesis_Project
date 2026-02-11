// android/build.gradle.kts
// Root-level build configuration for Flutter Android project

plugins {
    // Usually empty in Flutter root build file – plugins are applied in settings.gradle.kts or app/build.gradle.kts
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // If you use other repos (e.g. jitpack), add them here
    }
}

// ────────────────────────────────────────────────
//   Custom build directory: move builds to ../build (one level up from android/)
//   This helps keep your project folder clean / move heavy builds to another drive
// ────────────────────────────────────────────────
rootProject.layout.buildDirectory.set(
    rootProject.file("../build")
)

// Apply the same pattern to all subprojects (app, plugins if any)
subprojects {
    project.layout.buildDirectory.set(
        rootProject.layout.buildDirectory.dir(project.name)
    )
}

// ────────────────────────────────────────────────
//   Fix missing compileSdkVersion for plugins
// ────────────────────────────────────────────────
subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                if (compileSdkVersion == null) {
                    compileSdkVersion(36)
                }
            }
        }
    }
}

// Optional: Force :app to be evaluated first (rarely needed in recent Flutter, 
// but harmless if you had issues before)
subprojects {
    evaluationDependsOn(":app")
}

// Clean task: deletes the entire custom ../build folder
tasks.register<org.gradle.api.tasks.Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}