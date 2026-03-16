plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream
import java.io.File
import org.gradle.api.GradleException

fun firstNonBlank(vararg values: String?): String? {
    for (value in values) {
        if (!value.isNullOrBlank()) return value
    }
    return null
}

val signingProperties = Properties()
val signingPropertiesFile: File = run {
    val externalPath = System.getenv("SIGNING_PROPERTIES_FILE")
    if (!externalPath.isNullOrBlank()) {
        File(externalPath)
    } else {
        rootProject.file("key.properties")
    }
}

if (signingPropertiesFile.exists()) {
    FileInputStream(signingPropertiesFile).use { signingProperties.load(it) }
}

val signingStoreFilePath = firstNonBlank(
    System.getenv("ANDROID_KEYSTORE_PATH"),
    signingProperties.getProperty("storeFile"),
)
val signingStorePassword = firstNonBlank(
    System.getenv("ANDROID_KEYSTORE_PASSWORD"),
    signingProperties.getProperty("storePassword"),
)
val signingKeyAlias = firstNonBlank(
    System.getenv("ANDROID_KEY_ALIAS"),
    signingProperties.getProperty("keyAlias"),
)
val signingKeyPassword = firstNonBlank(
    System.getenv("ANDROID_KEY_PASSWORD"),
    signingProperties.getProperty("keyPassword"),
)

val hasReleaseSigning =
    !signingStoreFilePath.isNullOrBlank() &&
    !signingStorePassword.isNullOrBlank() &&
    !signingKeyAlias.isNullOrBlank() &&
    !signingKeyPassword.isNullOrBlank()

android {
    namespace = "com.meshcore.team"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.meshcore.team"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = signingKeyAlias
                keyPassword = signingKeyPassword
                storeFile = file(signingStoreFilePath!!)
                storePassword = signingStorePassword
            }
        }
    }

    buildTypes {
        release {
            if (!hasReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Set env vars ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD or provide key.properties outside the repo and point SIGNING_PROPERTIES_FILE to it."
                )
            }
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.gms:play-services-location:21.3.0")
}

val verifyNoAdIdPermission by tasks.registering {
    group = "verification"
    description = "Fails release build if Advertising ID permission is present in merged manifest."

    dependsOn("processReleaseMainManifest")

    doLast {
        val candidates = listOf(
            file("$buildDir/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml"),
            file("$buildDir/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml"),
        )

        val mergedManifest = candidates.firstOrNull { it.exists() }
            ?: throw GradleException(
                "Unable to find merged release manifest to validate AD_ID permission. Checked: ${candidates.joinToString { it.path }}"
            )

        val content = mergedManifest.readText()
        if (content.contains("com.google.android.gms.permission.AD_ID")) {
            throw GradleException(
                "Advertising ID permission detected in merged release manifest (${mergedManifest.path}). Remove AD_ID usage or update Play Console declarations."
            )
        }
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    dependsOn(verifyNoAdIdPermission)
}
