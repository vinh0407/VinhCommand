plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("org.jetbrains.kotlin.plugin.serialization")
    id("com.google.devtools.ksp")
    id("com.google.dagger.hilt.android")
}

android {
    namespace = "com.vinhcommand"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.vinhcommand"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables.useSupportLibrary = true
    }

    signingConfigs {
        create("release") {
            val path = System.getenv("KEYSTORE_PATH")
            if (path != null && path.isNotEmpty()) {
                storeFile = file(path)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
        debug {
            isMinifyEnabled = false
            isDebuggable = true
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-Xopt-in=kotlin.RequiresOptIn",
            "-Xopt-in=kotlinx.coroutines.ExperimentalCoroutinesApi",
            "-Xopt-in=androidx.lifecycle.ExperimentalLifecycleApi",
            "-Xopt-in=androidx.compose.material3.ExperimentalMaterial3Api",
            "-Xopt-in=androidx.compose.foundation.ExperimentalFoundationApi"
        )
    }

    buildFeatures {
        compose = true
        viewBinding = true
        dataBinding = true
    }

    packagingOptions {
        resources.excludes += listOf("META-INF/*")
        jniLibs.useLegacyPackaging = true
    }

    defaultTasks("clean", "assembleDebug")
}

dependencies {
    // Core Android
    val coreKtx = "1.13.1"
    val appCompat = "1.7.0"
    val material = "1.14.0-alpha01"
    val activity = "1.9.0"
    val fragment = "1.8.5"
    val lifecycle = "2.8.7"
    val room = "2.6.1"
    val datastore = "1.1.1"
    val work = "2.9.1"
    val navigation = "2.8.3"
    val paging = "3.3.2"
    val biometric = "1.2.0-alpha05"

    // Compose
    val composeBom = "2024.10.01"
    val composeCompiler = "1.5.13"
    val material3 = "1.3.1"
    val composeFoundation = "1.7.5"
    val composeAnimation = "1.7.5"
    val composeMaterialIcons = "1.7.5"
    val composeRuntime = "1.7.5"
    val composeUi = "1.7.5"
    val composeNavigation = "2.8.3"

    // Coroutines & Flow
    val coroutines = "1.9.0"
    val flow = "1.9.0"

    // DI - Hilt
    val hilt = "2.52"

    // Network
    val okhttp = "4.12.0"
    val retrofit = "2.11.0"
    val moshi = "1.15.1"
    val okio = "3.5.0"

    // WebSocket
    val okhttpWs = "4.12.0"
    val scarlet = "0.1.12"

    // Security
    val securityCrypto = "1.1.0-alpha05"

    // Serialization
    val kotlinxSerialization = "1.7.3"

    // Image loading
    val coil = "2.6.0"

    // Testing
    val junit = "4.13.2"
    val junitJupiter = "5.10.2"
    val espresso = "3.5.1"
    val composeTest = "1.5.1"
    val mockk = "1.13.14"
    val turbine = "1.0.0"

    // Logging
    val timber = "5.0.1"

    // Preferences DataStore
    implementation("androidx.datastore:datastore-preferences:$datastore")
    implementation("androidx.datastore:datastore-core:$datastore")
    implementation("androidx.datastore:datastore-preferences-rxjava3:$datastore")

    // Room Database
    implementation("androidx.room:room-runtime:$room")
    implementation("androidx.room:room-ktx:$room")
    ksp("androidx.room:room-compiler:$room")

    // Lifecycle & ViewModel
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:$lifecycle")
    implementation("androidx.lifecycle:lifecycle-livedata-ktx:$lifecycle")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:$lifecycle")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:$lifecycle")

    // Navigation Compose
    implementation("androidx.navigation:navigation-compose")
    implementation("androidx.navigation:navigation-fragment-ktx:$navigation")
    implementation("androidx.navigation:navigation-ui-ktx:$navigation")

    // Paging Compose
    implementation("androidx.paging:paging-compose:$paging")

    // WorkManager
    implementation("androidx.work:work-runtime-ktx:$work")

    // Biometric
    implementation("androidx.biometric:biometric:$biometric")

    // Core
    implementation("androidx.core:core-ktx:$coreKtx")
    implementation("androidx.appcompat:appcompat:$appCompat")
    implementation("com.google.android.material:material:$material")
    implementation("androidx.activity:activity-compose:$activity")
    implementation("androidx.fragment:fragment-ktx:$fragment")

    // Compose BOM
    implementation(platform("androidx.compose:compose-bom:$composeBom"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3:$material3")
    implementation("androidx.compose.material3:material3-window-size-class:$material3")
    implementation("androidx.compose.foundation:foundation:$composeFoundation")
    implementation("androidx.compose.animation:animation:$composeAnimation")
    implementation("androidx.compose.material:material-icons-extended:$composeMaterialIcons")
    implementation("androidx.compose.runtime:runtime-livedata:$composeRuntime")
    implementation("androidx.compose.runtime:runtime-rxjava3:$composeRuntime")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:$coroutines")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:$coroutines")

    // Hilt
    implementation("com.google.dagger:hilt-android:$hilt")
    ksp("com.google.dagger:hilt-android-compiler:$hilt")
    implementation("androidx.hilt:hilt-navigation-compose:1.2.0")
    implementation("androidx.hilt:hilt-work:1.2.0")

    // Network - Retrofit + OkHttp + Moshi
    implementation("com.squareup.retrofit2:retrofit:$retrofit")
    implementation("com.squareup.retrofit2:converter-moshi:$retrofit")
    implementation("com.squareup.moshi:moshi-kotlin:$moshi")
    implementation("com.squareup.moshi:moshi-adapters:$moshi")
    ksp("com.squareup.moshi:moshi-kotlin-codegen:$moshi")
    implementation("com.squareup.okhttp3:okhttp:$okhttp")
    implementation("com.squareup.okhttp3:logging-interceptor:$okhttp")
    implementation("com.squareup.okio:okio:$okio")

    // WebSocket - Scarlet
    implementation("com.tinder.scarlet:scarlet:$scarlet")
    implementation("com.tinder.scarlet:message-adapter-moshi:$scarlet")
    implementation("com.tinder.scarlet:websocket-okhttp:$scarlet")
    implementation("com.tinder.scarlet:lifecycle-android:$scarlet")

    // RxJava for Scarlet
    implementation("io.reactivex.rxjava3:rxjava:3.1.8")
    implementation("io.reactivex.rxjava3:rxandroid:3.0.2")

    // Kotlinx Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:$kotlinxSerialization")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-core:$kotlinxSerialization")

    // Security - EncryptedSharedPreferences, MasterKeys
    implementation("androidx.security:security-crypto:$securityCrypto")
    implementation("androidx.security:security-identity-credential:1.0.0-alpha03")

    // Coil Image Loading
    implementation("io.coil-kt:coil-compose:$coil")

    // Timber Logging
    implementation("com.jakewharton.timber:timber:$timber")

    // Testing
    testImplementation("junit:junit:$junit")
    testImplementation("org.junit.jupiter:junit-jupiter:$junitJupiter")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.1.0")
    testImplementation("io.mockk:mockk:$mockk")
    testImplementation("app.cash.turbine:turbine:$turbine")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
    androidTestImplementation("androidx.test.espresso:espresso-core:$espresso")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4:$composeTest")
    androidTestImplementation("androidx.compose.ui:ui-test-manifest:$composeTest")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-tooling-data")
}