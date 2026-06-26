plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.bikinstiker.bikin_stiker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bikinstiker.bikin_stiker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Post-build hook: rename generated APKs in build/app/outputs/flutter-apk/
// to {applicationId}-{versionName}-{descriptor}.apk so the output filename
// encodes the package name and the current semver build.
//   - applicationId/versionName are auto-populated by the Flutter Gradle
//     plugin from pubspec.yaml (no manual sync needed).
//   - descriptor preserves the build type (release/debug/profile) and, when
//     `flutter build apk --split-per-abi` is used, the target ABI
//     (e.g. arm64-v8a-release).
//   - The hook is idempotent: already-renamed outputs (matching the
//     applicationId prefix) are skipped on repeated builds.
gradle.projectsEvaluated {
    listOf("assembleRelease", "assembleDebug", "assembleProfile").forEach { taskName ->
        tasks.findByName(taskName)?.doLast {
            val buildType = taskName.removePrefix("assemble").replaceFirstChar { it.lowercase() }
            val apkDir = file("${layout.buildDirectory.get().asFile}/outputs/flutter-apk")
            if (!apkDir.exists()) return@doLast
            apkDir.listFiles { f -> f.extension == "apk" }?.forEach { apk ->
                if (apk.name.startsWith("${defaultConfig.applicationId}-")) return@forEach
                val descriptor = apk.nameWithoutExtension.removePrefix("app-")
                val newName = "${defaultConfig.applicationId}-${defaultConfig.versionName}-${descriptor}.apk"
                val target = file("${apkDir}/$newName")
                if (target.exists()) target.delete()
                apk.copyTo(target, overwrite = true)
                apk.delete()
                logger.lifecycle("Renamed APK: ${apk.name} -> $newName")
            }
        }
    }
}
