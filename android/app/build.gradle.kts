plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.manualentryticket"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.manualentryticket"

        minSdk = 24   // مهم جداً (حل مشاكل image_picker)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
//    testOptions {
//        unitTests.all {
//            it.enabled = false
//        }
//    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Keep the .tflite model uncompressed so it can be memory-mapped at runtime
    // (FileUtil.loadMappedFile fails on a compressed asset).
    androidResources {
        noCompress += "tflite"
    }
}


dependencies {

    // Kotlin coroutines — used by the plate-detection MethodChannel handler.
    // Added explicitly so it doesn't depend on a Flutter plugin pulling it in.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // TensorFlow Lite (clean)
    implementation("org.tensorflow:tensorflow-lite:2.14.0")
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")

    // CameraX (optional)
    implementation("androidx.camera:camera-core:1.3.1")
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")

    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
}

flutter {
    source = "../.."
}
tasks.configureEach {
    if (name.contains("test", ignoreCase = true) ||
        name.contains("Test", ignoreCase = true)) {
        enabled = false
    }
}