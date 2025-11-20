plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cscore"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // ⭐ UPGRADE: Use Java 17 for better compatibility with modern Android/Flutter builds
        sourceCompatibility = JavaVersion.VERSION_17 
        targetCompatibility = JavaVersion.VERSION_17 
    }

    kotlinOptions {
        // ⭐ UPGRADE: Match the jvmTarget to the compileOptions
        jvmTarget = JavaVersion.VERSION_17.toString() 
    }

    defaultConfig {
        applicationId = "com.example.cscore"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// NOTE: The plugins block above already handles this line. You can safely remove one.
// Since you are using the modern plugins block, you can remove this legacy line.
// apply(plugin = "com.google.gms.google-services") // ❌ Can be removed if the plugins block works

// You should only need to keep the 'apply(plugin = ...)' line if your current build 
// is failing to pick up 'com.google.gms.google-services' from the plugins block.