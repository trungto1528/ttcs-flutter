import java.util.Properties
import java.io.FileInputStream

// 1. Khởi tạo Properties và xác định file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

// 2. Chỉ load nếu file tồn tại (Ở Local)
val isLocalSigningReady = if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    // Kiểm tra thêm xem các key cần thiết có đủ không
    keystoreProperties.containsKey("keyAlias") &&
            keystoreProperties.containsKey("keyPassword") &&
            keystoreProperties.containsKey("storeFile") &&
            keystoreProperties.containsKey("storePassword")
} else {
    false
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tqtrung.novelread.novel_app"
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
        applicationId = "com.tqtrung.novelread.novel_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // 3. Cấu hình signing chỉ khi có đủ dữ liệu từ file local
        if (isLocalSigningReady) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            // 4. CHỐT CHẶN QUAN TRỌNG:
            // Nếu có file local thì dùng signingConfigs.release
            // Nếu không (trên GitHub) thì set là null để build bản Unsigned
            signingConfig = if (isLocalSigningReady) {
                signingConfigs.getByName("release")
            } else {
                null
            }

            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}