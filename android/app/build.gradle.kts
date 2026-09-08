import java.net.URI
import java.security.MessageDigest

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val libboxVersion = "1.14.0-lx.35"
val libboxSha256 = "c4bc5f7b6aea3b022fff83421baeacbf672298cd167d828a6484cdbb1e896281"
val libboxUrl =
    "https://github.com/Leadaxe/sing-box-lx/releases/download/v$libboxVersion/libbox-$libboxVersion.aar"
val libboxAar = layout.buildDirectory.file("generated/libbox/libbox-$libboxVersion.aar")

fun sha256(file: File): String {
    val digest = MessageDigest.getInstance("SHA-256")
    file.inputStream().use { input ->
        val buffer = ByteArray(1024 * 1024)
        while (true) {
            val read = input.read(buffer)
            if (read <= 0) break
            digest.update(buffer, 0, read)
        }
    }
    return digest.digest().joinToString("") { "%02x".format(it) }
}

val downloadLibbox by tasks.registering {
    outputs.file(libboxAar)
    doLast {
        val target = libboxAar.get().asFile
        val validExisting = target.isFile && sha256(target) == libboxSha256
        if (!validExisting) {
            target.parentFile.mkdirs()
            val temporary = File(target.parentFile, "${target.name}.part")
            temporary.delete()
            URI(libboxUrl).toURL().openStream().use { input ->
                temporary.outputStream().buffered().use { output ->
                    input.copyTo(output)
                }
            }
            check(sha256(temporary) == libboxSha256) {
                "Downloaded libbox checksum mismatch"
            }
            if (target.exists()) target.delete()
            check(temporary.renameTo(target)) {
                "Unable to move downloaded libbox into place"
            }
        }
    }
}

val generatedLibbox = files(libboxAar).builtBy(downloadLibbox)

android {
    namespace = "app.truetun"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "app.truetun"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        buildConfigField("String", "LIBBOX_VARIANT", "\"sing-box-lx-$libboxVersion\"")
    }

    buildTypes {
        release {
            // TODO: replace the test key with a production signing configuration.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Pinned XHTTP-capable sing-box-lx Android binding. The SHA-256 is verified
    // before Gradle exposes the generated AAR to Kotlin/Android compilation.
    implementation(generatedLibbox)
}

flutter {
    source = "../.."
}
