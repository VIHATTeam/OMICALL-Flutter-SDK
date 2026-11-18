# 📦 OMICALL SDK FOR Flutter

The OmiKit exposes the 📦 <a href="https://pub.dev/packages/omicall_flutter_plugin">omicall_flutter_plugin</a> library.

The most important part of the framework is :
- ✅ Help to easy integrate with Omicall.
- ✅ Easy custom Call UI/UX.
- ✅ Optimize codec voip for you.
- ✅ Full interface to interactive with core function like sound/ringtone/codec.
- ✅ Built-in Call Quality Monitoring (MOS score tracking)

### 📦 SDK Versions

| Component | Version |
|---|---|
| omicall_flutter_plugin | 3.4.2 |
| Android OmiSDK (`io.omicrm.vihat:omi-sdk`) | 2.9.5 |
| iOS OmiKit | 1.12.3 (CocoaPods or Swift Package Manager) |
| Android minimum | minSdk 24, compileSdk 35 |
| iOS minimum | 13.0 |

### 📝 Status
Currently active maintenance and improve performance

---

## 📚 Table of Contents

- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [Configuration](#configuration)
  - [Android Setup](#-android)
  - [iOS Setup](#-iosobject-c)
  - [Flutter Integration](#️-step-2-integrate-into-flutter-code--)
- [Call Flow Lifecycle](#call-flow-lifecycle)
- [API Reference](#api-reference)
  - [Core Functions](#core-functions)
  - [Call Control](#call-control)
  - [Video Call Functions](#video-call-functions--)
  - [Call Quality Monitoring](#-call-quality-monitoring-new)
- [Event Listeners](#event-listener-)
- [Error Codes](#error-codes)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

---

## Quick Start

Install via pubspec.yaml:

```yaml
dependencies:
  omicall_flutter_plugin: ^3.4.2
```

Minimum setup:

```dart
// 1. Start services
await OmicallClient.instance.startServices();

// 2. Login
final login = await OmicallClient.instance.register(
  userName: "your_username",
  password: "your_password",
  realm: "your_realm",
  fcmToken: fcmToken,      // FCM token (Android) / APNS token (iOS)
  host: "",                // optional SIP proxy; empty = OMICall default
  isVideo: false,
  projectId: "your_firebase_project_id",
);
if (!login.isSuccess) return; // login.message: MISSING_PARAMS | INIT_FAILED | NETWORK_UNAVAILABLE

// 3. Make a call — returns a JSON string {"status", "_id", "message"}
final result = await OmicallClient.instance.startCall(phoneNumber, false);
```

---

## Architecture Overview

### 📐 System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Layer                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Your Flutter App (UI/UX)                                  │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │  │
│  │  │ Call Screen │  │ Dial Screen  │  │ Settings Screen  │   │  │
│  │  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘   │  │
│  └─────────┼─────────────────┼────────────────────┼───────────┘  │
│            │                 │                    │              │
│            └─────────────────┴────────────────────┘              │
│                              │                                   │
├──────────────────────────────┼───────────────────────────────────┤
│                    OmicallClient API                             │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │  • startCall()        • toggleAudio()   • getCurrentUser() │  │
│  │  • endCall()          • toggleSpeaker() • getGuestUser()   │  │
│  │  • joinCall()         • toggleHold()    • getUserInfo()    │  │
│  │  • sendDTMF()         • toggleVideo()   • logout()         │  │
│  │  • switchCamera()     • transferCall()                     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                   │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │              Event Listeners & Helpers                     │  │
│  │  • callStateChangeEvent  • CallQualityTracker              │  │
│  │  • setCallQualityListener • CallQualityInfo                │  │
│  │  • setMuteListener       • VideoController                 │  │
│  │  • setSpeakerListener    • CameraView                      │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────┘
                               │ Method Channel
┌──────────────────────────────┴───────────────────────────────────┐
│                   Flutter Plugin Bridge                          │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Platform: Android (Kotlin)    Platform: iOS (Swift/ObjC)  │  │
│  │  • OmicallsdkPlugin            • SwiftOmikitPlugin         │  │
│  │  • Event Broadcasting          • Event Broadcasting        │  │
│  │  • Permission Handling         • CallKit Integration       │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
┌──────────────────────────────┴───────────────────────────────────┐
│                    Native SDK Layer                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Android SDK (vn.vihat.omicall.omisdk)                     │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │  │
│  │  │ SipService   │  │ CallManager  │  │ AudioManager     │  │  │
│  │  │ (OMISIP)      │  │              │  │                  │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  iOS SDK (OmiKit)                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │  │
│  │  │ OMISIPLib    │  │ CallManager  │  │ PushKitManager   │  │  │
│  │  │ (OMISIP)      │  │              │  │                  │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │   Network Layer     │
                    │  • SIP Protocol     │
                    │  • RTP/SRTP         │
                    │  • STUN/TURN        │
                    └─────────────────────┘
```

### 🔄 Data Flow

```
User Action → Flutter UI → OmicallClient → Platform Channel
           → Native SDK → SIP Server → Remote Peer

Remote Peer → Native SDK → Event Broadcast → OmicallClient
           → Flutter Listeners → UI Update
```

---

## Call Flow Lifecycle

### 📞 Outgoing Call Flow

```
┌─────────┐
│ Flutter │ startCall(phoneNumber, isVideo)
│   App   │ ─────────────────────────────────────────┐
└─────────┘                                          │
                                                     ▼
┌──────────────────────────────────────────────────────────────┐
│                    Call State Changes                        │
│                                                              │
│  UNKNOWN (0)                                                 │
│      │                                                       │
│      ├─── Check permissions & account status                 │
│      │                                                       │
│      ▼                                                       │
│  CALLING (1) ◄─ startCallSuccess (status=8)                  │
│      │           "Initiating call..."                        │
│      │           ⏱️  Ring tone starts                        │
│      │                                                       │
│      ▼                                                       │
│  EARLY (3)                                                   │
│      │           "Ringing..."                                │
│      │           ⏱️  Waiting for remote peer                 │
│      │                                                       │
│      ▼                                                       │
│  CONNECTING (4)                                              │
│      │           "Connecting..."                             │
│      │           🔊 Remote peer answered                     │
│      │                                                       │
│      ▼                                                       │
│  CONFIRMED (5)                                               │
│      │           "Active call"                               │
│      │           📊 Call quality monitoring starts           │
│      │           ⏱️  Call timer starts                       │
│      │           🎙️  Audio/Video stream active               │
│      │                                                       │
│      │  ┌──────────────────────────────────┐                 │
│      │  │  User can perform:               │                 │
│      │  │  • toggleAudio() - Mute/Unmute   │                 │
│      │  │  • toggleSpeaker() - Speaker on  │                 │
│      │  │  • toggleHold() - Hold/Unhold    │                 │
│      │  │  • toggleVideo() - Video on/off  │                 │
│      │  │  • sendDTMF() - Send numbers     │                 │
│      │  │  • transferCall() - Transfer     │                 │
│      │  │  • endCall() - Hang up           │                 │
│      │  └──────────────────────────────────┘                 │
│      │                                                       │
│      ▼                                                       │
│  DISCONNECTED (6)                                            │
│      │           "Call ended"                                │
│      │           📊 Call info returned                       │
│      │           ⏱️  Final duration calculated               │
│      │           🧹 Cleanup resources                        │
│      │                                                       │
│      ▼                                                       │
│  UNKNOWN (0)                                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Timeline Example:
─────────────────────────────────────────────────────────────►
0s        2s        4s        7s        45s       47s
│         │         │         │         │         │
UNKNOWN   CALLING   EARLY     CONNECTING CONFIRMED DISCONNECTED
          "Dialing" "Ringing" "Answered" "Talking" "Ended"
```

### 📲 Incoming Call Flow

```
┌─────────────┐
│ Push Notif  │ Firebase/APNS Push
│ or CallKit  │ ───────────────────────────────────────┐
└─────────────┘                                        │
                                                       ▼
┌──────────────────────────────────────────────────────────────┐
│                    Call State Changes                        │
│                                                              │
│  UNKNOWN (0)                                                 │
│      │                                                       │
│      ▼                                                       │
│  INCOMING (2)                                                │
│      │           "Incoming call from XXX"                    │
│      │           🔔 Ringtone plays                           │
│      │           📱 CallKit/Notification shows               │
│      │                                                       │
│      │  ┌──────────────────────────────────┐                 │
│      │  │  User Actions:                   │                 │
│      │  │  • joinCall() ────┐              │                 │
│      │  │  • endCall() ─────┼────┐         │                 │
│      │  └──────────────────────────────────┘                 │
│      │                      │    │                           │
│      │  ◄───────────────────┘    │                           │
│      ▼                            │                          │
│  CONNECTING (4)                   │                          │
│      │           "Answering..."  │                           │
│      │           🔊 Audio setup   │                          │
│      │                            │                          │
│      ▼                            │                          │
│  CONFIRMED (5)                    │                          │
│      │           "Active call"   │                           │
│      │           📊 Quality monitoring                       │
│      │           🎙️  Audio stream active                     │
│      │                            │                          │
│      │  [Same actions as         │                           │
│      │   outgoing call]           │                          │
│      │                            │                          │
│      ▼                            ▼                          │
│  DISCONNECTED (6) ◄───────── DISCONNECTED (6)                │
│      │           "Answered & Ended" "Rejected"               │
│      │           📊 Call duration    📊 No duration          │
│      │                                                       │
│      ▼                                                       │
│  UNKNOWN (0)                                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Timeline Example (Answer):
─────────────────────────────────────────────────────────────►
0s        1s        3s        30s       32s
│         │         │         │         │
UNKNOWN   INCOMING  CONNECTING CONFIRMED DISCONNECTED
          "Ringing" "Answered" "Talking" "Ended"

Timeline Example (Reject):
─────────────────────────────────────────────────────────────►
0s        1s        4s
│         │         │
UNKNOWN   INCOMING  DISCONNECTED
          "Ringing" "Rejected"
```

### 🔁 Hold State Flow

```
CONFIRMED (5)
     │
     ├─ toggleHold() ──►  setHoldListener(true)            (HOLD event)
     │                    setCallHoldChangedListener(...)  (CALL_HOLD_CHANGED, per call)
     │                       │
     │                       ├─ "Call on hold" — the customer hears nothing
     │                       │
     │  ◄──── toggleHold() ──┤
     ▼
setHoldListener(false) — "Call resumed"
```

> Hold is reported through the `HOLD` / `CALL_HOLD_CHANGED` listeners. `CALL_STATE_CHANGED` with
> status 7 is not emitted on Android, so do not rely on it. `toggleHold()` is ignored while a consult
> transfer is running (the SDK keeps the customer on hold).

---

## Configuration

### 🛠️ STEP 1: Config native file

#### 🚀 Android:

##### 📌 - Config *gradle* file

- The Android SDK is served from GitHub Packages and needs credentials (ask the OMI team for the
  token). Put them in `android/local.properties` — never commit this file:

```properties
omicallUsername=omicall
omicallPassword=YOUR_GITHUB_PAT
```

- `android/build.gradle.kts` (Flutter 3.29+ default), as in [example/android/build.gradle.kts](example/android/build.gradle.kts):

```kotlin
// Load local.properties for OMICall SDK credentials
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
                    ?: project.findProperty("omicallUsername") as? String ?: "omicall"
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

- Groovy `android/build.gradle` equivalent:

```gradle
def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withInputStream { localProperties.load(it) }
}

allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url "https://maven.pkg.github.com/omicall/OMICall-SDK"
            credentials {
                username = localProperties.getProperty('omicallUsername') ?: 'omicall'
                password = localProperties.getProperty('omicallPassword') ?: ''
            }
            authentication {
                basic(BasicAuthentication)
            }
        }
    }
}
```

- `android/app/build.gradle.kts` — apply Google Services (Firebase push), as in
  [example/android/app/build.gradle.kts](example/android/app/build.gradle.kts):

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") version "4.4.2"
}
```

Groovy: `apply plugin: 'com.google.gms.google-services'` plus
`classpath 'com.google.gms:google-services:4.4.2'` in the root `buildscript { dependencies { } }`.

A `401 Unauthorized` while resolving `io.omicrm.vihat:omi-sdk` means the token is missing or expired.


##### 📌 - Config *AndroidManifest.xml* file

**⚠️ IMPORTANT:** This configuration is required for Android 13+ (API 33+) and Android 14+ (API 34+). Missing permissions will cause crashes or prevent calls from working.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Hardware features - telephony is optional for VoIP apps -->
    <uses-feature
        android:name="android.hardware.telephony"
        android:required="false" />

    <!-- Basic permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <!-- Android 14+ (API 34+) - REQUIRED for foreground service types -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />

    <!-- Android 13+ (API 33+) - REQUIRED for notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- CRITICAL: Explicitly remove FOREGROUND_SERVICE_CAMERA to prevent crashes on Android 14-15 -->
    <!-- See CHANGELOG 3.3.2: this permission causes crashes on devices without camera -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" tools:node="remove" />

    <!-- Connection Service for Android 15-16 -->
    <uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />

    <application
        android:name="${applicationName}"
        android:label="Your App Name"
        android:enableOnBackInvokedCallback="true"
        android:alwaysRetainTaskState="true"
        android:largeHeap="true"
        android:exported="true"
        android:supportsRtl="true"
        android:allowBackup="false"
        android:fullBackupContent="false"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:windowSoftInputMode="adjustResize"
            android:showOnLockScreen="true"
            android:launchMode="singleTask"
            android:largeHeap="true"
            android:alwaysRetainTaskState="true"
            android:supportsPictureInPicture="true"
            android:resizeableActivity="true"
            android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation">
            <!-- supportsPictureInPicture / resizeableActivity / configChanges: only needed for
                 video Picture-in-Picture (see "Picture-in-Picture"); use false if you do not use PiP -->

            <!-- Your theme configuration -->
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <!-- Main launcher intent -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- Incoming call intent -->
            <intent-filter>
                <action android:name="android.intent.action.CALL" />
                <category android:name="android.intent.category.DEFAULT" />
                <data
                    android:host="incoming_call"
                    android:scheme="omisdk" />
            </intent-filter>

        </activity>

        <!-- Firebase Message Receiver -->
        <receiver
            android:name="vn.vihat.omicall.omisdk.receiver.FirebaseMessageReceiver"
            android:exported="true"
            android:enabled="true"
            tools:replace="android:exported"
            android:permission="com.google.android.c2dm.permission.SEND">
            <intent-filter>
                <action android:name="com.google.android.c2dm.intent.RECEIVE" />
            </intent-filter>
        </receiver>

        <!-- Notification Service -->
        <service
            android:name="vn.vihat.omicall.omisdk.service.NotificationService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="microphone|phoneCall">
            <!-- IMPORTANT: Only microphone|phoneCall, NO camera (see CHANGELOG 3.3.2) -->
        </service>

        <!-- Flutter plugin metadata -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

    </application>
</manifest>
```

**📝 Critical Notes:**

1. **FOREGROUND_SERVICE_CAMERA removal is REQUIRED:**
   ```xml
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" tools:node="remove" />
   ```
   - Without `tools:node="remove"`, app **WILL CRASH** on Android 14-15 devices without camera
   - See CHANGELOG 3.3.2 for details

2. **Android 14+ requires foregroundServiceType:**
   - NotificationService: `android:foregroundServiceType="microphone|phoneCall"` (NOT camera)
   - (`foregroundServiceType` has no effect on a `<receiver>`; older guides that put
     `remoteMessaging` on FirebaseMessageReceiver can drop it)

3. **Android 13+ requires POST_NOTIFICATIONS:**
   - Request this permission at runtime for notifications to work
   - Add to your permissions request flow

4. **Android 15-16 requires MANAGE_OWN_CALLS:**
   - For connection service integration

5. **Optional — Disable saving calls to device call history (`WRITE_CALL_LOG`):**
   By default the SDK may request `WRITE_CALL_LOG` to log calls in the native call history. If your app does **not** want calls saved to the device's call history, explicitly remove this permission:
   ```xml
   <uses-permission android:name="android.permission.WRITE_CALL_LOG" tools:node="remove" />
   ```
   > **Note:** `xmlns:tools="http://schemas.android.com/tools"` must be declared in the `<manifest>` tag (already included in the manifest template above).

**Runtime Permission Request Example:**
```kotlin
// In your MainActivity or permissions handler
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    requestPermissions(arrayOf(
        Manifest.permission.POST_NOTIFICATIONS
    ), REQUEST_CODE_NOTIFICATIONS)
}
```

##### 📌 -  Config *MainActivity* file

* In the `MainActivity.kt` file we need you to add the following configurations
```kotlin
import androidx.core.app.ActivityCompat.requestPermissions
import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import vn.vihat.omicall.omicallsdk.OmicallsdkPlugin
import android.Manifest
import androidx.activity.result.contract.ActivityResultContracts
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.os.Bundle
import android.content.Intent
import android.content.res.Configuration
import android.util.Log
import vn.vihat.omicall.omisdk.utils.SipServiceConstants

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val callPermissions = arrayOf(Manifest.permission.RECORD_AUDIO)

            if(!isGrantedPermission(Manifest.permission.RECORD_AUDIO)){
                requestPermissions(this,callPermissions,0)
            }

            val isIncomingCall = intent.getBooleanExtra(SipServiceConstants.ACTION_IS_INCOMING_CALL, false)
            OmicallsdkPlugin.onOmiIntent(this, intent)

        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun onNewIntent(intent: Intent){
        super.onNewIntent(intent);
        OmicallsdkPlugin.onOmiIntent(this, intent)
    }


    override fun onDestroy() {
        super.onDestroy()
        OmicallsdkPlugin.onDestroy()
    }

    override fun onResume(){
        super.onResume()
        OmicallsdkPlugin.onResume(this);
    }

    fun isGrantedPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        OmicallsdkPlugin.onRequestPermissionsResult(requestCode, permissions, grantResults, this)
    }

    // Only for video Picture-in-Picture (see "Picture-in-Picture")
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        OmicallsdkPlugin.onUserLeaveHint(this)
    }

    override fun onPictureInPictureModeChanged(isInPip: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPip, newConfig)
        OmicallsdkPlugin.onPictureInPictureModeChanged(isInPip)
    }

  // Your config
}

```

- ✨ Setup push notification : Only support Firebase for remote push notification.
  - ✅ Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - ✅ Add Fire Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - ✅ For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/android-sdk/cau-hinh-push-notification">Config Push for Android</a>


<br>*Now let's continue configuring iOS, let's go 🚀*<br>

#### 🚀 iOS: CocoaPods or Swift Package Manager

The plugin supports both, with the same OmiKit version:
- **CocoaPods** (default): OmiKit is bundled inside the plugin (`ios/Frameworks/OmiKit.xcframework`),
  so `pod install` does not fetch OmiKit from CocoaPods Trunk (Trunk becomes read-only on 2026-12-02).
- **Swift Package Manager** (Flutter's upcoming default): Flutter takes
  `ios/omicall_flutter_plugin/Package.swift`, which pulls OmiKit from
  `https://github.com/VIHATTeam/OmiKit.git` (1.12.x, from 1.12.3).

##### 📦 Install with Swift Package Manager

Requirements: `omicall_flutter_plugin` **3.4.0 or later** (older versions have no `Package.swift`),
a Flutter version with Swift Package Manager support (tested on Flutter 3.47.1 / Xcode 26.6),
iOS 13.0+.

1. Enable SPM — for this app only (recommended):
   ```yaml
   # your app's pubspec.yaml
   flutter:
     config:
       enable-swift-package-manager: true
   ```
   or for every project on the machine: `flutter config --enable-swift-package-manager`.
2. Do **not** add OmiKit yourself: remove any `pod 'OmiKit'` line from `ios/Podfile` and do not add
   the OmiKit package in Xcode. The plugin brings OmiKit; a second copy fails to build or link.
3. Objective-C `AppDelegate.m` only — the CocoaPods header `omicall_flutter_plugin-Swift.h` does not
   exist with SPM. Import the plugin like this (works with both):
   ```objc
   #if __has_include(<omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>)
   #import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>  // CocoaPods
   #else
   @import omicall_flutter_plugin;  // Swift Package Manager
   #endif
   ```
   A Swift `AppDelegate` keeps `import omicall_flutter_plugin` / `import OmiKit` unchanged.
4. Build: `flutter build ios` (or `flutter run`). The first build adds the Swift package to
   `Runner.xcodeproj` and resolves OmiKit from GitHub; plugins without SPM support (for example
   `permission_handler_apple`) keep using CocoaPods automatically.

Moving an existing CocoaPods app: steps 1–3, then build. Flutter removes the plugin and its OmiKit
pod from the Pods project by itself; `pod deintegrate` is not needed. To go back to CocoaPods set
`enable-swift-package-manager: false`.

The setup below (AppDelegate, Info.plist, capabilities) is the same for CocoaPods and SPM.

**SPM troubleshooting**

| Error | Cause / fix |
|---|---|
| `'omicall_flutter_plugin/omicall_flutter_plugin-Swift.h' file not found` | Objective-C AppDelegate still uses the CocoaPods import → use the conditional import of step 3 |
| Duplicate OmiKit symbols / `OmiKit` found twice | OmiKit added by the app as well → remove `pod 'OmiKit'` / the Xcode package (step 2) |
| `The following plugins do not support Swift Package Manager: omicall_flutter_plugin` | Plugin older than 3.4.0 → upgrade |
| `unable to override package 'omicall_flutter_plugin' because its identity ... doesn't match` | The app is inside another folder that contains the plugin source (e.g. a `path:` dependency on a parent directory, like this repo's `example/`) → depend on the plugin from pub.dev / a separate folder |
| Package resolution fails or hangs | Network to github.com is required the first time; retry, or delete `build/ios/SourcePackages` and build again |

#### 🚀 iOS(Object-C):


- 📝 Assets: Add `call_image` into assets folder to update callkit image. We only support png style (*This will help show your application icon on iOS CallKit when a call comes in*)

<br></br>

- 📌 Add instance variables in *AppDelegate.h* (ivars, not file-scope globals — globals in a header
  cause duplicate-symbol link errors):

```objc
#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <OmiKit/OmiKit-umbrella.h>
#import <OmiKit/Constants.h>

@interface AppDelegate : FlutterAppDelegate<UIApplicationDelegate> {
    PushKitManager *pushkitManager;
    CallKitProviderDelegate *provider;
    PKPushRegistry *voipRegistry;
}
@end
```

<br></br>
- 📌 Edit *AppDelegate.m*:

```objc
#import <OmiKit/OmiKit.h>
#if __has_include(<omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>)
#import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>  // CocoaPods
#else
@import omicall_flutter_plugin;  // Swift Package Manager
#endif
```
<br></br>
- 📌 Add these lines into `didFinishLaunchingWithOptions`:

```objc
[OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX userNameKey:@"extension" maxCall:1 callKitImage: @"call_image" typePushVoip:@"default" representName:@"OMICALL"];
provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager];
voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
if (@available(iOS 10.0, *)) {
    [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
}

```

📝 Notes:
- To custom callkit image, you need add image into assets and paste image name into setEnviroment function.
- The variable representName is not required. If it has a value, when a call comes in, by default this name will be displayed on callKit. If nothing is transmitted, internal calls will display the Employee's name or the employee's internal
<br></br>


```objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    bool value = [SwiftOmikitPlugin processUserActivityWithUserActivity:userActivity];
    return value;
}
```

```objc
// This action is used to close ongoing calls when the user kills the app
- (void)applicationWillTerminate:(UIApplication *)application {
    @try {
        [OmiClient OMICloseCall];
    }
    @catch (NSException *exception) {

    }
}
```

- 📌  Add these lines into `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Need camera access for video call functions</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for make Call</string>
<!-- VoIP push, call audio in background (also required for video Picture-in-Picture) -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>voip</string>
</array>
<!-- Calls started from the iOS Recents list (setCallLogListener) -->
<key>NSUserActivityTypes</key>
<array>
    <string>INStartCallIntent</string>
</array>
```

- 📌 In Xcode → Signing & Capabilities add **Push Notifications** and **Background Modes**
  (Audio, Voice over IP, Remote notifications).

- 💡 Save token for `OmiClient`: if you added `firebase_messaging` in your project so you don't need add these lines.

```objc
- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    // parse token bytes to string
    const char *data = [devToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < [devToken length]; i++)
    {
        [token appendFormat:@"%02.2hhX", data[i]];
    }

    // print the token in the console.
    NSLog(@"Push Notification Token: %@", [token copy]);
    [OmiClient setUserPushNotificationToken:[token copy]];
}

```

✨ Push on iOS
  - ✅ Incoming calls arrive through APNS VoIP (PushKit, handled by `PushKitManager`) and CallKit.
  - ✅ Pass the APNS token as `fcmToken` to `register()` / `registerWithApiKey()`
    (`await FirebaseMessaging.instance.getAPNSToken()` when you use `firebase_messaging`).
  - ✅ Add `GoogleService-Info.plist` only if your app uses Firebase on iOS.
  - ✅ For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>

#### 🚀  iOS(Swift):
- 📝 *Notes: The configurations are similar to those for object C above, with only a slight difference in the syntax of the funcs*

- 📌 Add variables in Appdelegate.swift:

```swift
import OmiKit
import PushKit
import NotificationCenter
import omicall_flutter_plugin

var pushkitManager: PushKitManager?
var provider: CallKitProviderDelegate?
var voipRegistry: PKPushRegistry?
```

- 📌 Add these lines into `didFinishLaunchingWithOptions`:

```swift
OmiClient.setEnviroment(KEY_OMI_APP_ENVIROMENT_SANDBOX, userNameKey: "extension", maxCall: 1, callKitImage: "call_image", typePushVoip: "default", representName: "OMICALL")
provider = CallKitProviderDelegate.init(callManager: OMISIPLib.sharedInstance().callManager)
voipRegistry = PKPushRegistry.init(queue: .main)
pushkitManager = PushKitManager.init(voipRegistry: voipRegistry)

```

```swift
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    return SwiftOmikitPlugin.processUserActivity(userActivity: userActivity)
}

// Close ongoing calls when the user kills the app
override func applicationWillTerminate(_ application: UIApplication) {
    OmiClient.omiCloseCall()
}
```

- 📌 `Info.plist` and capabilities: same as the Objective-C section above.

- 💡 Save token for `OmiClient`: if you added `firebase_messaging` in your project so you don't need add these lines.

```swift
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let deviceTokenString = deviceToken.hexString
    OmiClient.setUserPushNotificationToken(deviceTokenString)
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
```

✨ Push on iOS
  - ✅ Incoming calls arrive through APNS VoIP (PushKit, handled by `PushKitManager`) and CallKit.
  - ✅ Pass the APNS token as `fcmToken` to `register()` / `registerWithApiKey()`
    (`await FirebaseMessaging.instance.getAPNSToken()` when you use `firebase_messaging`).
  - ✅ Add `GoogleService-Info.plist` only if your app uses Firebase on iOS.
  - ✅ For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>

<br></br>
❌ Important release note

```
We support 2 environments. So you need set correct key in Appdelegate.
- KEY_OMI_APP_ENVIROMENT_SANDBOX support on debug mode
- KEY_OMI_APP_ENVIROMENT_PRODUCTION support on release mode
- Visit on web admin to select correct enviroment.
```
<br></br>

### 🛠️ STEP 2: Integrate into Flutter code  🚀

#### Request permission

- 📌 Request these permissions before making a call (e.g. with `permission_handler`):

```
 + Permission.microphone
 + Permission.camera        (video calls only)
 + Permission.notification  (Android 13+, incoming-call notification)
```

> On Android, `register()` also requests RECORD_AUDIO, POST_NOTIFICATIONS and — when
> `isVideo: true` — CAMERA. Pass `isVideo: false` for audio-only apps.


- 📌 Set up for Firebase:

```dart
await Firebase.initializeApp();
// If you only use Firebase on Android. Add these line `if (Platform.isAndroid)`
// Because we use APNS to push notification on iOS so you don't need add Firebase for iOS.
```


- 📌 Important function.

- 📝 Start Serivce: OmiKit need start services and register some events.

```dart
  // Call in the root widget
  OmicallClient.instance.startServices();
```
<br></br>
💡 You need to log in to OMI's switchboard system, we provide you with 2 functions with 2 different functions: <br>

📝 Notes: *The information below is taken from the API, you should connect with our Technical team for support*

- ✅ `register`: for employees. They can call any telecommunications number allowed in your business on the OMI system.

```dart
String? token = await FirebaseMessaging.instance.getToken();
if (Platform.isIOS) {
    token = await FirebaseMessaging.instance.getAPNSToken();
}

final result = await OmicallClient.instance.register(
  userName: "100",
  password: "******",
  realm: "your_realm",
  fcmToken: token ?? "",
  host: "",          // optional SIP proxy; empty = OMICall default
  isVideo: true,
  projectId: "",     // optional Firebase project id
);

if (!result.isSuccess) {
  // result.message: NETWORK_UNAVAILABLE | MISSING_PARAMS | INIT_FAILED
  showError(result.message);
  return;
}
// Login successful — proceed
```
<br>

- ✅ `registerWithApiKey`: usually for your customers, who only call a fixed number (for example your hotline).

```dart
final result = await OmicallClient.instance.registerWithApiKey(
  fullName: "John",
  userUuid: "user-uuid",
  apiKey: "your_api_key",
  phone: "0901234567",
  fcmToken: token ?? "",
  isVideo: true,
);
if (!result.isSuccess) showError(result.message);
```

> `initCallWithUserPassword` / `initCallWithApiKey` still work but are **deprecated** since 3.4.0 — they return the raw JSON string. See [Migration Guide](#upgrading-from-33x-to-340).

- ✅ Get the ongoing call when the app is opened (e.g. from a call notification / killed state):
```dart
final result = await OmicallClient.instance.getInitialCall();
// A Map with the call info when a call exists;
// otherwise `false` (iOS) or null (Android).
final hasCall = result is Map && result.isNotEmpty;
```

- ✅ Config push notification:
  ```dart
  OmicallClient.instance.configPushNotification(
    notificationIcon: "calling_face",        // Android: notification icon (res/drawable)
    prefix: "Cuộc gọi tới từ: ",             // Android: incoming-call text prefix
    userImage: "calling_face",               // Android: default avatar (res/drawable)
    prefixMissedCallMessage: "Cuộc gọi nhỡ từ", // both: missed-call message prefix
    missedCallTitle: "Cuộc gọi nhỡ",         // iOS: missed-call title
    userNameKey: "uuid",                     // Android: uuid | full_name | extension
    channelId: "channelid.callnotification", // Android: used as <channelId>-inbound / -missed
    representName: "",                       // Android: name shown for incoming calls (optional)
    isUseIntentFilter: true,                 // Android: open the app through the intent filter
  );
  ```

  | Key | Android | iOS |
  |---|---|---|
  | `notificationIcon`, `prefix`, `userImage`, `userNameKey`, `channelId`, `representName`, `isUseIntentFilter` | ✅ | — (iOS takes `userNameKey` / `representName` from `setEnviroment` in AppDelegate) |
  | `prefixMissedCallMessage` | ✅ | ✅ (only when `missedCallTitle` is also set) |
  | `missedCallTitle` | — | ✅ |
  | `incomingBackgroundColor`, `incomingAcceptButtonImage`, `incomingDeclineButtonImage`, `backImage`, `audioNotificationDescription`, `videoNotificationDescription` | accepted, not used by the current SDK | — |

---

## API Reference

### Core Functions

#### 📌 Authentication

##### register
Login for employees (can call any number allowed in business)

```dart
final OmiRegisterResult result = await OmicallClient.instance.register(
  userName: String,   // required
  password: String,   // required
  realm: String,      // required
  fcmToken: String,   // required — FCM token (Android) / APNS token (iOS)
  host: String,       // optional, default "" = OMICall default SIP proxy
  isVideo: bool,      // optional, default true
  projectId: String,  // optional, default ""
  isSkipDevices: bool, // optional, default false — see "Register the device yourself"
);
```

`initCallWithUserPassword` (deprecated) takes the same `isSkipDevices` parameter.

##### registerWithApiKey
Login for customers (call a fixed number, e.g., hotline)

```dart
final OmiRegisterResult result = await OmicallClient.instance.registerWithApiKey(
  fullName: String,   // required
  userUuid: String,   // required
  apiKey: String,     // required
  phone: String,      // required
  fcmToken: String,   // required
  isVideo: bool,      // optional, default true
  projectId: String,  // optional, default ""
);
```

**Returns** `Future<OmiRegisterResult>` — same on Android and iOS:

| `statusCode` | `message` | Meaning |
|----------|-----------|---------|
| `200` | `INIT_SUCCESS` | Login successful (`result.isSuccess == true`) |
| `400` | `MISSING_PARAMS` | Required fields missing |
| `500` | `INIT_FAILED` | Wrong credentials or SDK error |
| `600` | `NETWORK_UNAVAILABLE` | No internet connection |

> iOS: the SIP stack registers asynchronously, so `register` returns `200` once the credentials are set; a wrong password shows up as a failed call, not as `500`.

##### initCallWithUserPassword / initCallWithApiKey (deprecated)
Same as `register` / `registerWithApiKey` but return the raw JSON string `{"status": Int, "message": String}`.

##### logout
Logout current user

```dart
OmicallClient.instance.logout();
```

##### Register the device yourself (`isSkipDevices`, 3.4.2)

By default (`isSkipDevices: false`) the SDK adds the device (push token, VoIP token, device id,
app id) on the OMI backend after login, so incoming calls can wake the app by push.

Pass `isSkipDevices: true` when your backend adds the device instead. The SDK still logs in to the
switchboard but skips its own "add device" call; send the values below to your API:

```dart
final result = await OmicallClient.instance.register(
  userName: u, password: p, realm: r, fcmToken: token,
  isSkipDevices: true,
);
if (result.isSuccess) {
  await myApi.addOmiDevice(
    deviceId: await OmicallClient.instance.getDeviceId(),
    appId: await OmicallClient.instance.getAppId(),
    fcmToken: await OmicallClient.instance.getFcmToken(),
    voipToken: await OmicallClient.instance.getVoipToken(),   // iOS only
    projectId: await OmicallClient.instance.getProjectId(),
  );
}
```

- Only for username/password login (`register` / `initCallWithUserPassword`); the API-key login
  has no such option.
- If nobody adds the device, it receives **no incoming-call push**, and `needsReLogin()` returns true.

##### Mask phone numbers on the call UI (3.4.2)

Hide part of the caller's number on the SDK's native call UI — the incoming-call notification and
call screen on Android, CallKit on iOS. Numbers your Flutter UI shows are not affected. Same API on
both platforms; the modes are the `hide_phone_type` values of the OMI role API:

```dart
// From the role API
await OmicallClient.instance.setPhoneNumberMask(
  enabled: true,
  mode: ExtensionOmiPhoneMaskMode.fromApiValue(role.hidePhoneType),
);

// Or directly
await OmicallClient.instance.setPhoneNumberMask(enabled: true, mode: OmiPhoneMaskMode.hideLast3);
await OmicallClient.instance.setPhoneNumberMask(enabled: false); // show full numbers

final config = await OmicallClient.instance.getPhoneNumberMask(); // OmiPhoneMaskConfig(enabled, mode)
```

Four masking modes (example number `0987654321`):

| # | `OmiPhoneMaskMode` | `hide_phone_type` (role API) | What it does | Web / Android | iOS (OmiKit 1.12.3) |
|---|---|---|---|---|---|
| 0 | `hideLastKeepFirst3` (default) | `hide_last_keep_first_3` | Keep the first 3 digits | `098*******` | `098*******` |
| 1 | `hideLast3` | `hide_last_3` | Hide the last 3 digits | `0987654***` | `0987654***` |
| 2 | `hideLastKeepFirst4` | `hide_last_keep_first_4` | Keep the first 4 digits | `0987******` | `0987******` |
| 3 | `hideMiddleKeepLast` | `hide_middle_keep_last` | Keep the first digits and the last 3 | `0987***321` | ⚠️ `098****321` |

- `enabled: false` (default): full numbers. `enabled: true`: masked with `mode`.
- The setting is kept across app launches; apply the role value again after each login.
- Internal extensions are not masked. Threshold today: Android skips numbers of up to 8
  characters, iOS masks only numbers of 7 digits or more.
- ⚠️ Mode 3 on iOS keeps the first 3 digits instead of 4 (OmiKit 1.12.3); it will match web and
  Android once OmiKit is fixed — no plugin change needed.

##### Device info & backend registration (3.4.0)
Same names and behaviour as the React Native SDK — use them to check or add this device on the
OMI backend yourself:

```dart
final client = OmicallClient.instance;
final deviceId = await client.getDeviceId();   // value the SDK sends when adding the device
final appId = await client.getAppId();         // bundle id / package name
final fcm = await client.getFcmToken();        // push token registered by the SDK
final voip = await client.getVoipToken();      // iOS PushKit token, null on Android
final projectId = await client.getProjectId(); // Firebase project id
final sip = await client.getSipInfo();         // current SIP account

final devices = await client.getOmiDevices();  // List<OmiDeviceInfo> on the backend (HTTP, do not poll)
final boundSip = client.findSipNumberByDeviceId(devices, deviceId);
if (await client.needsReLogin()) {
  // logged in locally but the backend has no record of this device → logout + register again
}
```

| Function | Returns |
|---|---|
| `getDeviceId` / `getAppId` / `getFcmToken` / `getVoipToken` / `getProjectId` / `getSipInfo` | `String?` |
| `getOmiDevices` | `List<OmiDeviceInfo>` (empty when not logged in or on network error) |
| `isCurrentDeviceRegistered` / `needsReLogin` | `bool` (false when not logged in) |
| `findSipNumberByDeviceId(devices, deviceId)` | `String?` (sync helper) |

---

### Call Control

##### 📌 Start Call (Phone Number)
Initiate outgoing call to any number

```dart
final result = await OmicallClient.instance.startCall(
    phone,      // phone number
    _isVideoCall // if true, it's a video call; otherwise, it's an audio call.
);
```

**Returns** a JSON string `{"status": int, "_id": String, "message": String}` on both platforms:

```dart
final json = jsonDecode(result as String) as Map;
final started = json['status'] == 8 || json['message'] == 'START_CALL_SUCCESS';
if (started) openCallScreen(); else showError(json['message']);
```

The `status` codes differ by platform — branch on `message` for cross-platform handling.

| `message` | iOS `status` | Android `status` |
|---|---|---|
| `START_CALL_SUCCESS` ⬅️ navigate to the call screen | 8 (also 12 = waiting for endpoint) | 8 |
| `SWITCHBOARD_REGISTERING` (call continues once registered — treat as started) | — | 8 |
| `INVALID_UUID` | 0 | 401 |
| `INVALID_PHONE_NUMBER` | 1 | 402 |
| `SAME_PHONE_NUMBER_WITH_PHONE_REGISTER` / `CAN_NOT_CALL_YOURSELF` | 2 | 403 |
| `MAX_RETRY` | 3 | — |
| `PERMISSION_DENIED` | 4 | 405 (audio) / 406 (video) |
| `COULD_NOT_FIND_END_POINT` (log in first) | 5 | — |
| `SWITCHBOARD_NOT_CONNECTED` | — | 404 |
| `REGISTER_ACCOUNT_FAIL` | 6 | — |
| `START_CALL_FAIL` | 7 | — |
| `HAVE_ANOTHER_CALL` | 9 | 400 |
| `ACCOUNT_TURN_OFF_NUMBER_INTERNAL` | 10 | — |
| `NO_NETWORK` | 11 | 408 |

`OmiStartCallStatus` (iOS codes 0-11) lives in `package:omicall_flutter_plugin/action/action_model.dart`.

##### 📌 Start Call (UUID)
Call using user UUID (API key only)

```dart
final int status = await OmicallClient.instance.startCallWithUUID(
    uuid,         // user id
    _isVideoCall  // call video or audio
);
// iOS: 8 = started (codes as in the table above). Android: raw SDK code, 200 = started.
// 4 = microphone permission denied (both).
```

##### 📌 Join Call
Answer incoming call

```dart
OmicallClient.instance.joinCall();
```

##### 📌 End Call
Hang up current call

```dart
final Map? callInfo = await OmicallClient.instance.endCall();
// Declines a ringing incoming call, hangs up otherwise.
// Returns the call info (null when declining on Android, {} when there is no call on iOS).

/* Sample output:
{
  "transaction_id": "ea7dff38-cb1e-483d-8576-xxxxxxxxxxxx",
  "direction": "inbound",
  "source_number": 111,
  "destination_number": 110,
  "time_start_to_answer": 1682858097393,
  "time_end": 1682858152181,   // iOS: seconds
  "sip_user": 111,
  "disposition": "answered",
  "code_end_call": 200
}
*/
```

##### 📌 Reject / Drop Incoming Call

```dart
// 486 Busy Here — other devices of the same extension keep ringing
await OmicallClient.instance.rejectCall();

// 603 Decline — stops ringing on every device of the extension
await OmicallClient.instance.dropCall();
```

Both hang up the call instead when it is already answered.

##### 📌 Toggle Audio (Mute/Unmute)
Toggle microphone on/off

```dart
OmicallClient.instance.toggleAudio();
```

##### 📌 Toggle Speaker
Switch between earpiece and speaker

```dart
OmicallClient.instance.toggleSpeaker();
```

##### 📌 Toggle Hold
Hold/Unhold current call

```dart
OmicallClient.instance.toggleHold();
```

##### 📌 Send DTMF
Send a key (0-9, *, #)

```dart
OmicallClient.instance.sendDTMF(value);
```

##### 📌 Transfer Call
Forward call to another employee

```dart
final bool sent = await OmicallClient.instance.transferCall(phoneNumber: "101");
```

The PBX result arrives in `setTransferStatusListener` (see below). Since 3.4.0 (Android SDK 2.9.1)
a failed transfer no longer ends the call on Android: you get `TRANSFER_STATUS` with
`statusCode: 500, isFinal: true` and the call stays up.

##### 📌 Consult (Attended) Transfer — NEW 3.4.0
Talk to a colleague before handing the customer over (answered **audio** calls only).

```dart
final client = OmicallClient.instance;

client.setConsultStateListener((e) {
  // e.state: dialing → ringing → answered → ended; e.statusCode: SIP code
  if (e.state == OmiConsultState.answered) showCompleteButton();
  if (e.state == OmiConsultState.ended) hideConsultUi();
});
client.setTransferStatusListener((e) {
  if (e.isFinal) e.isSuccess ? closeCallScreen() : showError("Transfer failed (${e.statusCode})");
});

// 1. Hold the customer and call extension 102
final status = await client.startConsultCall("102");
if (status != OmiConsultStartStatus.success) showError(status.name);

// 2a. Colleague answered → hand the customer over
await client.completeConsultTransfer();

// 2b. …or go back to the customer (taken off hold)
await client.cancelConsult();
```

| Function | Returns | Description |
|---|---|---|
| `startConsultCall(extension, {extraHeaders})` | `OmiConsultStartStatus` | Hold the customer and call `extension` |
| `completeConsultTransfer({extraHeaders})` | `bool` | Hang up the consult, transfer the customer to the same extension. `false` if not answered yet / customer already ended |
| `cancelConsult()` | `bool` | End the consult, take the customer off hold |
| `isConsulting()` | `bool` | A consult is running |
| `isConsultOriginalEnded()` | `bool` | The customer hung up while the consult is running |
| `getActiveCalls()` | `List<OmiCallSummary>` | Live calls with hold state; consult call has `isConsult == true` |

`OmiConsultStartStatus`: `success` (200), `emptyExtension` (402), `canNotCallYourself` (403),
`switchboardNotConnected` (404), `missingAudioPermission` (405), `noActiveCall` (409),
`consultInProgress` (410), `videoCallNotSupported` (411), `sameAsCustomer` (412),
`unknown` (-1, a code this plugin version does not know).

Rules (same on Android and iOS):
- The consult call never fires `CALL_STATE_CHANGED`; follow it with `setConsultStateListener`.
- `endCall()` during a consult hangs up the **customer**; use `cancelConsult()` to cancel.
- Colleague rejects / does not answer → the consult ends and the customer is taken off hold automatically.
- Transfer fails or has no result within 30 s → the customer is taken off hold.
- `toggleHold()` is ignored while consulting; mute / DTMF go to the consult call once answered.

##### 📌 Get Current User
Retrieve logged-in user information

```dart
final user = await OmicallClient.instance.getCurrentUser();
// Output: { "extension": "111", "full_name": "John", "avatar_url": "", "uuid": "122aaa" }
```

##### 📌 Get Guest User
Retrieve remote user information

```dart
final user = await OmicallClient.instance.getGuestUser();
// Output: { "extension": "111", "full_name": "Jane", "avatar_url": "", "uuid": "456bbb" }
```

##### 📌 Get User Info (SIP)
Lookup user by phone number

```dart
final user = await OmicallClient.instance.getUserInfo(phone: "111");
// Output: { "extension": "111", "full_name": "Alice", "avatar_url": "", "uuid": "789ccc" }
```

##### 📌 Audio Output (earpiece / speaker / Bluetooth / headset)

```dart
final outputs = await OmicallClient.instance.getOutputAudios();  // List of {name, type}
final current = await OmicallClient.instance.getCurrentAudio();  // List with the active output
await OmicallClient.instance.setOutputAudio(portType: outputs.first["type"]);
OmicallClient.instance.setAudioChangedListener((List<dynamic> audios) {
  // AUDIO_CHANGE: the active output changed (Bluetooth connected, headset unplugged, ...)
});
```

`portType` is the `type` value from `getOutputAudios()`: an `int` on Android, a `String` on iOS.

##### 📌 Other

| Function | Platform | Description |
|---|---|---|
| `changeTransport(type: "UDP" \| "TCP")` | Android | Switch the SIP transport |
| `getHistoryCallLog()` | iOS | Number of a call started from the iOS Recents list (see Call Log Listener) |
| `dispose()` | both | Close the call-state stream (only when the app no longer uses the SDK) |
| `remove…Listener()` | both | Each `set…Listener` has a matching `remove…Listener` |

---

### Video Call Functions  🚀🚀
>📝  **Note:** These functions support video calls only. Make sure you enable video in the initialization functions and when starting a call.

##### 📌 Switch Camera
Toggle between front/back camera

```dart
OmicallClient.instance.switchCamera();
```

##### 📌 Toggle Video
Turn video on/off during call

```dart
OmicallClient.instance.toggleVideo();
```

##### 📌 Remote Video Ready
`setVideoListener` receives `REMOTE_VIDEO_READY` when the first remote frame is decoded (Android
and iOS since 3.4.0). `registerVideoEvent()` / `removeVideoEvent()` are kept for compatibility and
are no longer needed.

##### 📌 How video is rendered (3.4.0)
Same as the OMICall store apps:
- **Android:** each widget attaches its feed as soon as its surface exists and again when the call
  connects; the picture is fitted 9:16 and the remote ratio follows the size the peer really sends.
- **iOS:** the widgets are containers for `OMIVideoCallManager`, which handles rendering,
  background/foreground, re-INVITE recovery, PiP and the "reconnecting" overlay. Video starts as
  soon as both widgets are laid out; it does not wait for CONFIRMED.
- Show `LocalCameraView` / `RemoteCameraView` only after the call is answered (or for an outgoing
  call): on iOS the camera starts as soon as both widgets are on screen during a video call.
- Do **not** mirror the local preview yourself (`Transform.scale(scaleX: -1)`): the SDK already
  mirrors the front camera.

##### 📌 Local Camera Widget
Display your camera view

```dart
LocalCameraView(
  width: double.infinity,
  height: double.infinity,
  onCameraCreated: (controller) {
    _localController = controller;
  },
)
```

##### 📌 Remote Camera Widget
Display remote camera view

```dart
RemoteCameraView(
  width: double.infinity,
  height: double.infinity,
  onCameraCreated: (controller) {
    _remoteController = controller;
  },
)
```

##### 📌 Refresh Camera
Optional since 3.4.0 (views attach themselves). Safe to call at any time:

```dart
_remoteController?.refresh();
_localController?.refresh();
```

##### 📌 Picture-in-Picture (3.4.0)
The remote video moves to a floating window when the app goes to the background during a video
call; the SDK closes it at call end. Enable it once, before the call:

```dart
final supported = await OmicallClient.instance.setVideoPictureInPictureEnabled(true);
OmicallClient.instance.setPictureInPictureListener((isActive) {
  setState(() => _hideControls = isActive); // hide buttons inside the PiP window
});
```

Android — `AndroidManifest.xml` (MainActivity):
```xml
<activity android:name=".MainActivity"
    android:supportsPictureInPicture="true"
    android:resizeableActivity="true"
    android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation" ... />
```
`MainActivity.kt`:
```kotlin
override fun onUserLeaveHint() {
    super.onUserLeaveHint()
    OmicallsdkPlugin.onUserLeaveHint(this)
}

override fun onPictureInPictureModeChanged(isInPip: Boolean, newConfig: Configuration) {
    super.onPictureInPictureModeChanged(isInPip, newConfig)
    OmicallsdkPlugin.onPictureInPictureModeChanged(isInPip)
}
```

iOS 15+: `audio` in `UIBackgroundModes`. To keep sending your camera while in PiP (iOS 16+), add the
entitlement `com.apple.developer.avfoundation.multitasking-camera-access` (explain it in App
Review notes); without it the other party sees your video paused while audio continues.

##### 📌 Remote Connection State (iOS, 3.4.0)
The SDK draws a "reconnecting / weak connection" overlay on the remote video. Translate it, or
follow the state yourself:

```dart
OmicallClient.instance.setRemoteConnectionOverlayTexts({
  OmiRemoteConnectionState.reconnecting: "Reconnecting…",
  OmiRemoteConnectionState.videoPaused: "Video paused",
});
OmicallClient.instance.setRemoteConnectionListener((e) {
  // e.state: connected | videoPaused | weak | reconnecting | localReconnecting | networkSwitching | uplinkPoor
});
```

---

### 📊 Call Quality Monitoring (NEW)

The SDK provides built-in call quality tracking using **MOS (Mean Opinion Score)** and **LCN (Loss Connect Number)** metrics.

#### Quick Setup

```dart
import 'package:omicall_flutter_plugin/omicall.dart';
import 'package:omicall_flutter_plugin/models/call_quality_info.dart';
import 'package:omicall_flutter_plugin/utils/call_quality_tracker.dart';

class MyCallScreen extends StatefulWidget {
  @override
  State<MyCallScreen> createState() => _MyCallScreenState();
}

class _MyCallScreenState extends State<MyCallScreen> {
  final CallQualityTracker _qualityTracker = CallQualityTracker();
  String callQuality = "";

  @override
  void initState() {
    super.initState();

    // Set up call quality listener
    OmicallClient.instance.setCallQualityListener((data) {
      // Parse call quality data using helper
      final info = _qualityTracker.parseCallQuality(data);

      debugPrint("CallQualityInfo => $info");

      // Handle loading indicator (network issue detection)
      if (info.shouldShowLoading) {
        EasyLoading.show(); // Show loading when network stuck
      } else if (info.isNetworkRecovered || info.lcn == 0) {
        EasyLoading.dismiss(); // Dismiss when network recovers
      }

      // Display MOS score
      setState(() {
        callQuality = info.mosDisplay; // "4.5", "3.2", etc.
      });
    });
  }

  @override
  void dispose() {
    _qualityTracker.reset(); // Reset tracker when screen closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Call Quality: $callQuality"),
            // Display quality level: "Excellent", "Good", "Fair", "Poor", "Bad"
          ],
        ),
      ),
    );
  }
}
```

#### CallQualityInfo Properties

| Property | Type | Description |
|----------|------|-------------|
| `mos` | `double` | MOS score (1.0-5.0) - call quality metric |
| `mosDisplay` | `String` | Formatted MOS for display (e.g., "4.5") |
| `qualityText` | `String` | Quality level: "Excellent", "Good", "Fair", "Poor", "Bad" |
| `lcn` | `int` | Loss Connect Number (connection loss tracking) |
| `quality` | `int` | Quality level (0=good, 1=normal, 2=bad) |
| `jitter` | `double` | Jitter in milliseconds |
| `latency` | `double` | Latency in milliseconds |
| `packetLoss` | `double` | Packet loss percentage |
| `shouldShowLoading` | `bool` | Whether to show loading indicator |
| `isNetworkRecovered` | `bool` | Whether network has recovered |
| `consecutiveSameLcnCount` | `int` | Current consecutive same LCN count |
| `requestCount` | `int` | Request counter (`req`) from the native quality report |

#### MOS Score Scale

| MOS Range | Quality Level | Description |
|-----------|---------------|-------------|
| **≥ 4.0** | **Excellent** | Xuất sắc - Perfect call quality |
| **3.5-4.0** | **Good** | Tốt - High quality |
| **3.0-3.5** | **Fair** | Chấp nhận được - Acceptable |
| **2.0-3.0** | **Poor** | Kém - Low quality |
| **< 2.0** | **Bad** | Rất kém - Very poor |

#### Loading Logic (Network Issue Detection)

The loading indicator is automatically shown/hidden based on LCN tracking.
**Android only** — iOS always reports `lcn: 0` / `isNeedLoading: false`, so `shouldShowLoading` never
turns on there (use `setRemoteConnectionListener` on iOS instead).

```
Show Loading:
  ├─ The same non-zero LCN value arrives 4 times in a row (3 repeats)
  └─ Indicates network stuck/frozen

Hide Loading:
  ├─ LCN value changes (network recovered)
  └─ LCN value is 0 (no connection loss)
```

**Timeline Example:**
```
Event 1: LCN=5 → Count=0 → No loading
Event 2: LCN=5 → Count=1 → No loading
Event 3: LCN=5 → Count=2 → No loading
Event 4: LCN=5 → Count=3 → ⚠️ SHOW LOADING (network stuck!)
Event 5: LCN=6 → Count=0 → ✅ HIDE LOADING (network recovered!)
```

#### Benefits

✅ **Clean Code**: No manual parsing logic in UI code
✅ **Consistent**: Same logic across all screens
✅ **Maintainable**: Update logic in one place
✅ **Type Safe**: Strongly typed data
✅ **Testable**: Easy to unit test
✅ **Automatic**: Loading logic handled automatically

For more details, see [lib/utils/README.md](lib/utils/README.md)

---

## Event Listener ✨

### 📌 Call State Change Event (IMPORTANT)

Listen to all call state changes:

```dart
OmicallClient.instance.callStateChangeEvent.listen((action) {
  debugPrint("Action: ${action.actionName}, Data: ${action.data}");
});
```

#### Action Names

`action.actionName` is a string; filter on it — the stream carries more than call states:

| `actionName` | Constant | Payload |
|-------------|----------|---------|
| `"CALL_STATE_CHANGED"` | `OmiEventList.onCallStateChanged` | see Event Data below |
| `"SWITCHBOARD_ANSWER"` | `OmiEventList.onSwitchboardAnswer` | `{sip}` — switchboard answered |
| `"VIDEO"` | `OmiEventList.onVideo` | iOS: camera on/off after `toggleVideo()` |
| `"CAMERA_STATUS"` | — | Android: sent after `switchCamera()` |

```dart
OmicallClient.instance.callStateChangeEvent.listen((action) {
  if (action.actionName != OmiEventList.onCallStateChanged) return;
  final status = action.data["status"] as int?;
});
```

#### Call States

| State | Code | Description |
|-------|------|-------------|
| `unknown` | 0 | Unknown state |
| `calling` | 1 | Outgoing call initiated |
| `incoming` | 2 | Incoming call |
| `early` | 3 | Ringing |
| `connecting` | 4 | Connecting |
| `confirmed` | 5 | Active call |
| `disconnected` | 6 | Call ended |
| `hold` | 7 | Call on hold |

#### Event Data (onCallStateChanged)

```dart
{
  "isVideo": bool,          // true for video call
  "status": int,            // call state code (0-7)
  "callerNumber": String,   // phone number
  "incoming": bool,         // true if incoming
  "_id": String,            // iOS: call UUID; Android: ""
  "transactionId": String,  // iOS: every event; Android: on CONFIRMED
  // When status == disconnected (6):
  "code_end_call": int,     // SIP/OMI end reason code — see Call End Codes table
}
```

> **DISCONNECTED arrives twice on iOS**: once with the call info + `code_end_call`, and once from
> the SDK teardown as `{status: 6, message, codeEndCall}`. Android sends it once. Handle
> DISCONNECTED idempotently (e.g. close the call screen only once). iOS forwards the raw SDK
> state, so ignore values you do not know.

#### State Lifecycle

**Outgoing Call:**
```
CALLING (1) → EARLY (3) → CONNECTING (4) → CONFIRMED (5) → DISCONNECTED (6)
```

**Incoming Call:**
```
INCOMING (2) → CONNECTING (4) → CONFIRMED (5) → DISCONNECTED (6)
```

---

### 📌 Other Event Listeners

#### Call Quality Listener (Recommended: Use CallQualityTracker)

```dart
OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  // Use parsed info
  print(info.mosDisplay);      // "4.5"
  print(info.qualityText);     // "Excellent"
  print(info.shouldShowLoading); // true/false
});
```

**Raw data format (if not using helper):**
```dart
{
  "quality": int,        // 0: GOOD, 1: NORMAL, 2: BAD
  "stat": {
    "req": double,       // Request time
    "mos": double,       // MOS score (1.0-5.0)
    "jitter": double,    // Jitter (ms)
    "latency": double,   // Latency (ms)
    "ppl": double,       // Packet loss (%)
    "lcn": int          // Loss connect count
  },
  "isNeedLoading": bool  // (Deprecated: Use CallQualityTracker instead)
}
```

#### Speaker Listener

```dart
OmicallClient.instance.setSpeakerListener((isSpeakerOn) {
  setState(() {
    isSpeaker = isSpeakerOn;
  });
});
```

#### Mute Listener

```dart
OmicallClient.instance.setMuteListener((isMuted) {
  setState(() {
    this.isMuted = isMuted;
  });
});
```

#### Hold Listener

```dart
OmicallClient.instance.setHoldListener((isOnHold) {
  setState(() {
    this.isHold = isOnHold;
  });
});
```

#### Consult / Transfer / Call Hold Listeners (3.4.0)

```dart
OmicallClient.instance.setConsultStateListener((OmiConsultStateEvent e) {});   // CONSULT_STATE_CHANGED
OmicallClient.instance.setTransferStatusListener((OmiTransferStatusEvent e) {}); // TRANSFER_STATUS
OmicallClient.instance.setCallHoldChangedListener((OmiCallHoldEvent e) {});    // CALL_HOLD_CHANGED: any call, with callId
```

Remove with `removeConsultStateListener()`, `removeTransferStatusListener()`, `removeCallHoldChangedListener()`.

#### Remote Video Ready Listener

```dart
// data: {"name": "REMOTE_VIDEO_READY", "data": {...}} — once per call, Android and iOS
OmicallClient.instance.setVideoListener((data) {
  setState(() => _remoteVideoReady = true); // e.g. hide the "connecting video" placeholder
});
```

#### Missed Call Listener

Triggered when user taps missed call notification:

```dart
OmicallClient.instance.setMissedCallListener((data) {
  final String callerNumber = data["callerNumber"];
  final bool isVideo = data["isVideo"];
  makeCallWithParams(context, callerNumber, isVideo);
});
```

#### Call Log Listener (iOS Only)

Triggered when the user starts a call from the iOS Recents list. Requires
`processUserActivity` in AppDelegate and `NSUserActivityTypes` → `INStartCallIntent` in Info.plist
(see iOS setup):

```dart
OmicallClient.instance.setCallLogListener((data) {
  final String callerNumber = data["callerNumber"];
  final bool isVideo = data["isVideo"];
  makeCallWithParams(context, callerNumber, isVideo);
});
```

---

## Error Codes

### Call End Codes (`code_end_call`)

The `code_end_call` field is included in the event data when `status == disconnected (6)`. It indicates why the call ended.

#### How to handle end-call reasons

```dart
import 'package:omicall_flutter_plugin/action/action_model.dart'; // OmiCallState

OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
  if (omiAction.actionName != OmiEventList.onCallStateChanged) return;
  final data = omiAction.data;
  final status = data['status'] as int;

  if (status == OmiCallState.disconnected.rawValue) {
    // iOS also sends a second DISCONNECTED with `codeEndCall` (see Event Data)
    final code = (data['code_end_call'] ?? data['codeEndCall']) as int?;
    final reason = _endCallReason(code);
    if (reason != null) {
      // Show toast or dialog to user
      showToast(reason);
    }
  }
});

String? _endCallReason(int? code) {
  switch (code) {
    case null:
    case 0:
    case 200:  // Normal BYE — both sides hung up
    case 487:  // Caller cancelled before answer
      return null;
    case 408: return 'No answer. The call was not answered.';
    case 480: return 'Callee is temporarily unavailable.';
    case 486: return 'Line busy. Please try again later.';
    case 503: return 'Service unavailable.';
    default:  return 'Call ended (code: $code).';
  }
}
```

#### Standard OMISIP Codes

| Code | Meaning | Action for user |
|------|---------|-----------------|
| `200` | Normal call end (BYE) | No toast needed |
| `403` | Forbidden — service plan restricts this number | Upgrade service plan |
| `404` | Number not found or not allowed to call carrier | Check number |
| `408` | Request timeout — callee did not answer | Notify: no answer |
| `480` | Temporarily unavailable — callee offline/busy | Notify: unavailable |
| `486` | Busy here — callee rejected / busy | Notify: line busy |
| `487` | Request terminated — caller cancelled | No toast needed |
| `503` | Service unavailable | Notify: service error |
| `601` | Call ended by customer |
| `602` | Call ended by another employee |
| `603` | Call rejected — check account limit or call barring |
| `850` | Simultaneous call limit exceeded |
| `851` | Call duration limit exceeded |
| `852` | Service package not assigned |
| `853` | Internal number disabled |
| `854` | Subscriber in DNC (Do Not Call) list |
| `855` | Exceeded allowed calls for trial package |
| `856` | Exceeded allowed minutes for trial package |
| `857` | Subscriber blocked in configuration |
| `858` | Unidentified or unconfigured number |
| `859` | No available numbers for Viettel direction |
| `860` | No available numbers for VinaPhone direction |
| `861` | No available numbers for Mobifone direction |
| `862` | Temporary block on Viettel direction |
| `863` | Temporary block on VinaPhone direction |
| `864` | Temporary block on Mobifone direction |
| `865` | Advertising number outside permitted calling hours |

---

## Troubleshooting

### Common Issues

#### 1. Call Not Starting (startCall returns error)

**Symptom:** `startCall()` returns status other than 8

**Solutions:**

```dart
// Check result and handle errors
final result = await OmicallClient.instance.startCall(phone, false);
final jsonMap = jsonDecode(result as String) as Map;
final status = jsonMap['status'];

// Use 'message' field for cross-platform handling (status code differs between Android/iOS)
final message = jsonMap['message'];

switch(message) {
  case 'START_CALL_SUCCESS':
    navigateToCallScreen();
    break;
  case 'NO_NETWORK':
    // Android: status=408 / iOS: status=11
    print("No network connection - check internet");
    showNoNetworkDialog();
    break;
  case 'PERMISSION_DENIED':
    print("Microphone permission denied");
    await requestMicrophonePermission();
    break;
  case 'COULD_NOT_FIND_END_POINT': // iOS
    print("Not logged in - call register() first");
    break;
  case 'INVALID_PHONE_NUMBER':
  case 'INVALID_UUID':
  case 'CAN_NOT_CALL_YOURSELF':                 // Android
  case 'SAME_PHONE_NUMBER_WITH_PHONE_REGISTER': // iOS
    print("Invalid destination");
    break;
  case 'MAX_RETRY':             // iOS
  case 'REGISTER_ACCOUNT_FAIL': // iOS
  case 'START_CALL_FAIL':       // iOS
    print("Could not start the call - try again");
    break;
  case 'HAVE_ANOTHER_CALL':
    print("Already in a call");
    break;
  case 'SWITCHBOARD_NOT_CONNECTED':
    print("Switchboard not connected - check account");
    break;
  case 'SWITCHBOARD_REGISTERING':
    // status=8 on Android, call is being registered
    navigateToCallScreen();
    break;
  case 'ACCOUNT_TURN_OFF_NUMBER_INTERNAL':
    print("Internal call feature is disabled for this account");
    break;
}
```

#### 2. No Incoming Call Notification

**Android:**
- ✅ Check `google-services.json` exists in `android/app/`
- ✅ Verify the FCM token is registered: `OmicallClient.instance.register(..., fcmToken: token)`
- ✅ Check `AndroidManifest.xml` has `FirebaseMessageReceiver`
- ✅ Ensure app has notification permissions

**iOS:**
- ✅ Check APNS certificate is configured on Firebase
- ✅ Verify APNS token: `FirebaseMessaging.instance.getAPNSToken()`
- ✅ Check `PushKitManager` is initialized in `AppDelegate`
- ✅ Verify VoIP push certificate in Apple Developer Portal

#### 3. Call Quality Issues (Low MOS Score)

**Symptom:** MOS < 3.0 or frequent loading indicators

**Debugging:**

```dart
OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  print("MOS: ${info.mos}");           // Target: ≥ 4.0
  print("Jitter: ${info.jitter}ms");   // Target: < 30ms
  print("Latency: ${info.latency}ms"); // Target: < 150ms
  print("Packet Loss: ${info.packetLoss}%"); // Target: < 1%
  print("LCN: ${info.lcn}");           // Target: 0 or changing

  if (info.mos < 3.0) {
    // Poor call quality detected
    if (info.jitter > 50) {
      print("High jitter - check network stability");
    }
    if (info.latency > 200) {
      print("High latency - check internet speed");
    }
    if (info.packetLoss > 3) {
      print("Packet loss - check WiFi signal");
    }
  }

  if (info.shouldShowLoading) {
    print("Network stuck - LCN frozen at ${info.lcn}");
  }
});
```

**Solutions:**
- Switch from WiFi to cellular or vice versa
- Close bandwidth-heavy apps
- Move closer to WiFi router
- Check internet speed (minimum 100kbps recommended)

#### 4. Video Call Issues

**No Remote Video:**
- ✅ Show both `RemoteCameraView` and `LocalCameraView` — they attach to the SDK by themselves
  (since 3.4.0 `refresh()` is optional).
- ✅ `setVideoListener` fires `REMOTE_VIDEO_READY` once the first remote frame is decoded; if it
  never comes, check the network / PBX video codec (H.264).

**Camera Not Switching:**
```dart
// Ensure camera is created before switching
if (_localController != null) {
  OmicallClient.instance.switchCamera();
}
```

**Black Screen:**
- ✅ Check camera permissions
- ✅ Ensure `isVideo: true` in `register()` and `startCall()`
- ✅ Keep both camera widgets on screen during the video call (they attach automatically)

#### 5. Audio Issues

**No Audio During Call:**
```dart
// Check if muted
OmicallClient.instance.setMuteListener((isMuted) {
  if (isMuted) {
    OmicallClient.instance.toggleAudio(); // Unmute
  }
});

// Check speaker status
OmicallClient.instance.setSpeakerListener((isSpeakerOn) {
  print("Speaker: $isSpeakerOn");
});
```

**Echo or Feedback:**
- Use headphones/earphones
- Enable speaker phone
- Check microphone sensitivity

---

## Migration Guide

### Upgrading from 3.3.x to 3.4.0

No breaking change. Replace the deprecated init functions:

```dart
// Before
final raw = await OmicallClient.instance.initCallWithUserPassword(
  userName: u, password: p, realm: r, host: h, isVideo: true, fcmToken: t);
final ok = (jsonDecode(raw) as Map)['status'] == 200;

// After
final result = await OmicallClient.instance.register(
  userName: u, password: p, realm: r, host: h, isVideo: true, fcmToken: t);
final ok = result.isSuccess;
```

| Deprecated | New | Parameter renames |
|---|---|---|
| `initCallWithUserPassword` | `register` | — |
| `initCallWithApiKey` | `registerWithApiKey` | `usrName` → `fullName`, `usrUuid` → `userUuid` |

Behaviour changes:
- `host` is now optional on Android (empty = SDK default) and honored on iOS (was always `vh.omicrm.com:5222`).
- `transferCall` failure no longer ends the call on Android — listen to `setTransferStatusListener`.
- `toggleHold()` is ignored while a consult transfer is running (both platforms).

Video calls:
- `registerVideoEvent()` / `removeVideoEvent()` are no longer needed (kept as no-ops) and
  `refresh()` is optional — the camera widgets attach themselves.
- `REMOTE_VIDEO_READY` (`setVideoListener`) now also fires on Android, once per call.
- iOS renders through `OMIVideoCallManager`: do not mirror the local preview yourself.
- Picture-in-Picture: `setVideoPictureInPictureEnabled(true)`; on Android add the manifest flags and
  forward `onUserLeaveHint` / `onPictureInPictureModeChanged` from MainActivity (see
  [Picture-in-Picture](#-picture-in-picture-340)).

Native setup:
- Android: Maven credentials are `omicallUsername` / `omicallPassword` in `android/local.properties`.
- iOS: minimum deployment target is now 13.0; run `pod install` (OmiKit is bundled in the plugin,
  no separate `OmiKit` pod).
- iOS: Swift Package Manager is supported — see [Install with Swift Package Manager](#-install-with-swift-package-manager).

### Upgrading from 2.x.x to 3.x.x

Call quality: parse `setCallQualityListener` data with `CallQualityTracker` instead of reading the
raw map yourself (see [Call Quality Monitoring](#-call-quality-monitoring-new)):

```dart
final _qualityTracker = CallQualityTracker();

OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);
  if (info.shouldShowLoading) {
    EasyLoading.show();          // Android only, see Loading Logic
  } else if (info.isNetworkRecovered) {
    EasyLoading.dismiss();
  }
  setState(() => callQuality = info.mosDisplay); // "4.5"
});
```

---

## Support

- 📧 Email: contact@omicall.com
- 📱 Hotline: 0272 7777 787
- 🌐 Website: https://omicall.com
- 📖 API Docs: https://omicrm.io/post/detail/omicall-apis-post76

---

## License

Copyright © 2021 VIHAT Team. All rights reserved.
