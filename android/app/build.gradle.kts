plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.fitnessos.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.fitnessos.app"
        minSdk = 24  // Raised to 24 for ML Kit Pose Detection stability
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Multidex support for ML Kit
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // ProGuard rules for ML Kit and performance optimization
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Ensure Java 11 bytecode compatibility
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
    }
}

dependencies {
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")

    // Core library desugaring for Java 11 features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
