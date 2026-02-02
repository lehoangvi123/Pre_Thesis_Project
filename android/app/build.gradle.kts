plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project1"
    
    // ⭐ SỬA: Tăng compileSdk lên 34 (từ flutter.compileSdkVersion)
    compileSdk = 36  
    ndkVersion = flutter.ndkVersion 

    // ⭐ SỬA: Nâng Java lên VERSION_17 (từ VERSION_11)
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ⭐ SỬA: Nâng Kotlin JVM target lên 17
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.project1"
        
        // ⭐ SỬA: Đảm bảo minSdk >= 21
        minSdk = flutter.minSdkVersion
        
        // ⭐ SỬA: Tăng targetSdk lên 34  
        targetSdk = 34
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName 
        multiDexEnabled = true 


        minSdk = flutter.minSdkVersion  // ✅ ĐÚNG
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64"))  // ✅ ĐÚNG
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
} 

dependencies {
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    
    // MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
