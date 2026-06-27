plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.alamaby.bikin_stiker"
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
        applicationId = "com.alamaby.bikin_stiker"
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

// Post-build hook: copy generated APKs in build/app/outputs/flutter-apk/
// and create a renamed copy named {name}-{version}-{descriptor}.apk.
// Both the original and renamed copy are kept.
//   - name/version are read from pubspec.yaml at the project root.
//   - descriptor preserves the build type (release/debug/profile) and, when
//     `flutter build apk --split-per-abi` is used, the target ABI
//     (e.g. arm64-v8a-release).
//   - The hook is idempotent: already-renamed outputs (matching the
//     pubspec name prefix) are skipped on repeated builds.
gradle.projectsEvaluated {
    listOf("assembleRelease", "assembleDebug", "assembleProfile").forEach { taskName ->
        tasks.findByName(taskName)?.doLast {
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

            apkDir.listFiles { f -> f.extension == "apk" }?.forEach { apk ->
                // Skip files that are already renamed (start with pubspec name)
                if (apk.name.startsWith("$pubspecName-")) return@forEach
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
