// D:\Programlar\projelerim\formdakal\android\build.gradle.kts
buildscript {
    val kotlinVersion by extra("1.9.0")
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.4.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Alt projeler için varsayılan Android ayarları
subprojects {
    afterEvaluate {
        if (plugins.hasPlugin("com.android.application") || plugins.hasPlugin("com.android.library")) {
            configure<com.android.build.gradle.BaseExtension> {
                compileSdkVersion(35)
                
                defaultConfig {
                    minSdk = 21
                    targetSdk = 35
                }
                
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_1_8
                    targetCompatibility = JavaVersion.VERSION_1_8
                }
            }
        }
    }
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}