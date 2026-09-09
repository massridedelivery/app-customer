import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Load signing config from android/key.properties (kept out of version control).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.massdrive.customer_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications needs backported java.time APIs.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.massdrive.customer_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            // dev installs alongside prod: com.massdrive.customer_app.dev
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Mass Delivery Dev")
            // Google Maps SDK key for dev (fills the AndroidManifest placeholder).
            manifestPlaceholders["mapsApiKey"] =
                "AIzaSyAx8IyTZMk6bif4eLcPzzKH8pj7tuzLxPQ"
        }
        create("prod") {
            dimension = "env"
            // Launcher name must match the Play/App Store listing ("Mass
            // Delivery") — a mismatch is a Play "misleading claims" rejection.
            resValue("string", "app_name", "Mass Delivery")
            // Production Google Maps SDK key (restricted to package
            // com.massdrive.customer_app + the signing-cert SHA-1s).
            manifestPlaceholders["mapsApiKey"] =
                "AIzaSyCFlJ-xOwNwPXItxUCi4Le6lUTLpBYmEUo"
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Use the upload keystore when key.properties is present,
            // otherwise fall back to debug keys so `flutter run --release` still works.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Shrink the Java/Kotlin + plugin layer and strip unused Android
            // resources from the release APK/AAB. (Dart code lives in libapp.so
            // and is shrunk separately via --obfuscate/tree-shaking at build.)
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // shared_preferences pulls androidx.datastore, whose older native lib
    // (libdatastore_shared_counter.so) isn't aligned to 16 KB memory pages —
    // Play flags it for Android 15+ devices. Force a 16 KB-aligned release.
    constraints {
        implementation("androidx.datastore:datastore-core:1.1.7")
        implementation("androidx.datastore:datastore-core-android:1.1.7")
        implementation("androidx.datastore:datastore-preferences:1.1.7")
        implementation("androidx.datastore:datastore-preferences-android:1.1.7")
    }
}
