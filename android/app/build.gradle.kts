// Copyright 2026 Tech Details. All rights reserved.
// Use of this file is governed by the LICENSE file at the root of this repository.

import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// REDIX's upload key (redix-app #118): android/key.properties, written from GitHub's secrets by the test-builds workflow, never in the repo.
// Without it, as on the owner's PC, a release build is signed with the debug key and never leaves the PC; the workflow checks the key before it uploads.
val uploadKeyFile = rootProject.file("key.properties")
val uploadKey = Properties().apply { if (uploadKeyFile.exists()) uploadKeyFile.inputStream().use { load(it) } }

android {
    namespace = "redix"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // The environment's config file decides the app's id, its name and its link host (redix-app #95, #83): the --dart-define values the app is built
        // with. Without one the app is com.techdetails.redix, REDIX and redix.test, the production names; the prefix is the company's, Tech Details, as every
        // app it publishes carries it (redix-app #118 D2).
        val dartDefines = (project.findProperty("dart-defines") as String? ?: "").split(",").filter { it.isNotEmpty() }
            .map { String(Base64.getDecoder().decode(it)) }
            .associate { it.substringBefore("=") to it.substringAfter("=") }
        applicationId = "com.techdetails.redix" + (dartDefines["APP_ID_SUFFIX"] ?: "")
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appName"] = dartDefines["APP_NAME"] ?: "REDIX"
        manifestPlaceholders["linkHost"] = dartDefines["LINK_HOST"] ?: "redix.test"
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    // Which build the Patrol cases run on: profile is compiled as a release is, and keeps Patrol, which Flutter leaves out of a release.
    testBuildType = System.getenv("REDIX_TEST_BUILD_TYPE") ?: "debug"

    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }

    signingConfigs {
        if (uploadKeyFile.exists()) {
            create("upload") {
                storeFile = file(uploadKey.getProperty("storeFile"))
                storePassword = uploadKey.getProperty("storePassword")
                keyAlias = uploadKey.getProperty("keyAlias")
                keyPassword = uploadKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("upload") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    androidTestUtil("androidx.test:orchestrator:1.5.1")
    // The «إضافة قيد» widget's rows (redix-app #86): Android's own list of RemoteViews, on every Android this app runs on; home_widget already brings this version.
    implementation("androidx.core:core-remoteviews:1.1.0")
}
