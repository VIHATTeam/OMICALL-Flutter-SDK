# Migration Guide: 3.2.4 → 3.3.1

## Overview

Version 3.3.1 includes major updates to both Android and iOS native SDKs, build toolchain upgrades, and new call quality monitoring features.

| | 3.2.4 | 3.3.1 |
|--|-------|-------|
| Android OMI SDK | 2.3.22-v2 | **2.6.3** |
| iOS OmiKit | 1.8.44 | **1.10.29** |
| Kotlin | 1.6.10 | **1.9.24** |
| Android Gradle Plugin | 7.1.2 | **8.1.4** |
| compileSdk / targetSdk | 33 | **35** |
| Java | 1.8 | **11** |

---

## Step 1: Update Plugin Version

**`pubspec.yaml`**:
```yaml
dependencies:
  omicall_flutter_plugin: ^3.3.1
```

Then run:
```bash
flutter pub get
```

---

## Step 2: Android — Update Maven Repository

The Maven package name has changed. Update your project-level `build.gradle` or `build.gradle.kts`.

**`android/build.gradle` (Groovy)**:
```groovy
// OLD
api 'vn.vihat.omicall:omi-sdk:2.3.22-v2'

// NEW
api 'io.omicrm.vihat:omi-sdk:2.6.3'
```

**`android/build.gradle.kts` (Kotlin DSL)**:
```kotlin
// OLD
api("vn.vihat.omicall:omi-sdk:2.3.22-v2")

// NEW
api("io.omicrm.vihat:omi-sdk:2.6.3")
```

> **Note**: The Maven repository URL remains the same (`https://maven.pkg.github.com/omicall/OMICall-SDK`). Only the package group ID changed.

---

## Step 3: Android — Update GitHub Authentication

Remove hardcoded tokens and use `local.properties` instead.

**`android/local.properties`** (do NOT commit this file):
```properties
omicallUsername=YOUR_GITHUB_USERNAME
omicallPassword=YOUR_GITHUB_PERSONAL_ACCESS_TOKEN
```

**`android/build.gradle.kts`** — Read credentials from local.properties:
```kotlin
val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/omicall/OMICall-SDK")
            credentials {
                username = localProperties.getProperty("omicallUsername")
                    ?: project.findProperty("omicallUsername") as? String ?: ""
                password = localProperties.getProperty("omicallPassword")
                    ?: project.findProperty("omicallPassword") as? String ?: ""
            }
            authentication {
                create<BasicAuthentication>("basic")
            }
        }
    }
}
```

---

## Step 4: Android — Update Permissions

Add the following permissions to your `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Existing permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <!-- NEW: Android 14+ (API 34+) - Required for foreground service types -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />

    <!-- NEW: Android 13+ (API 33+) - Required for notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- NEW: Android 15-16 - Required for ConnectionService -->
    <uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />

    <!-- CRITICAL: Remove camera permission to prevent crashes on Android 14+ -->
    <!-- Apps without video call MUST add this line -->
    <uses-permission
        android:name="android.permission.FOREGROUND_SERVICE_CAMERA"
        tools:node="remove" />

    <!-- NEW: Telephony is optional for VoIP apps -->
    <uses-feature
        android:name="android.hardware.telephony"
        android:required="false" />

    <!-- ... -->
</manifest>
```

> **Warning**: Omitting `FOREGROUND_SERVICE_CAMERA` removal will cause crashes on Android 14-15 devices without a camera.

---

## Step 5: Android — Update Service Declarations

Update `NotificationService` and `FirebaseMessageReceiver` in `AndroidManifest.xml`:

```xml
<!-- Update: Add foregroundServiceType -->
<service
    android:name="vn.vihat.omicall.omisdk.service.NotificationService"
    android:enabled="true"
    android:exported="false"
    android:foregroundServiceType="microphone|phoneCall">
    <!-- IMPORTANT: Only microphone|phoneCall, NO camera -->
</service>

<!-- Update: Add foregroundServiceType -->
<receiver
    android:name="vn.vihat.omicall.omisdk.receiver.FirebaseMessageReceiver"
    android:exported="true"
    android:enabled="true"
    android:foregroundServiceType="remoteMessaging"
    tools:replace="android:exported"
    android:permission="com.google.android.c2dm.permission.SEND">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</receiver>
```

---

## Step 6: Android — Build Toolchain (if not already updated)

If your project still uses old Kotlin/AGP versions, update:

**`android/build.gradle`**:
```groovy
buildscript {
    ext.kotlin_version = '1.9.24'  // was 1.6.10

    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.4'  // was 7.1.2
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.dagger:hilt-android-gradle-plugin:2.48'  // was 2.39.1
    }
}

android {
    compileSdkVersion 35  // was 33

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_11  // was 1.8
        targetCompatibility JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = '11'  // was 1.8
    }

    defaultConfig {
        targetSdkVersion 35  // was 33
    }
}
```

