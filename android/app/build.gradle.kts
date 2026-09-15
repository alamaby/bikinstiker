import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load android/key.properties for release signing. The file is gitignored;
// see key.properties.example for the expected schema. Falls back to debug
// signing when the file is absent (e.g. CI debug builds, fresh clones).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val hasReleaseSigning = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.alamaby.bikin_stiker"
    // Pinned to Android 16 (API 36) — Play requires targetSdk 35+ from Aug 2025
    // and is expected to require 36 from Aug 2026. Pinning explicitly also
    // avoids surprises when bumping the Flutter SDK.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.alamaby.bikin_stiker"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // When key.properties is absent we fall back to debug signing so
            // `flutter run --release` still works locally. Play Store uploads
            // MUST use the release keystore — CI verifies the AAB is not
            // debug-signed. See android/key.properties.example and
            // plans/2026-09-12-bikinstiker-play-store-release-plan.md.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

// Post-build hook: copy freshly generated APKs in
// build/app/outputs/flutter-apk/ to a renamed copy named
// {name}-{version}-{descriptor}.apk. Both the original and renamed copy
// are kept.
//   - name/version are read from pubspec.yaml at the project root.
//   - descriptor preserves the build type (release/debug/profile) and, when
//     `flutter build apk --split-per-abi` is used, the target ABI
//     (e.g. arm64-v8a-release).
//   - Safety: only APKs produced by THIS build (lastModified >= task start,
//     minus a small slack for filesystem timestamp granularity) are
//     renamed. Stale `app-*.apk` leftovers from previous builds are deleted
//     instead (with their .sha1/.sha256 sidecars), so they can never be
//     mislabeled with the current version (incident 2026-09-11: stale 0.26.3
//     binaries were copied as 0.26.4+86). Already-renamed outputs (pubspec
//     name prefix) are left untouched as the release archive.
gradle.projectsEvaluated {
    listOf("assembleRelease", "assembleDebug", "assembleProfile").forEach { taskName ->
        val task = tasks.findByName(taskName) ?: return@forEach
        var buildStartMs = 0L
        task.doFirst {
            buildStartMs = System.currentTimeMillis()
        }
        task.doLast {
            val apkDir = file("${layout.buildDirectory.get().asFile}/outputs/flutter-apk")
            if (!apkDir.exists()) return@doLast

            // Read name and version from pubspec.yaml
            val pubspecFile = file("../../pubspec.yaml")
            if (!pubspecFile.exists()) {
                logger.warn("pubspec.yaml not found at ${pubspecFile.absolutePath}, skipping APK rename")
                return@doLast
            }
            val pubspecLines = pubspecFile.readLines()
            val pubspecName = pubspecLines
                .firstOrNull { it.trimStart().startsWith("name:") }
                ?.substringAfter("name:")?.trim() ?: ""
            val pubspecVersion = pubspecLines
                .firstOrNull { it.trimStart().startsWith("version:") }
                ?.substringAfter("version:")?.trim() ?: ""

            if (pubspecName.isEmpty() || pubspecVersion.isEmpty()) {
                logger.warn("Could not parse name/version from pubspec.yaml, skipping APK rename")
                return@doLast
            }

            // Slack for coarse filesystem timestamp granularity (e.g. FAT 2s).
            val freshnessSlackMs = 30_000L
            apkDir.listFiles { f -> f.extension == "apk" }?.forEach apkLoop@{ apk ->
                // Skip files that are already renamed (start with pubspec name)
                if (apk.name.startsWith("$pubspecName-")) return@apkLoop
                // Stale leftover from a previous build: delete instead of
                // renaming, so it can never be mislabeled as this version.
                if (apk.lastModified() < buildStartMs - freshnessSlackMs) {
                    logger.lifecycle("Deleting stale APK leftover: ${apk.name}")
                    apk.delete()
                    listOf("sha1", "sha256").forEach { ext ->
                        file("${apkDir}/${apk.name}.$ext").takeIf { it.exists() }?.delete()
                    }
                    return@apkLoop
                }
                val descriptor = apk.nameWithoutExtension.removePrefix("app-")
                val newName = "$pubspecName-$pubspecVersion-$descriptor.apk"
                val target = file("${apkDir}/$newName")
                if (target.exists()) target.delete()
                apk.copyTo(target, overwrite = true)
                logger.lifecycle("Copied APK: ${apk.name} -> $newName")
            }
        }
    }
}