**Remove KAPT** (if present):
```groovy
// REMOVE this line
apply plugin: 'kotlin-kapt'

// REMOVE this dependency
kapt "com.github.bumptech.glide:compiler:4.15.1"
```

**Remove `jcenter()`** from repositories (deprecated).

---

## Step 7: iOS — Update OmiKit

**`ios/Podfile`** — Simply run:
```bash
cd ios
pod update OmiKit
```

This will update OmiKit from 1.8.44 to 1.10.29.

### iOS Build Fixes (Xcode 26+)

If you encounter build errors with Xcode 26+, add these post_install hooks to your `Podfile`:

```ruby
post_install do |installer|
  # Fix 1: CocoaPods bug - 'source: unbound variable'
  frameworks_script = File.join(__dir__, 'Pods', 'Target Support Files',
    'Pods-Runner', 'Pods-Runner-frameworks.sh')
  if File.exist?(frameworks_script)
    content = File.read(frameworks_script)
    patched = content.gsub('set -u', 'set +u')
    File.write(frameworks_script, patched) if content != patched
  end

  # Fix 2: 'framework Pods_Runner not found' linker error
  search_path_fix = '"${PODS_CONFIGURATION_BUILD_DIR}"'
  ['debug', 'release', 'profile'].each do |config|
    xcconfig_path = File.join(__dir__, 'Pods', 'Target Support Files',
      'Pods-Runner', "Pods-Runner.#{config}.xcconfig")
    if File.exist?(xcconfig_path)
      xcconfig = File.read(xcconfig_path)
      unless xcconfig.match?(/"\$\{PODS_CONFIGURATION_BUILD_DIR\}"(?!\/)/)
        xcconfig = xcconfig.gsub(
          /^(FRAMEWORK_SEARCH_PATHS = .*)$/,
          "\\1 #{search_path_fix}"
        )
        File.write(xcconfig_path, xcconfig)
      end
    end
  end

  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

---

## Step 8: (Optional) Use CallQualityTracker

New in 3.3.1 — typed helper classes for call quality monitoring:

```dart
import 'package:omicall_flutter_plugin/omicall.dart';

// Create tracker instance (stateful - tracks LCN changes)
final _qualityTracker = CallQualityTracker();

// In your call screen setup
OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  // Access typed properties
  print('MOS: ${info.mos}');           // double (0.0 - 5.0)
  print('LCN: ${info.lcn}');           // int
  print('Quality: ${info.quality}');   // int (0=bad, 1=normal, 2=good)
  print('Jitter: ${info.jitter}');     // double (ms)
  print('Latency: ${info.latency}');   // double (ms)
  print('Packet Loss: ${info.packetLoss}'); // double (%)

  // Helper getters
  print('Display: ${info.mosDisplay}');           // "4.5" or ""
  print('Loading: ${info.shouldShowLoading}');     // bool
  print('Recovered: ${info.isNetworkRecovered}');  // bool

  // Show loading when network is poor (LCN stuck)
  if (info.shouldShowLoading) {
    showLoadingOverlay();
  } else if (info.isNetworkRecovered || info.lcn == 0) {
    hideLoadingOverlay();
  }

  // Update UI with MOS score
  setState(() {
    callQuality = info.mosDisplay;
  });
});

// Don't forget to clean up
@override
void dispose() {
  _qualityTracker.reset();
  OmicallClient.instance.removeCallQualityListener();
  super.dispose();
}
```

> **Note**: `CallQualityTracker` handles `Map<dynamic, dynamic>` from platform channels correctly on both Android and iOS. The old manual approach with `Map<String, dynamic>` casting would crash on iOS.

---

## Checklist

- [ ] Updated `pubspec.yaml` to `^3.3.1`
- [ ] Updated Maven package: `vn.vihat.omicall` → `io.omicrm.vihat`
- [ ] Moved GitHub credentials to `local.properties`
- [ ] Added `FOREGROUND_SERVICE_MICROPHONE` permission
- [ ] Added `FOREGROUND_SERVICE_PHONE_CALL` permission
- [ ] Added `POST_NOTIFICATIONS` permission
- [ ] Added `MANAGE_OWN_CALLS` permission
- [ ] Added `FOREGROUND_SERVICE_CAMERA` removal with `tools:node="remove"`
- [ ] Added `uses-feature telephony required=false`
- [ ] Updated `NotificationService` with `foregroundServiceType`
- [ ] Updated `FirebaseMessageReceiver` with `foregroundServiceType`
- [ ] Removed `kotlin-kapt` plugin (if present)
- [ ] Removed `jcenter()` repository (if present)
- [ ] Updated Kotlin / AGP / compileSdk / Java versions
- [ ] Run `pod update OmiKit` for iOS
- [ ] Tested on physical device (VoIP requires real device)
